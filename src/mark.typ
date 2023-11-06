#let typst-length = length
#import "bezier.typ"
#import "drawable.typ"
#import "vector.typ"
#import "util.typ"
#import "path-util.typ"

// Calculate offset for a triangular mark (triangle, harpoon, ..)
#let _triangular-mark-offset(ctx, mark-width, mark-length, symbol, style) = {
  let revert = symbol == "<"
  let sign = if revert { 1 } else { -1 }

  let stroke = line(stroke: style.stroke).stroke
  let (width, limit, join) = (
    stroke.thickness, stroke.miter-limit, stroke.join)

  // Fallback to Typst's defaults
  if width == auto { width = 1pt }
  if limit == auto { limit = 4 }
  if join  == auto { join = "miter" }

  if type(width) == typst-length { width /= ctx.length }

  if style.length == 0 { return 0 }
  let angle = calc.atan(mark-width / (2 * mark-length)) * 2
  if join == "miter" {
    let angle = calc.abs(angle)
    let miter = if angle == 180deg {
      width / 2
    } else if angle == 0deg or angle == 360deg {
      0
    } else {
      (1 / calc.sin(angle / 2) * width / 2)
    }

    if calc.abs(2 * miter / width) <= limit {
      return miter * sign
    } else {
      // If the miter limit kicks in, use bevel calculation
      join = "bevel"
    }
  }

  if join == "bevel" {
    return calc.sin(angle / 2) * width / 2 * sign
  } else {
    return width / 2 * sign
  }
}

// Calculate the offset of a mark symbol.
// For triangular marks, this is the half
// of the miter length or halt of the stroke
// thickness, depending on the joint style.
#let calc-mark-offset(ctx, symbol, style) = {
  if symbol in ("<", ">") {
    return _triangular-mark-offset(ctx, style.width, style.length, symbol, style)
  } else if symbol in ("left-harpoon", "right-harpoon") {
    return _triangular-mark-offset(ctx, style.width / 2, style.length, symbol, style)
  } else if symbol == "<>" {
    return _triangular-mark-offset(ctx, style.width, style.length / 2, symbol, style)
  } else {
    // Offset by half the strok width to have the stroke edge touch
    // the target position.
    let width = line(stroke: style.stroke).stroke.thickness
    if width == auto { width = 1pt }
    if type(width) == length { width /= ctx.length }

    return -width / 2
  }
}

// Get mark symbol mid length, that is the length from the tip to the mid-point
// of its base. For triangular shaped marks, that is the distance between tip and
// inset.
#let mark-mid-length(symbol, style) = {
  let scale = style.scale
  let length = style.length * scale

  if symbol in ("<", ">", "left-harpoon", "right-harpoon") {
    return length - style.inset * scale
  }

  return length
}

/// Place marks along line of points
///
/// - ctx (context): Context
/// - pts (array): Array of vectors
/// - style (style): Mark style dictionary
/// -> (drawables, pts) Tuple of drawables and adjusted line points
#let place-marks-along-line(ctx, pts, style) = {
  let start = if type(style.start) == str {
    (style.start,)
  } else {
    style.start
  }

  // Offset start
  if start != none and start.len() > 0 {
    let off = calc-mark-offset(ctx, start.at(0), style)
    let dir = vector.norm(vector.sub(pts.at(1), pts.at(0)))

    pts.at(0) = vector.sub(pts.at(0), vector.scale(dir, off))
  }

  let end = if type(style.end) == str {
    (style.end,)
  } else {
    style.end
  }

  // Offset end
  if end != none and end.len() > 0 {
    let off = calc-mark-offset(ctx, end.at(0), style)
    let dir = vector.norm(vector.sub(pts.at(-2), pts.at(-1)))

    pts.at(-1) = vector.sub(pts.at(-1), vector.scale(dir, off))
  }

  let drawables = ()

  // Draw start marks
  if start != none {
    let dir = vector.norm(vector.sub(pts.at(1), pts.at(0)))
    let pt = pts.at(0)
    for m in start {
      drawables.push(drawable.mark(
        vector.add(pt, dir), pt, m, style))
      pt = vector.add(pt, vector.scale(dir, mark-mid-length(m, style) + style.sep))
    }
  }

  // Draw end marks
  if end != none {
    let dir = vector.norm(vector.sub(pts.at(-1), pts.at(-2)))
    let pt = pts.at(-1)
    for m in end {
      drawables.push(drawable.mark(
        vector.sub(pt, dir), pt, m, style))
      pt = vector.sub(pt, vector.scale(dir, mark-mid-length(m, style) + style.sep))
    }
  }

  return (drawables, pts)
}

// Shorten curve by distance
#let _shorten-curve(curve, distance, style) = {
  assert(style.shorten in ("LINEAR", "CURVED"),
    message: "Invalid cubic shorten style")
  let quick = style.shorten == "LINEAR"
  if quick {
    return bezier.cubic-shorten-linear(..curve, distance)
  } else {
    return bezier.cubic-shorten(..curve, distance)
  }
}

/// Place marks along a cubic bezier curve
///
/// - ctx (context): Context
/// - curve (array): Array of curve points (start, end, ctrl-1, ctrl-2)
/// - style (style): Curve style
/// - mark-style (style): Mark style
/// -> (drawables, curve) Tuple of drawables and adjusted curve points
#let place-marks-along-bezier(ctx, curve, style, mark-style) = {
  let samples = calc.max(2, calc.min(mark-style.position-samples, 1000))

  let start = if type(mark-style.start) == str {
    (mark-style.start,)
  } else {
    mark-style.start
  }

  // Offset start
  if start != none and start.len() > 0 {
    let off = calc-mark-offset(ctx, start.at(0), mark-style)
    curve = _shorten-curve(curve, calc.max(0, -off), style)
  }

  let end = if type(mark-style.end) == str {
    (mark-style.end,)
  } else {
    mark-style.end
  }

  // Offset end
  if end != none and end.len() > 0 {
    let off = calc-mark-offset(ctx, end.at(0), mark-style)
    curve = _shorten-curve(curve, calc.min(0, off), style)
  }

  let drawables = ()
  let flex = mark-style.flex

  // Draw start mark-style
  if start != none {
    let dist = 0
    for m in start {
      let t = if dist > 0 {
        bezier.cubic-t-for-distance(..curve, dist, samples: samples)
      } else {
        0
      }

      let pt = bezier.cubic-point(..curve, t)
      let dir = if flex {
        let t-base = bezier.cubic-t-for-distance(..curve, dist + mark-mid-length(m, mark-style),
          samples: samples)
        vector.sub(bezier.cubic-point(..curve, t-base), pt)
      } else {
        bezier.cubic-derivative(..curve, t)
      }
      if vector.len(dir) == 0 {break} // TODO: Emit warning

      drawables.push(drawable.mark(
        vector.add(pt, dir), pt, m, mark-style))

      dist += mark-mid-length(m, mark-style) + mark-style.sep
    }
  }

  // Draw end mark-style
  if end != none {
    let dist = 0
    for m in end {
      let t = if dist > 0 {
        bezier.cubic-t-for-distance(..curve, -dist, samples: samples)
      } else {
        1
      }

      let pt = bezier.cubic-point(..curve, t)
      let dir = if flex {
        let t-base = bezier.cubic-t-for-distance(..curve, -dist - mark-mid-length(m, mark-style),
          samples: samples)
        vector.sub(pt, bezier.cubic-point(..curve, t-base))
      } else {
        bezier.cubic-derivative(..curve, t)
      }
      if vector.len(dir) == 0 {break} // TODO: Emit warning

      drawables.push(drawable.mark(
        vector.sub(pt, dir), pt, m, mark-style))

      dist += mark-mid-length(m, mark-style) + mark-style.sep
    }
  }

  return (drawables, curve)
}

/// Place marks along a list of cubic bezier curves
///
/// - ctx (context): Context
/// - curves (array): Array of curves
/// - style (style): Curve style
/// - mark-style (style): Mark style
/// -> (drawables, curves) Tuple of drawables and adjusted curves
#let place-marks-along-beziers(ctx, curves, style, mark-style) = {
  if curves.len() == 1 {
    let (marks, curve) = place-marks-along-bezier(
      ctx, curves.at(0), style, mark-style)
    return (marks, (curve,))
  } else {
    // TODO: This has the limitation that only the first curve of
    //       the catmull-rom is used for placing marks.
    let start-mark-style = mark-style
    start-mark-style.end = none
    let (start-marks, start-curve) = place-marks-along-bezier(
      ctx, curves.at(0), style, start-mark-style)

    let end-mark-style = mark-style
    end-mark-style.start = none
    let (end-marks, end-curve) = place-marks-along-bezier(
      ctx, curves.at(-1), style, end-mark-style)
    curves.at(0) = start-curve
    curves.at(-1) = end-curve
    return (start-marks + end-marks, curves)
  }
}

#let place-marks-along-arc(ctx, start-angle, stop-angle, arc-start,
                           rx, ry, style, mark-style) = {
  let adjust = style.at("mode", default: "OPEN") == "OPEN"

  let r-at(angle) = calc.sqrt(calc.pow(calc.cos(angle) * ry, 2) +
                              calc.pow(calc.sin(angle) * rx, 2))

  let start = if type(mark-style.start) == str {
    (mark-style.start,)
  } else {
    mark-style.start
  }

  // Offset start
  if start != none and start.len() > 0 {
    let off = calc-mark-offset(ctx, start.at(0), mark-style)

    // Remember original start
    let orig-start = start-angle

    // Calc an optimized start angle
    let r = r-at(start-angle)
    start-angle -= (off * 360deg) / (2 * calc.pi * r)

    // Reposition the arc
    let diff = vector.sub((calc.cos(start-angle) * rx, calc.sin(start-angle) * ry),
                          (calc.cos(orig-start) * rx, calc.sin(orig-start) * ry))
    arc-start = vector.add(arc-start, diff)
  }

  let end = if type(mark-style.end) == str {
    (mark-style.end,)
  } else {
    mark-style.end
  }

  // Offset end
  if end != none and end.len() > 0 {
    let off = calc-mark-offset(ctx, end.at(0), mark-style)

    let r = r-at(stop-angle)
    stop-angle += (off * 360deg) / (2 * calc.pi * r)
  }

  let arc-center = vector.sub(arc-start, (calc.cos(start-angle) * rx,
                                          calc.sin(start-angle) * ry))
  let pt-at(angle) = vector.add(arc-center,
    (calc.cos(angle) * rx, calc.sin(angle) * ry, 0))

  let drawables = ()

  // Draw start marks
  if start != none {
    let angle = start-angle
    for m in start {
      let length = mark-mid-length(m, mark-style)
      let r = r-at(angle)
      let angle-offset = (length * 360deg) / (2 * calc.pi * r)

      let pt = pt-at(angle)
      drawables.push(drawable.mark(
        pt-at(angle + angle-offset), pt, m, mark-style))

      let angle-offset = ((length + mark-style.sep) * 360deg) / (2 * calc.pi * r)
      angle += angle-offset
    }
  }

  // Draw end marks
  if end != none {
    let angle = stop-angle
    for m in end {
      let length = mark-mid-length(m, mark-style)
      let r = r-at(angle)
      let angle-offset = (length * 360deg) / (2 * calc.pi * r)

      let pt = pt-at(angle)
      drawables.push(drawable.mark(
        pt-at(angle - angle-offset), pt, m, mark-style))

      let angle-offset = ((length + mark-style.sep) * 360deg) / (2 * calc.pi * r)
      angle -= angle-offset
    }
  }

  return (drawables, arc-start, start-angle, stop-angle)
}
