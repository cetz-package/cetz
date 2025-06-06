#import "/src/vector.typ"
#import "/src/matrix.typ"
#import "/src/util.typ"
#import "/src/draw.typ"
#import "/src/coordinate.typ"
#import "/src/styles.typ"


#let brace-default-style = (
  amplitude: 0.25,

  // Thickness relative to half the amplitude
  thickness: 0.015cm,

  // Outset of the inner side of the mid spike
  pointiness: 80%,

  // Draw a tapered brace
  taper: true,

  // Inset of the outer spike curves
  outer-inset: 0.5cm,
  outer-curvyness: 60%,

  // Outset of the inner spike curves
  inner-outset: 0.2cm,
  inner-curvyness: 80%,

  // Extra inset applied to both tips of the brace
  outer-thickness: 0,

  // Vertically flip
  flip: false,

  // Offset to apply to the "content" anchor
  content-offset: .3cm,

  stroke: none,
  fill: black,
)

/// Draw a curly brace between two points.
///
/// ```typc example
/// cetz.decorations.brace((0,1),(2,1))
/// cetz.decorations.brace((0,0),(2,0), outer-inset: 0)
/// ```
///
/// - start (coordinate): Start point
/// - end (coordinate): End point
/// - name (string, none): Element name used for querying anchors
/// - ..style (style): Style key-value pairs
///
/// ## Styling
///
/// *Root:* `brace`
/// - amplitude (number) = 0.25cm: Sets the height of the brace, from its baseline to its middle tip.
/// - thickness (number,ratio) = 0.015cm: Thickness of tapered braces (if ratio, relative to half the amplitude).
/// - pointiness (ratio) = 50%: Thickness of the mid-spice
/// - taper (boor) = true: Draw a tapered brace
/// - outer-inset (number,ratio): Inset of the outer curve points
/// - outer-curvyness (ratio): Curvyness of the outer curves
/// - inner-outset (number,ratio): Inset of the inner tip curve points
/// - inner-curvyness (ratio): Curvyness of the inner tip curves
/// - outer-thickness (number) = 0: Thickness of the outer tips
/// - content-offset (number) = 0.3: Offset of the `"content"` anchor from the spike of the brace.
/// - flip (bool) = false: Mirror the brace along the line between start and end.
///
/// Use the `fill` style for tapered braces and set `stroke` to none.
///
/// ## Anchors
/// - **start** Where the brace starts, same as the `start` parameter.
/// - **end** Where the brace end, same as the `end` parameter.
/// - **spike** Point of the spike, halfway between `start` and `end` and shifted by `amplitude` towards the pointing direction.
/// - **content** Point to place content/text at, in front of the spike.
/// - **center** Center of the enclosing rectangle.

#let brace(start, end, ..style, name: none) = {
  import draw: line, bezier, merge-path, scope, scale, translate, anchor, group

  let lerp(a, b, t) = {
    t = if type(t) == ratio { t / 100% } else { t }
    return (1 - t) * a + t * b
  }

  let draw-shape(x0, x1, x2, style, is-inner: false) = {
    let x-dist = x1 - x0

    let height = style.amplitude
    let pointiness = style.pointiness
    let thickness = style.thickness * (if is-inner { -1 } else { 1 })
    if style.flip {
      height *= -1
      thickness *= -1
    }

    let mid = height / 2

    let outer-inset = calc.min(style.outer-inset, x-dist / 2)
    let outer-curve-slant = 100% - style.outer-curvyness

    let inner-outset = calc.min(style.inner-outset, x-dist / 2)
    let inner-curve-slant = 100% - style.inner-curvyness

    let outer-thickness = if is-inner {
      style.outer-thickness
    } else {
      0
    }

    let a   = (x0 + outer-thickness, 0)
    let a-b = (lerp(x0, x0 + outer-inset, outer-curve-slant), mid + thickness)
    let b   = (x0 + outer-inset, mid + thickness)

    let c   = (x1 - inner-outset, mid + thickness)
    let c-d = (lerp(x1, x1 - inner-outset, inner-curve-slant), mid + thickness)
    let d   = if is-inner {
      (x1, lerp(mid + thickness, height, pointiness))
    } else {
      (x1, height)
    }

    let d-e = (lerp(x1, x1 + inner-outset, inner-curve-slant), mid + thickness)
    let e   = (x1 + inner-outset, mid + thickness)

    let f   = (x2 - outer-inset, mid + thickness)
    let f-g = (lerp(x2, x2 - outer-inset, outer-curve-slant), mid + thickness)
    let g   = (x2 - outer-thickness, 0)

    if not is-inner {
      bezier(a, b, a-b, a-b)
      line(b, c)
      bezier(c, d, c-d, c-d)

      bezier(d, e, d-e, d-e)
      line(e, f)
      bezier(f, g, f-g, f-g)
    } else {
      bezier(g, f, f-g, f-g)
      line(f, e)
      bezier(e, d, d-e, d-e)

      bezier(d, c, c-d, c-d)
      line(c, b)
      bezier(b, a, a-b, a-b)
    }
  }

  draw.group(name: name, ctx => {
    let (_, x0, x1) = coordinate.resolve(ctx, start, end)

    let style = styles.resolve(ctx.style, root: "brace", base: brace-default-style, merge: style.named())

    // Resolve thickness
    if type(style.thickness) == ratio {
      style.thickness = style.thickness / 100% * style.amplitude / 2
    }

    // Resolve relative style keys
    for key in ("inner-outset", "outer-inset") {
      if type(style.at(key)) == ratio {
         style.at(key) = style.at(key) / 50% * vector.dist(x0, x1)
      }
    }

    // Resolve length style keys
    for key in ("inner-outset", "outer-inset", "thickness", "amplitude", "content-offset") {
      style.at(key) = util.resolve-number(ctx, style.at(key))
    }

    let width = vector.dist(x0, x1)
    let angle = vector.angle2(x0, x1)

    draw.set-origin(x0)
    draw.rotate(angle)

    merge-path({
      draw-shape(0, width / 2, width, style)
      if style.taper {
        draw-shape(0, width / 2, width, style, is-inner: true)
      }
    }, close: style.taper, stroke: style.stroke, fill: style.fill)

    anchor("start", (0, 0))
    anchor("default", (width / 2, 0))
    anchor("end", (width, 0))
    anchor("spike", (width / 2, style.amplitude))
    anchor("content", (width / 2, style.amplitude + style.content-offset))

    draw.move-to(end)
  })
}


#let flat-brace-default-style = (
  stroke: auto,
  fill: none,
  amplitude: .3,
  aspect: 50%,
  curves: (1, .5, .6, .15),
  outer-curves: auto,
  content-offset: .3,
  debug-text-size: 6pt,
)

/// Draw a flat curly brace between two points.
///
/// ```typc example
/// cetz.decorations.flat-brace((0,1),(2,1))
///
/// cetz.decorations.flat-brace((0,0),(2,0),
///   curves: .2,
///   aspect: 25%)
/// cetz.decorations.flat-brace((0,-1),(2,-1),
///   outer-curves: 0,
///   aspect: 75%)
/// ```
///
/// This mimics the braces from TikZ's [`decorations.pathreplacing` library](https://github.com/pgf-tikz/pgf/blob/6e5fd71581ab04351a89553a259b57988bc28140/tex/generic/pgf/libraries/decorations/pgflibrarydecorations.pathreplacing.code.tex#L136-L185).
/// In contrast to the `brace` function, these braces use straight line segments, resulting in better looks for long braces with a small amplitude.
///
/// - start (coordinate): Start point
/// - end (coordinate): End point
/// - flip (bool): Flip the brace around
/// - name (str, none): Element name for querying anchors
/// - debug (bool):
/// - ..style (style): Style key-value pairs
///
/// ## Styling
///
/// *Root:* `flat-brace`
/// - amplitude (number) = 0.3: Determines how much the brace rises above the base line.
/// - aspect (ratio) = 50% Determines the fraction of the total length where the spike will be placed.
/// - curves (number, auto, array) = auto: Curviness factor of the brace, a factor of 0 means no curves.
/// - outer-curves (number, auto, array) = auto: Curviness factor of the outer curves of the brace. A factor of 0 means no curves.
///
/// ## Anchors
/// - **start** Where the brace starts, same as the `start` parameter.
/// - **end** Where the brace end, same as the `end` parameter.
/// - **spike** Point of the spike's top.
/// - **content** Point to place content/text at, in front of the spike.
/// - **center**  Center of the enclosing rectangle.
#let flat-brace(
  start,
  end,
  flip: false,
  debug: false,
  name: none,
  ..style,
) = {
  draw.group(name: name, ctx => {
    // Get styles and validate their types and values
    let style = styles.resolve(ctx.style, merge: style.named(),
      root: "flat-brace", base: flat-brace-default-style)

    let amplitude = style.amplitude
    assert(
      type(amplitude) in (int, float),
      message: "amplitude must be a number, got " + repr(amplitude),
    )

    let aspect = style.aspect
    assert(
      (type(aspect) == ratio
        and aspect >= 0% and aspect <= 100%)
      or (type(aspect) in (int, float)
        and aspect >= 0 and aspect <= 1),
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
    draw.set-origin(start)
    draw.rotate(vector.angle2(start, end))

    // we achieve flipping by inverting the amplitude
    if flip {
      amplitude *= -1
      content-offset *= -1
    }

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

    draw.merge-path({
      draw.bezier(a, d, alc, dlc)
      draw.bezier(e, c, elc, clc)
      draw.bezier(c, f, crc, frc)
      draw.bezier(g, b, grc, brc)
    }, stroke: style.stroke, fill: style.fill)

    // Define some named anchors
    draw.anchor("spike", c)
    draw.anchor("content", h)
    draw.anchor("start", a)
    draw.anchor("end", b)
    draw.anchor("default", (d, 50%, g))

    // Define anchors for all points
    for (name, point) in points {
      draw.anchor(name, point)
    }
  })

  // Move to end point so the current position after this is the end position
  draw.move-to(end)
}
