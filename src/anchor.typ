#import "deps.typ"
#import deps.oxifmt: strfmt

#import "util.typ"
#import "intersection.typ"
#import "drawable.typ"
#import "path-util.typ"
#import "matrix.typ"
#import "vector.typ"

// Compass direction to angle
#let compass-angle = (
  east: 0deg,
  north-east: 45deg,
  north: 90deg,
  north-west: 135deg,
  west: 180deg,
  south-west: 225deg,
  south: 270deg,
  south-east: 315deg,
)
#let compass-directions = compass-angle.keys()
#let compass-directions-with-center = compass-directions + ("center",)

// Path distance anchors
#let path-distances = (
  start: 0%,
  mid: 50%,
  end: 100%,
)
#let path-distance-names = path-distances.keys()

/// Setup an anchor calculation and handling function for an element. Unifies anchor error checking and calculation of the offset transform.
///
/// A tuple of a transformation matrix and function will be returned.
/// The transform is calculated by translating the given transform by the distance between the position of `offset-anchor` and `default`. It can then be used to correctly transform an element's drawables. If both either are none the calculation won't happen but the transform will still be returned.
/// The function can be used to get the transformed anchors of an element by passing it a string. An empty array can be passed to get the list of valid anchors.
///
/// - callback (function): The function to call to get an anchor's position. The anchor's name will be passed and it should return a vector (str => vector).
/// - anchor-names (array<str>): A list of valid anchor names. This list will be used to validate an anchor exists before `callback` is used.
/// - default (str): The name of the default anchor.
/// - transform (matrix): The current transformation matrix to apply to an anchor's position before returning it. If `offset-anchor` and `default` is set, it will be first translated by the distance between them.
/// - name (str): The name of the element, this is only used in the error message in the event an anchor is invalid.
/// - offset-anchor: The name of an anchor to offset the transform by.
/// -> (matrix, function)
#let setup(callback, anchor-names, default: none, transform: none, name: none, offset-anchor: none) = {
  if default != none and offset-anchor != none {
    assert(
      offset-anchor in anchor-names,
      message: strfmt("Anchor '{}' not in anchors {} for element '{}'", offset-anchor, repr(anchor-names), name)
    )
    let offset = matrix.transform-translate(
      ..vector.sub(callback(default), callback(offset-anchor)).slice(0, 3)
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

  let calculate-anchor(anchor) = {
    if anchor == () {
      return anchor-names
    }
    if anchor == "default" {
      assert.ne(default, none, message: strfmt("Element '{}' does not have a default anchor!", name))
      anchor = default
    }

    let out = callback(anchor)
    assert(
      out != none,
      message: strfmt("Anchor '{}' not in anchors {} for element '{}'", anchor, repr(anchor-names), name)
    )

    return if transform != none {
      util.apply-transform(
        transform,
        out
      )
    } else {
      out
    }
  }
  return (if transform == none { matrix.ident() } else { transform }, calculate-anchor)
}


/// Calculates a border anchor at the given angle by testing for an intersection between a line and the given drawables.
///
/// This function is not ready to be used widely in its current state. It is only to be used to calculate the cardinal anchors of the arc element until properly updated. It will panic if no intersections have been found.
///
/// - center (vector): The position from which to start the test line.
/// - x-dist (number): The furthest distance the test line should go in the x direction.
/// - y-dist (number): The furthest distance the test line should go in the y direction.
/// - drawables (drawables): Drawables to test for an intersection against. Ideally should be of type path but all others are ignored.
/// - angle (angle): The angle to check for a border anchor at.
/// -> vector
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
      center.at(2),
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

  // Find the furthest intersection point from center
  return util.sort-points-by-distance(center, pts).last()
}

/// Handle path distance anchor
#let resolve-distance(ctx, anchor, drawable) = {
  if type(anchor) in (int, float, length, ratio) {
    anchor = util.resolve-number(ctx, anchor)
    return path-util.point-on-path(drawable.segments, anchor)
  }
}

/// Handle border angle anchor
#let resolve-border-angle(anchor, center, rx, ry, drawable) = {
  return border(center, rx, ry, drawable, anchor)
}

/// Handle named compass direction
#let resolve-compass-dir(anchor, center, rx, ry, drawable, with-center: true) = {
  if type(anchor) == str {
    return if anchor in compass-directions {
      border(center, rx, ry, drawable, compass-angle.at(anchor))
    } else if with-center and anchor == "center" {
      center
    }
  }
}

#let resolve-line-shape(ctx, anchor, drawable) = {
  if type(drawable) == array {
    assert(drawable.len() == 1,
      message: "Expected a single path, got " + repr(drawable))
    drawable = drawable.first()
  }

  if type(anchor) == str and anchor in path-distance-names {
    anchor = path-distances.at(anchor)
  }

  return resolve-distance(ctx, anchor, drawable)
}

// Handle anchor for a closed shape
#let resolve-closed-shape(ctx, anchor, center, rx, ry, drawable) = {
  if type(drawable) == array {
    assert(drawable.len() == 1,
      message: "Expected a single path, got " + repr(drawable))
    drawable = drawable.first()
  }

  if type(anchor) == str and anchor in path-distance-names {
    anchor = path-distances.at(anchor)
  }

  if type(anchor) == str {
    return resolve-compass-dir(anchor, center, rx, ry, drawable)
  } else if type(anchor) == angle {
    return resolve-border-angle(anchor, center, rx, ry, drawable)
  } else {
    return resolve-distance(ctx, anchor, drawable)
  }
}
