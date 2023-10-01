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

#let brace-default-style = (
  amplitude: .7,
  pointiness: 15deg,
  outer-pointiness: 0,
  content-offset: .3,
)

/// Draw a curly brace between two points.
///
/// *Style root:* `brace`.
///
/// *Anchors:*
///   / start:   Where the brace starts, same as the `start` parameter.
///   / end:     Where the brace end, same as the `end` parameter.
///   / spike:   Point of the spike, halfway between `start` and `end` and shifted
///     by `amplitude` towards the pointing direction.
///   / content: Point to place content/text at, in front of the spike.
///   / center:  Center of the enclosing rectangle.
///   / (a-k):   Debug points `a` through `k`.
///
/// - start (coordinate): Start point
/// - end (coordinate): End point
/// - flip (bool): Flip the brace around
/// - debug (bool): Show debug lines and points
/// - name (string, none): Element name
/// - ..style (style): Style attributes
#let brace(
  start,
  end,
  flip: false,
  debug: false,
  name: none,
  ..style,
) = {
  // validate coordinates
  let t = (start, end).map(coordinate.resolve-system)

  group(name: name, ctx => {
    // get styles and validate types and values
    let style = util.merge-dictionary(brace-default-style,
      styles.resolve(ctx.style, style.named(), root: "brace"))

    let amplitude = style.amplitude
    assert(
      type(amplitude) in (int, float),
      message: "amplitude must be a number",
    )

    let pointiness = style.pointiness
    assert(
      type(pointiness) in (int, float)
        and pointiness >= 0 and pointiness <= 1
      or type(pointiness) == angle
        and pointiness >= 0deg and pointiness <= 90deg,
      message: "pointiness must be a factor between 0 and 1 or an angle between 0deg and 90deg",
    )
    let pointiness = if type(pointiness) == angle { pointiness } else { pointiness * 90deg }

    let outer-pointiness = style.outer-pointiness
    assert(
      outer-pointiness == auto
      or type(outer-pointiness) in (int, float)
        and outer-pointiness >= 0 and outer-pointiness <= 1
      or type(outer-pointiness) == angle
        and outer-pointiness >= 0deg and outer-pointiness <= 90deg,
      message: "outer-pointiness must be a factor between 0 and 1 or an angle between 0deg and 90deg or auto",
    )
    let outer-pointiness = if outer-pointiness == auto {
      pointiness
    } else if type(outer-pointiness) == angle {
      outer-pointiness
    } else {
      outer-pointiness * 90deg
    }

    let content-offset = style.content-offset
    assert(
      type(content-offset) in (int, float),
      message: "content-offset must be a number",
    )

    // we flip the brace by inverting the amplitude and pointiness values
    if flip {
      amplitude *= -1
      pointiness *= -1
      outer-pointiness *= -1
    }

    // 'abcd' is a rectangle with the base line 'ab' and the height 'amplitude'
    let a = start
    let b = end
    let c = (_rotate-around.with(len: amplitude, angle: -90deg), b, a)
    let d = (_rotate-around.with(len: amplitude, angle: +90deg), a, b)
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

    // 'i' and 'j' are the control points for the outer ends
    let i = (_rotate-around.with(angle: -outer-pointiness), a, d)
    let j = (_rotate-around.with(angle: +outer-pointiness), b, c)
    if debug {
      line(a, i, stroke: purple)
      line(b, j, stroke: orange)
    }

    // 'k' is the point where the content should be placed. It is offset from the spike (point 'f')
    // by 'content-offset' in the direction the spike is pointing
    let k = ((a, b) => {
      let rel = vector.sub(b, a)
      let scaled = vector.scale(vector.norm(rel), vector.len(rel) + content-offset)
      return vector.add(a, scaled)
    }, e, f)

    let points = (a: a, b: b, c: c, d: d, e: e, f: f, g: g, h: h, i: i, j: j, k: k)
    // combine the two bezier curves using 'merge-path' and apply styling
    merge-path({
      bezier(a, f, i, g)
      bezier(f, b, h, j)
    }, ..style)
    // define some named anchors
    anchor("spike", f)
    anchor("content", k)
    anchor("start", a)
    anchor("end", b)
    anchor("center", (e, .5, f))
    // define anchors for all points
    for (name, point) in points {
      anchor(name, point)
    }

    // label all points in debug mode
    if debug {
      for (name, point) in points {
        content(point, box(fill: luma(240), inset: .5pt, text(6pt, raw(name))))
      }
    }
  })
  // move to end point so the current position after this is the end position
  move-to(end)
}
