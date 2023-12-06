#import "@preview/oxifmt:0.2.0": strfmt

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
    assert(
      anchor in anchor-names,
      message: strfmt("Anchor '{}' not in anchors {} for element '{}'", anchor, repr(anchor-names), name)
      // message: strfmt("Anchor '{}' not in anchors {}", anchor, repr(anchor-names)) + if name != none { strfmt(" for element '{}'", name) }
    )

    let out = callback(anchor)
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
  assert(pts.len() > 0, message: strfmt("{} {} {}", test-line, drawables, angle))

  if pts.len() == 1 {
    return pts.first()
  }

  // Find the furthest intersection point from center
  let pt = pts.first()
  let d = vector.dist(center, pts.first())
  for i in range(1, pts.len()) {
    let nd = vector.dist(center, pts.at(i))
    if nd > d {
      d = nd
      pt = pts.at(i)
    }
  }

  return pt
}
