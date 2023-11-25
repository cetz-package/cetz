#import "../vector.typ"
#import "../matrix.typ"
#import "../util.typ"
#import "../draw.typ": *
#import "../coordinate.typ"
#import "../styles.typ"

// Rotates the vector 'ab' around 'a' and scales it to 'len', returns the absolute point 'c'.
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
  amplitude: .5,
  pointiness: 15deg,
  outer-pointiness: 0deg,
  content-offset: .3,
  debug-text-size: 6pt,
)

/// Draw a curly brace between two points.
///
/// #example(```
/// cetz.decorations.brace((0,1),(2,1))
///
/// cetz.decorations.brace((0,0),(2,0),
///   pointiness: 45deg, outer-pointiness: 45deg)
/// cetz.decorations.brace((0,-1),(2,-1),
///   pointiness: 90deg, outer-pointiness: 90deg)
/// ```)
///
/// *Style Root:* `brace`. \
/// *Style Keys:*
///   #show-parameter-block("amplitude", ("number"), [
///     Sets the height of the brace, from its baseline to its middle tip.], default: .5)
///   #show-parameter-block("pointiness", ("ratio", "angle"), [
///     How pointy the spike should be. #0deg or `0%` for maximum pointiness, #90deg or `100%` for minimum.], default: 15deg)
///   #show-parameter-block("outer-pointiness", ("ratio", "angle"), [
///     How pointy the outer edges should be. #0deg or `0` for maximum pointiness (allowing for a smooth transition to a straight line), #90deg or `1` for minimum. Setting this to #auto will use the value set for `pointiness`.], default: 15deg)
///   #show-parameter-block("content-offset", ("number","length"), [
///     Offset of the `"content"` anchor from the spike of the brace.], default: .3)
///
/// *Anchors:*
///   / start:   Where the brace starts, same as the `start` parameter.
///   / end:     Where the brace end, same as the `end` parameter.
///   / spike:   Point of the spike, halfway between `start` and `end` and shifted
///     by `amplitude` towards the pointing direction.
///   / content: Point to place content/text at, in front of the spike.
///   / center:  Center of the enclosing rectangle.
///
/// - start (coordinate): Start point
/// - end (coordinate): End point
/// - flip (bool): Flip the brace around
/// - name (string, none): Element name used for querying anchors
/// - ..style (style): Style key-value pairs
#let brace(
  start,
  end,
  flip: false,
  debug: false,
  name: none,
  ..style,
) = {
  // Validate coordinates
  let t = (start, end).map(coordinate.resolve-system)

  group(name: name, ctx => {
    // Get styles and validate types and values
    let style = styles.resolve(ctx.style, style.named(),
      root: "brace", base: brace-default-style)

    let amplitude = style.amplitude
    assert(
      type(amplitude) in (int, float),
      message: "amplitude must be a number, got " + repr(amplitude),
    )

    let pointiness = style.pointiness
    assert(
      type(pointiness) in (int, float)
        and pointiness >= 0 and pointiness <= 1
      or type(pointiness) == ratio
        and pointiness >= 0% and pointiness <= 100%
      or type(pointiness) == angle
        and pointiness >= 0deg and pointiness <= 90deg,
      message: "pointiness must be a factor between 0 and 1 or an angle between 0deg and 90deg, got " + repr(pointiness),
    )
    let pointiness = if type(pointiness) == angle { pointiness } else { pointiness * 90deg }

    let outer-pointiness = style.outer-pointiness
    assert(
      outer-pointiness == auto
      or type(outer-pointiness) in (int, float)
        and outer-pointiness >= 0 and outer-pointiness <= 1
      or type(outer-pointiness) == ratio
        and outer-pointiness >= 0% and outer-pointiness <= 100%
      or type(outer-pointiness) == angle
        and outer-pointiness >= 0deg and outer-pointiness <= 90deg,
      message: "outer-pointiness must be a factor between 0 and 1 or an angle between 0deg and 90deg or auto, got " + repr(outer-pointiness),
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
      message: "content-offset must be a number, got " + repr(content-offset),
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
        content(point, box(fill: luma(240), inset: .5pt, text(style.debug-text-size, raw(name))))
      }
    }
  })
  // move to end point so the current position after this is the end position
  move-to(end)
}

#let flat-brace-default-style = (
  amplitude: .3,
  aspect: 50%,
  curves: (1, .5, .6, .15),
  outer-curves: auto,
  content-offset: .3,
  debug-text-size: 6pt,
)

/// Draw a flat curly brace between two points.
///
/// #example(```
/// cetz.decorations.flat-brace((0,1),(2,1))
///
/// cetz.decorations.flat-brace((0,0),(2,0),
///   curves: .2,
///   aspect: 25%)
/// cetz.decorations.flat-brace((0,-1),(2,-1),
///   outer-curves: 0,
///   aspect: 75%)
/// ```)
///
/// This mimics the braces from TikZ's `decorations.pathreplacing` library#footnote[https://github.com/pgf-tikz/pgf/blob/6e5fd71581ab04351a89553a259b57988bc28140/tex/generic/pgf/libraries/decorations/pgflibrarydecorations.pathreplacing.code.tex#L136-L185].
/// In contrast to @@brace(), these braces use straight line segments, resulting
/// in better looks for long braces with a small amplitude.
///
/// *Style Root:* `flat-brace` \
/// *Style Keys:*
///   #show-parameter-block("amplitude", ("number"), [
///     Determines how much the brace rises above the base line.], default: .3)
///   #show-parameter-block("aspect", ("ratio"), [
///     Determines the fraction of the total length where the spike will be placed.], default: 50%)
///   #show-parameter-block("curves", ("number"), [
///     Curviness factor of the brace, a factor of 0 means no curves.], default: auto)
///   #show-parameter-block("outer-curves", ("auto", "number"), [
///     Curviness factor of the outer curves of the brace. A factor of 0 means no curves.], default: auto)
///
/// *Anchors:*
///   / start:   Where the brace starts, same as the `start` parameter.
///   / end:     Where the brace end, same as the `end` parameter.
///   / spike:   Point of the spike's top.
///   / content: Point to place content/text at, in front of the spike.
///   / center:  Center of the enclosing rectangle.
///
/// - start (coordinate): Start point
/// - end (coordinate): End point
/// - flip (bool): Flip the brace around
/// - name (string, none): Element name for querying anchors
/// - ..style (style): Style key-value pairs
#let flat-brace(
  start,
  end,
  flip: false,
  debug: false,
  name: none,
  ..style,
) = {
  // Validate coordinates
  let t = (start, end).map(coordinate.resolve-system)

  group(name: name, ctx => {
    // Get styles and validate their types and values
    let style = styles.resolve(ctx.style, style.named(),
      root: "flat-brace", base: flat-brace-default-style)

    let amplitude = style.amplitude
    assert(
      type(amplitude) in (int, float),
      message: "amplitude must be a number, got " + repr(amplitude),
    )
    // we achieve flipping by inverting the amplitude
    if flip { amplitude *= -1 }

    let aspect = style.aspect
    assert(
      type(aspect) == ratio
        and aspect >= 0% and aspect <= 100%
      or type(aspect) == (int, float)
        and aspect >= 0 and aspect <= 1,
      message: "aspect must be a ratio between 0% and 100%, got " + repr(aspect),
    )
    if type(aspect) == ratio { aspect /= 100% }

    let inner-curves = style.curves
    assert(
      type(inner-curves) in (int, float)
      or type(inner-curves) == array
        and inner-curves.all(v => type(v) in (int, float, type(auto))),
      message: "curves must be a number, or an array of numbers or auto, got " + repr(inner-curves),
    )
    if type(inner-curves) in (int, float) { inner-curves = (inner-curves,) }
    while inner-curves.len() < flat-brace-default-style.curves.len() {
      inner-curves.push(auto)
    }
    inner-curves = inner-curves.enumerate().map(((idx, v)) => if v == auto {
      flat-brace-default-style.curves.at(idx)
    } else { v })

    let outer-curves = style.outer-curves
    assert(
      type(outer-curves) in (int, float, type(auto))
      or type(outer-curves) == array
        and outer-curves.all(v => type(v) in (int, float, type(auto))),
      message: "outer-curves must be auto, a number, or an array of numbers or auto, got " + repr(outer-curves),
    )
    if outer-curves == auto {
      outer-curves = inner-curves
    } else {
      if type(outer-curves) in (int, float) { outer-curves = (outer-curves,) }
      while outer-curves.len() < inner-curves.len() { outer-curves.push(auto) }
      outer-curves = outer-curves.enumerate()
        .map(((idx, v)) => if v == auto { inner-curves.at(idx) } else { v })
    }

    let content-offset = style.content-offset
    assert(
      type(content-offset) in (int, float),
      message: "content-offset must be a number, got " + repr(content-offset),
    )

    // all the following code assumes the brace to start at (0, 0), growing to the right,
    // pointing upwards, so we set the origin and rotate the entire group accordingly
    let (_, start, end) = coordinate.resolve(ctx, start, end)
    set-origin(start)
    rotate(vector.angle2(start, end) * -1)

    let length = vector.dist(start, end)
    let middle = aspect * length
    let horizon = amplitude / 2

    let normal-outer = calc.abs(amplitude * outer-curves.at(0))
    let normal-inner = calc.abs(amplitude * inner-curves.at(0))
    let length-left  =          middle
    let length-right = length - middle

    // width of left-outer, left-inner, right-inner, right-outer curve segments
    let lo = if 2 * normal-outer > length-left  { length-left  / 2 } else { normal-outer }
    let li = if 2 * normal-inner > length-left  { length-left  / 2 } else { normal-inner }
    let ri = if 2 * normal-inner > length-right { length-right / 2 } else { normal-inner }
    let ro = if 2 * normal-outer > length-right { length-right / 2 } else { normal-outer }

    // 'a' and 'b' are start and end
    let a = (     0, 0)
    let b = (length, 0)
    // 'c' is the spike's top
    let c = (middle, amplitude)
    // 'de' is the left line, 'fg' is the right line
    let d = (         lo, horizon)
    let e = (middle - li, horizon)
    let f = (middle + ri, horizon)
    let g = (length - ro, horizon)
    // 'h' is where to place content, above the spike
    let h = (middle, amplitude + content-offset)

    // list of all named points to show in debug mode
    let points = (a: a, b: b, c: c, d: d, e: e, f: f, g: g, h: h)

    // bezier control points: in 'dlc' 'd' stands for the point 'd' where the control point is used,
    // 'l' stands for left of spike, 'c' stands for control point
    let dlc = (         (1 - outer-curves.at(1)) * lo, horizon)
    let elc = (middle - (1 - inner-curves.at(1)) * li, horizon)
    let frc = (middle + (1 - inner-curves.at(1)) * ri, horizon)
    let grc = (length - (1 - outer-curves.at(1)) * ro, horizon)
    let alc = (              outer-curves.at(3)  * lo,      outer-curves.at(2) / 2  * amplitude)
    let clc = (middle -      inner-curves.at(3)  * li, (1 - inner-curves.at(2) / 2) * amplitude)
    let crc = (middle +      inner-curves.at(3)  * ri, (1 - inner-curves.at(2) / 2) * amplitude)
    let brc = (length -      outer-curves.at(3)  * ro,      outer-curves.at(2) / 2  * amplitude)

    merge-path({
      bezier(a, d, alc, dlc)
      bezier(e, c, elc, clc)
      bezier(c, f, crc, frc)
      bezier(g, b, grc, brc)
    })
    // define some named anchors
    anchor("spike", c)
    anchor("content", h)
    anchor("start", a)
    anchor("end", b)
    anchor("center", (d, .5, g))
    // define anchors for all points
    for (name, point) in points {
      anchor(name, point)
    }
    if debug {
      // show bezier control points using colored lines
      line(stroke: purple, a, alc)
      line(stroke: blue,   d, dlc)
      line(stroke: olive,  e, elc)
      line(stroke: red,    c, clc)
      line(stroke: red,    c, crc)
      line(stroke: olive,  f, frc)
      line(stroke: blue,   g, grc)
      line(stroke: purple, b, brc)
      // show all named points
      for (name, point) in points {
        content(point, box(fill: luma(240), inset: .5pt, text(style.debug-text-size, raw(name))))
      }
    }
  })
  // move to end point so the current position after this is the end position
  move-to(end)
}
