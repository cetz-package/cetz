#import "../vector.typ"
#import "../matrix.typ"
#import "../util.typ"
#import "../draw.typ": *

/// Rotates the vector 'ab' around 'a' and scales it to 'len', returns the absolute point 'c'.
#let _rotate-around(a, b, angle: 90deg, len: auto) = {
  let rel = vector.sub(b, a)
  let rotated = util.apply-transform(matrix.transform-rotate-z(angle), rel)
  let scaled = if len == auto {
    rotated
  } else {
    vector.scale(vector.norm(rotated), len)
  }
  return vector.add(a, scaled)
}

/// Draw a curly brace between two points.
///
/// *Anchors:*
///   / start:   Start coordinate
///   / end:     End coordinate
///   / spike:   Point of the spike
///   / content: Point to place content at
///   / center:  Center of the enclosing rectangle
///   / (a-i):   Debug points
///
/// - a (coordinate): Start point
/// - b (coordinate): End point
/// - amplitude (int,float): Height of the brace
/// - pointiness (angle): How pointy the spike should be. `0deg` for maximum pointiness, `90deg` for minimum.
/// - content-offset (int,float): Offset of the `content` anchor from the spike
/// - flip (bool): Flip the brace around, same as swapping the start and end points
/// - debug (bool): Show debug lines and points
/// - name (string,none): Element name
/// - ..style (style): Style attributes
#let brace(
  a,
  b,
  amplitude: .7,
  pointiness: 15deg,
  content-offset: .3,
  flip: false,
  debug: false,
  name: none,
  ..style,
) = {
  // TODO: custom style root
  // TODO: type and value assertions
  // flipping is achieved by swapping the start and end points, the parameter is just for convenience
  if flip {
    return brace(
      b,
      a,
      amplitude: amplitude,
      pointiness: pointiness,
      content-offset: content-offset,
      flip: false,
      debug: debug,
      name: name,
      ..style,
    )
  }

  // 'abcd' is a rectangle with the base line 'ab' and the height 'amplitude'
  let c = (_rotate-around.with(len: amplitude, angle: -90deg), b, a)
  let d = (_rotate-around.with(len: amplitude, angle: 90deg), a, b)
  if debug {
    line(a, b, stroke: red)
    line(b, c, stroke: blue)
    line(c, d, stroke: olive)
    line(d, a, stroke: yellow)
  }

  // 'ef' is the perpendicular line in the center of that rectangle, with length 'amplitude'
  let e = (a, .5, b)
  let f = (c, .5, d)
  if debug {
    line(e, f, stroke: eastern)
  }

  // 'g' and 'h' are the control points for the middle spike
  let g = (_rotate-around.with(angle: -pointiness), f, e)
  let h = (_rotate-around.with(angle: +pointiness), f, e)
  if debug {
    line(f, g, stroke: purple)
    line(f, h, stroke: orange)
  }

  // 'i' is the point where the content should be placed. It is offset from the spike (point 'f')
  // by 'content-offset' in the direction the spike is pointing
  let i = ((a, b) => {
    let rel = vector.sub(b, a)
    let scaled = vector.scale(vector.norm(rel), vector.len(rel) + content-offset)
    return vector.add(a, scaled)
  }, e, f)

  let points = (a: a, b: b, c: c, d: d, e: e, f: f, g: g, h: h, i: i)
  // wrap the brace in a named group so we can define custom anchors
  group({
    // combine the two bezier curves using 'merge-path' and apply styling
    merge-path({
      bezier(a, f, d, g)
      bezier(f, b, h, c)
    }, ..style)
    // define some named anchors
    anchor("spike", f)
    anchor("content", i)
    anchor("start", a)
    anchor("end", b)
    anchor("center", (e, .5, f))
    // define anchors for all points
    for (name, point) in points {
      anchor(name, point)
    }
  }, name: name)

  // label all points in debug mode
  if debug {
    for (name, point) in points {
      content(point, box(fill: luma(240), inset: .5pt, text(6pt, raw(name))))
    }
  }
}
