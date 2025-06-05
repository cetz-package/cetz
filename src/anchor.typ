#import "deps.typ"
#import deps.oxifmt: strfmt

#import "util.typ"
#import "intersection.typ"
#import "drawable.typ"
#import "path-util.typ"
#import "matrix.typ"
#import "vector.typ"

// Compass direction to angle
#let named-border-anchors = (
  east: 0deg,
  north-east: 45deg,
  north: 90deg,
  north-west: 135deg,
  west: 180deg,
  south-west: 225deg,
  south: 270deg,
  south-east: 315deg,
)

// Path anchors
#let named-path-anchors = (
  start: 0%,
  mid: 50%,
  end: 100%,
)

/// Calculates a border anchor at the given angle by testing for an intersection between a line and the given drawables. Returns `none` if no intersection is found for better error reporting.
///
/// - center (vector): The position from which to start the test line.
/// - x-dist (number): The furthest distance the test line should go in the x direction.
/// - y-dist (number): The furthest distance the test line should go in the y direction.
/// - drawables (drawables): Drawables to test for an intersection against. Ideally should be of type path but all others are ignored.
/// - angle (angle): The angle to check for a border anchor at.
/// -> vector<float>,none
#let border(center, x-dist, y-dist, drawables, angle) = {
  x-dist += util.float-epsilon
  y-dist += util.float-epsilon

  if type(drawables) == dictionary {
    drawables = (drawables,)
  }

  let test-line = (
    center,
    (
      center.at(0) + x-dist * calc.cos(angle),
      center.at(1) + y-dist * calc.sin(angle),
      util.promote-float(center.at(2)),
    )
  )

  let pts = ()
  for drawable in drawables {
    if drawable.type != "path" {
      continue
    }
    pts += intersection.line-path(..test-line, drawable)
  }

  if pts.len() == 1 {
    return pts.first()
  }

  return if pts.len() == 1 {
    pts.first()
  } else if pts.len() > 1 {
    // Find the furthest intersection point from center
    util.sort-points-by-distance(center, pts).last()
  }
}


/// Setup an anchor calculation and handling function for an element. Unifies anchor error checking and calculation of the offset transform.
///
/// A tuple of a transformation matrix and function will be returned.
/// The transform is calculated by translating the given transform by the distance between the position of `offset-anchor` and `default`. It can then be used to correctly transform an element's drawables. If either are none the calculation won't happen but the transform will still be returned.
/// The function can be used to get the transformed anchors of an element by passing it a string. An empty array can be passed to get the list of valid anchors.
///
/// - callback (function, auto): The function to call to get a named anchor's position. The anchor's name will be passed and it should return a <Type>vector</Type> (`str => vector`). If no named anchors exist on the element `auto` can be given instead of a function.
/// - anchor-names (array): A list of valid anchor names. This list will be used to validate an anchor exists before `callback` is used.
/// - default (str,none): The name of the default anchor, if one exists.
/// - transform (matrix,none): The current transformation matrix to apply to an anchor's position before returning it. If `offset-anchor` and `default` is set, it will be first translated by the distance between them.
/// - name (str, none): The name of the element, this is only used in the error message in the event an anchor is invalid.
/// - offset-anchor (str, none): The name of an anchor to offset the transform by.
/// - border-anchors (bool): If true, add border anchors.
/// - path-anchors (bool): If true, add path anchors.
/// - radii (none,array): Radius tuple used for border anchor calculation.
/// - path (none,drawable): Path used for path and border anchor calculation.
/// -> array
#let setup(
    callback,
    anchor-names,
    default: none,
    transform: none,
    name: none,
    offset-anchor: none,
    border-anchors: false,
    path-anchors: false,
    radii: none,
    path: none,
    nested-anchors: false
  ) = {
  // Passing no callback is valid!
  if callback == auto {
    callback = (anchor) => {}
  }

  // Add enabled anchor names
  if border-anchors {
    assert("center" in anchor-names and radii != none and path != none,
      message: "Border anchors need a center anchor, radii and the path set!")
  }
  if path-anchors {
    assert(path != none,
      message: "Path anchors need the path set!")
  }

  // Anchor callback
  let calculate-anchor(anchor, transform: none) = {
    if anchor == () {
      return (anchor-names + if border-anchors { named-border-anchors.keys() } + if path-anchors { named-path-anchors.keys() }).dedup()
    }

    let out = none
    let nested-anchors = if type(anchor) == array {
      if not nested-anchors {
        anchor = anchor.join(".")
      } else {
        if anchor.len() > 1 {
          anchor
        }
        anchor = anchor.first()
      }
    } else if nested-anchors and type(anchor) == str {
      anchor = anchor.split(".")
      if anchor.len() > 1 {
        anchor
      }
      anchor = anchor.first()
    }


    if type(anchor) == str {
      if anchor in anchor-names or (anchor == "default" and default != none) {
        if anchor == "default" {
          anchor = default
        }
        
        out = callback(if nested-anchors != none { nested-anchors } else { anchor })
      } else if path-anchors and anchor in named-path-anchors {
        anchor = named-path-anchors.at(anchor)
      } else if border-anchors and anchor in named-border-anchors {
        anchor = named-border-anchors.at(anchor)
      } else if util.str-is-number(anchor) {
        anchor = util.str-to-number(if nested-anchors != none { nested-anchors.join(".") } else { anchor })
      } else {
        panic(
          strfmt(
            "Anchor '{}' not in anchors {} for element '{}'",
            anchor,
            repr(anchor-names),
            name
          )
        )
      }
    }

    if out == none {
      if type(anchor) in (ratio, float, int) {
        assert(path-anchors, message: strfmt("Element '{}' does not support path anchors.", name))
        let point-info = path-util.point-at(path.segments, anchor)
        assert.ne(point-info, none)
        out = point-info.point
      } else if type(anchor) == angle {
        assert(border-anchors, message: strfmt("Element '{}' does not support border anchors.", name))
        out = border(callback("center"), ..radii, path, anchor)
        for o in out {
          assert(type(o) == float, message: "Border anchor must return floats")
        }
        assert(out != none, message: strfmt("Element '{}' does not have a border for anchor '{}'.", name, anchor))
      } else {
        panic(strfmt("Unknown anchor '{}' for element '{}'", repr(anchor), name))
      }
    }

    return if transform != none {
      util.apply-transform(
        transform,
        out
      )
    } else {
      out
    }
  }

  if default != none and offset-anchor != none {
    let offset = matrix.transform-translate(
      ..vector.sub(calculate-anchor(default), calculate-anchor(offset-anchor)).slice(0, 3)
    )
    transform = if transform != none {
      matrix.mul-mat(
        transform,
        offset
      )
    } else {
      offset
    }
  }

  return (if transform == none { matrix.ident(4) } else { transform }, calculate-anchor.with(transform: transform))
}


