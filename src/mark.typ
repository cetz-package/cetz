#let typst-length = length

#import "drawable.typ"
#import "vector.typ"
#import "path-util.typ"

// Calculate offset for a triangular mark (triangle, harpoon, ..)
#let _triangular-mark-offset(ctx, mark-width, mark-length, symbol, style) = {
  let revert = symbol == "<"
  let sign = if revert { 0 } else { -1 }

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

  return 0
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
    let width = line(stroke: style.stroke).stroke.thickness
    if width == auto { width = 1pt }
    if type(width) == length { width /= ctx.length }

    return -width / 2
  }

  return 0
}

// Get mark symbol mid length, that is the length from the tip to the mid-point
// of its base. For triangular shaped marks, that is the length minus the inset.
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
/// - marks (style): Mark style dictionary
/// -> (drawables, pts) Tuple of drawables and adjusted line points
#let place-marks-along-line(ctx, pts, marks) = {
  let start = if type(marks.start) == str {
    (marks.start,)
  } else {
    marks.start
  }

  // Offset start
  if start != none and start.len() > 0 {
    let off = calc-mark-offset(ctx, start.at(0), marks)
    let dir = vector.norm(vector.sub(pts.at(1), pts.at(0)))

    pts.at(0) = vector.sub(pts.at(0), vector.scale(dir, off))
  }

  let end = if type(marks.end) == str {
    (marks.end,)
  } else {
    marks.end
  }

  // Offset end
  if end != none and end.len() > 0 {
    let off = calc-mark-offset(ctx, end.at(0), marks)
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
        vector.add(pt, dir), pt, m, marks))
      pt = vector.add(pt, vector.scale(dir, mark-mid-length(m, marks) + marks.sep))
    }
  }

  // Draw end marks
  if end != none {
    let dir = vector.norm(vector.sub(pts.at(-1), pts.at(-2)))
    let pt = pts.at(-1)
    for m in end {
      drawables.push(drawable.mark(
        vector.sub(pt, dir), pt, m, marks))
      pt = vector.sub(pt, vector.scale(dir, mark-mid-length(m, marks) + marks.sep))
    }
  }

  return (drawables, pts)
}

/// Place marks along a cubic bezier curve
///
/// - ctx (context): Context
/// - curve (array): Array of curve points (start, end, ctrl-1, ctrl-2)
/// - style (style): Curve style
/// - marks (style): Mark style
/// -> (drawables, curve) Tuple of drawables and adjusted curve points
#let place-marks-along-bezier(ctx, curve, style, marks) = {
  import "/src/bezier.typ"

  let samples = calc.min(2, calc.max(marks.position-samples, 1000))

  // Shorten curve by distance
  let shorten-curve(curve, distance, style) = {
    assert(style.shorten in ("LINEAR", "CURVED"),
      message: "Invalid cubic shorten style")
    let quick = style.shorten == "LINEAR"
    if quick {
      return bezier.cubic-shorten-linear(..curve, distance)
    } else {
      return bezier.cubic-shorten(..curve, distance)
    }
  }

  let start = if type(marks.start) == str {
    (marks.start,)
  } else {
    marks.start
  }

  // Offset start
  if start != none and start.len() > 0 {
    let off = calc-mark-offset(ctx, start.at(0), marks)
    curve = shorten-curve(curve, -off, style)
  }

  let end = if type(marks.end) == str {
    (marks.end,)
  } else {
    marks.end
  }

  // Offset end
  if end != none and end.len() > 0 {
    let off = calc-mark-offset(ctx, end.at(0), marks)
    curve = shorten-curve(curve, off, style)
  }

  let drawables = ()
  let flex = marks.flex

  // Draw start marks
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
        let t-base = bezier.cubic-t-for-distance(..curve, dist + mark-mid-length(m, marks),
          samples: samples)
        vector.sub(bezier.cubic-point(..curve, t-base), pt)
      } else {
        bezier.cubic-derivative(..curve, t)
      }
      drawables.push(drawable.mark(
        vector.add(pt, dir), pt, m, marks))

      dist += mark-mid-length(m, marks) + marks.sep
    }
  }

  // Draw end marks
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
        let t-base = bezier.cubic-t-for-distance(..curve, -dist - mark-mid-length(m, marks),
          samples: samples)
        vector.sub(pt, bezier.cubic-point(..curve, t-base))
      } else {
        bezier.cubic-derivative(..curve, t)
      }
      drawables.push(drawable.mark(
        vector.sub(pt, dir), pt, m, marks))

      dist += mark-mid-length(m, marks) + marks.sep
    }
  }

  return (drawables, curve)
}

/// Place marks along a catmull-rom curve
///
/// - ctx (context): Context
/// - pts (array): Array of curve points
/// - style (style): Curve style
/// - marks (style): Mark style
/// -> (drawables, curve) Tuple of drawables and adjusted curve points
#let place-marks-along-catmull(ctx, pts, style, marks) = {
  return (none, pts)
}
