#let typst-length = length
#import "bezier.typ"
#import "drawable.typ"
#import "vector.typ"
#import "util.typ"
#import "path-util.typ"

/// Prepare mark style by resolving all stroke-thickness relative
/// values to absolute ones.
///
/// -> dictionary
#let prepare-mark-style(ctx, style) = {
  let thickness = util.get-stroke(style.stroke).thickness
  if type(thickness) == length { thickness /= 1pt }

  let scale = style.scale
  if type(scale) == ratio { scale = thickness * scale / 100% }

  let width = style.width
  if type(width) == ratio { width = thickness * width / 100% }
  width *= scale

  let length = style.length
  if type(length) == ratio { length = thickness * length / 100% }
  length *= scale

  let inset = style.inset
  if type(inset) == ratio { inset = thickness * inset / 100% }
  inset *= scale

  let sep = style.sep
  if type(sep) == ratio { sep = thickness * sep / 100% }

  // Reset the scale to 1 because we pre-scaled all values
  style.scale = 1
  style.width = width
  style.length = length
  style.inset = inset
  style.sep = sep
  return style
}

/// Draw a triangle mark with optional inset
#let draw-triangle(dir, norm, tip, style, open: false) = {
  let w = vector.scale(norm, style.width / 2)
  let b = vector.sub(tip, vector.scale(dir, style.length))

  if open {
    (drawable.path(path-util.line-segment((vector.add(b, w), tip, vector.sub(b, w))),
       stroke: style.stroke, fill: none, close: false),)
  } else if style.inset == 0 {
    (drawable.path(path-util.line-segment((vector.add(b, w), tip, vector.sub(b, w))),
       stroke: style.stroke, fill: style.fill, close: true),)
  } else {
    let i = vector.add(b, vector.scale(dir, style.inset))
    (drawable.path(path-util.line-segment((vector.add(b, w), tip, vector.sub(b, w), i)),
       stroke: style.stroke, fill: style.fill, close: true),)
  }
}

/// Draw a diamond/rotated square
#let draw-diamond(dir, norm, tip, style) = {
  let w = vector.scale(norm, style.width / 2)
  let b = vector.sub(tip, vector.scale(dir, style.length))
  let m = vector.sub(tip, vector.scale(dir, style.length / 2))

  (drawable.path(path-util.line-segment((
     tip, vector.add(m, w), b, vector.sub(m, w))),
     stroke: style.stroke, fill: style.fill, close: true),)
}

// Draw a barbed/math arrow
#let draw-barbed(dir, norm, tip, style) = {
  let w = vector.scale(norm, style.width / 2)
  let b = vector.sub(tip, vector.scale(dir, style.length))

  (drawable.path(
     (path-util.cubic-segment(vector.add(b, w), tip, vector.add(b, w), b),
      path-util.cubic-segment(tip, vector.sub(b, w), b, vector.sub(b, w))),
     stroke: style.stroke, fill: none, close: false),)
}

/// Draw a bar
#let draw-bar(dir, norm, tip, style) = {
  let w = vector.scale(norm, style.width / 2)

  (drawable.path(
     path-util.line-segment((vector.add(tip, w), vector.sub(tip, w))),
     stroke: style.stroke, close: false),)
}

/// Draw a bracket with
#let draw-bracket(dir, norm, tip, style) = {
  let w = vector.scale(norm, style.width / 2)
  let b = vector.sub(tip, vector.scale(dir, style.length))

  (drawable.path(
     path-util.line-segment((vector.add(b, w),
                             vector.add(tip, w),
                             vector.sub(tip, w),
                             vector.sub(b, w))),
     stroke: style.stroke, close: false),)
}

/// Draw a star with n lines
#let draw-star(dir, norm, tip, style, n: 5, angle-offset: 0deg) = {
  return range(0, n).map(i => {
    let a = i * 360deg / n + angle-offset
    let d = vector.scale(vector.rotate-z(norm, a), style.width / 2)

    drawable.path(path-util.line-segment((tip, vector.add(tip, d))),
      stroke: style.stroke, close: false)
  })
}

/// Draw a circle
#let draw-circle(dir, norm, tip, style) = {
  let o = vector.sub(tip, vector.scale(dir, style.width / 2))

  (drawable.ellipse(..o, style.width / 2, style.width / 2,
     stroke: style.stroke, fill: style.fill),)
}

/// Draw a rect
#let draw-rect(dir, norm, tip, style) = {
  let w = vector.scale(norm, style.width / 2)
  let b = vector.sub(tip, vector.scale(dir, style.length))

  (drawable.path(path-util.line-segment((
    vector.add(b, w), vector.add(tip, w),
    vector.sub(tip, w), vector.sub(b, w))),
    stroke: style.stroke, fill: style.fill, close: true),)
}

/// Draw a round hook
#let draw-hook(dir, norm, tip, style) = {
  let w = vector.scale(norm, style.width / 2)
  let b = vector.sub(tip, vector.scale(dir, style.width / 2))

  (drawable.path(path-util.cubic-segment(
    b, vector.add(b, w), tip, vector.add(tip, w)),
    stroke: style.stroke, fill: none, close: false),)
}

// Calculate offset for a triangular mark (triangle, harpoon, ..)
#let _triangular-mark-offset(ctx, mark-width, mark-length, symbol, style) = {
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
      return -miter
    } else {
      // If the miter limit kicks in, use bevel calculation
      join = "bevel"
    }
  }

  if join == "bevel" {
    return -calc.sin(angle / 2) * width / 2
  } else {
    return width / -2
  }
}

/// Public list of all predefined mark symbols
#let mark-symbols = (
  ">", "<", "->", "<-", "~>", "<~", "|", "[", "]", "o", "<>", "[]", "*", "+", "x", "hook", "hook-right",
)

/// Returns a tuple of a draw-function and a mark offset
#let get-mark(ctx, symbol, index, style) = {
  let thickness = util.get-stroke(style.stroke).thickness / 2
  if type(thickness) == length { thickness /= ctx.length }

  assert(type(symbol) in (str, dictionary),
    message: "Invalid mark symbol type: " + type(symbol))
  let mark = if symbol in (">", "<") {(
    draw: draw-triangle,
    offset: _triangular-mark-offset(ctx, style.width, style.length, symbol, style),
    length: style.length - style.inset,
    reverse: symbol == "<"
  )} else if symbol in ("->", "<-") {(
    draw: draw-triangle.with(open: true),
    offset: _triangular-mark-offset(ctx, style.width, style.length, symbol, style),
    gap: style.length,
    reverse: symbol == "<-"
  )} else if symbol in ("~>", "<~") {(
    draw: draw-barbed,
    offset: _triangular-mark-offset(ctx, 0, style.length, symbol, style),
    gap: style.length,
    reverse: symbol == "<~"
  )} else if symbol == "|" {(
    draw: draw-bar,
  )} else if symbol in ("]", "[") {(
    draw: draw-bracket,
    gap: style.length,
    offset: -thickness,
    reverse: symbol == "["
  )} else if symbol == "[]" {(
    draw: draw-rect,
    length: style.length,
    offset: -thickness,
  )} else if symbol == "<>" {(
    draw: draw-diamond,
    offset: _triangular-mark-offset(ctx, style.width, style.length / 2, symbol, style),
    length: style.length
  )} else if symbol == "o" {(
    draw: draw-circle,
    length: style.width,
    offset: -thickness,
  )} else if symbol == "*" {(
    draw: draw-star,
    gap: style.length
  )} else if symbol == "+" {(
    draw: draw-star.with(n: 4),
    gap: style.length
  )} else if symbol == "x" {(
    draw: draw-star.with(n: 4, angle-offset: 45deg),
    gap: style.length
  )} else if symbol in ("hook", "hook-right") {(
    draw: draw-hook,
    offset: thickness,
    length: style.width / 2,
    flip: symbol == "hook-right"
  )} else if type(symbol) == dictionary {
    assert("draw" in symbol and type(symbol.draw) == function,
      message: "Mark dictionary must contain 'draw' function: " + repr(symbol))
    symbol
  } else {
    panic("Invalid mark symbol: " + symbol)
  }

  mark.reverse = mark.at("reverse", default: false)
  mark.reverse = mark.reverse != style.reverse
  let dir-factor = if mark.reverse { -1 } else { 1 }
  mark.offset = dir-factor * mark.at("offset", default: 0)
  mark.flip = mark.at("flip", default: false)
  mark.flip = mark.flip != style.flip
  let norm-factor = if mark.flip { -1 } else { 1 }

  if dir-factor != 1 or norm-factor != 1 {
    mark.draw = (dir, norm, tip, style) => {
      let dir = vector.scale(dir, dir-factor)
      let norm = vector.scale(norm, dir-factor * norm-factor)
      (mark.draw)(dir, norm, tip, style)
    }
  }

  return mark
}

#let prepare-start-end(ctx, style) = {
  let start = if type(style.start) == str {
    (style.start,)
  } else if style.start == none {
    ()
  } else {
    style.start
  }.enumerate().map(((i, sym)) => get-mark(ctx, sym, i, style))

  let end = if type(style.end) == str {
    (style.end,)
  } else if style.end == none {
    ()
  } else {
    style.end
  }.enumerate().map(((i, sym)) => get-mark(ctx, sym, i, style))

  return (start, end)
}

// Calculate norm mark direction between two points
#let calc-dir(from, to, style) = {
  let dir = vector.sub(to, from)
  if dir == (0,0,0) {
    dir = (1,0,0)
  } else {
    dir = vector.norm(dir)
  }

  return dir
}

#let calc-normal(dir, style) = {
  let norm = (-dir.at(1), dir.at(0), dir.at(2))

  // 3D support
  if norm.at(2) != 0 {
    norm = vector.norm(vector.cross(norm, style.z-up))
  }

  // Slanting
  if style.slant != none and style.slant != 0deg {
    norm = vector.rotate-z(norm, style.slant)
  }

  return norm
}

/// Place marks along line of points
///
/// - ctx (context): Context
/// - pts (array): Array of vectors
/// - style (style): Mark style dictionary
/// -> (drawables, pts) Tuple of drawables and adjusted line points
#let place-marks-along-line(ctx, pts, style) = {
  let style = prepare-mark-style(ctx, style)
  let (start, end) = prepare-start-end(ctx, style)

  // Offset start
  let start-pt = pts.at(0)
  if start.len() > 0 {
    let mark = start.at(0)
    let offset = mark.at("offset", default: 0)

    let dir = vector.sub(pts.at(0), pts.at(1))
    if vector.len(dir) != 0 {
      let dir = vector.norm(dir)
      start-pt = vector.add(start-pt, vector.scale(dir, offset))
    }
  }

  // Offset end
  let end-pt = pts.at(-1)
  if end.len() > 0 {
    let mark = end.at(0)
    let offset = mark.at("offset", default: 0)

    let dir = vector.sub(pts.at(-2), pts.at(-1))
    if vector.len(dir) != 0 {
      let dir = vector.norm(dir)
      end-pt = vector.sub(end-pt, vector.scale(dir, offset))
    }
  }

  let drawables = ()

  // Draw start marks
  if start != none {
    let dir = calc-dir(pts.at(1), pts.at(0), style)
    let norm = calc-normal(dir, style)

    let pt = start-pt
    for (i, m) in start.enumerate() {
      let tip = pt
      drawables += (m.draw)(dir, norm, tip, style)

      let off = vector.scale(dir, m.at("length", default: 0))
      pt = vector.sub(pt, off)

      if style.shorten-to == auto or style.shorten-to == i {
         pts.at(0) = if m.reverse { tip } else { pt }
      }

      let gap = vector.scale(dir, m.at("gap", default: 0) + style.sep)
      pt = vector.sub(pt, gap)
    }
  }

  // Draw end marks
  if end != none {
    let dir = calc-dir(pts.at(-2), pts.at(-1), style)
    let norm = calc-normal(dir, style)

    let pt = end-pt
    for (i, m) in end.enumerate() {
      let tip = pt
      drawables += (m.draw)(dir, norm, tip, style)

      let off = vector.scale(dir, m.at("length", default: 0))
      pt = vector.sub(pt, off)

      if style.shorten-to == auto or style.shorten-to == i {
        pts.at(-1) = if m.reverse { tip } else { pt }
      }

      let gap = vector.scale(dir, m.at("gap", default: 0) + style.sep)
      pt = vector.sub(pt, gap)
    }
  }

  return (drawables, pts)
}

// Shorten curve by distance
#let _shorten-curve(curve, distance, target-pt, style, start: true) = {
  assert(style.shorten in ("LINEAR", "CURVED"),
    message: "Invalid cubic shorten style")
  let quick = style.shorten == "LINEAR"
  curve = if quick {
    if target-pt == none {
      bezier.cubic-shorten-linear(..curve, distance)
    } else {
      curve
    }
  } else {
    bezier.cubic-shorten(..curve, distance)
  }

  // Snap curve to point
  if target-pt != none {
    if start {
      curve.at(0) = target-pt
    } else {
      curve.at(1) = target-pt
    }
  }

  return curve
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
  let mark-style = prepare-mark-style(ctx, mark-style)
  let (start, end) = prepare-start-end(ctx, mark-style)

  // Offset start
  if start.len() > 0 {
    let mark = start.at(0)
    let offset = mark.at("offset", default: 0)
    let dir = bezier.cubic-derivative(..curve, 0)
    let opt = if vector.len(dir) != 0 {
      vector.sub(curve.at(0), vector.scale(vector.norm(dir), offset))
    }
    curve = _shorten-curve(curve, calc.max(0, -offset), opt, style, start: true)
  }

  // Offset end
  if end.len() > 0 {
    let mark = end.at(0)
    let offset = mark.at("offset", default: 0)
    let dir = bezier.cubic-derivative(..curve, 1)
    let opt = if vector.len(dir) != 0 {
      vector.add(curve.at(1), vector.scale(vector.norm(dir), offset))
    }
    curve = _shorten-curve(curve, calc.min(0, offset), opt, style, start: false)
  }

  let drawables = ()
  let flex = mark-style.flex

  let min-sample-length = 0.0001
  let shorten-start = 0; let pt-start = none
  let shorten-end = 0; let pt-end = none

  // Draw start mark-style
  if start != none {
    let dist = 0
    for (i, m) in start.enumerate() {
      let t = if dist > 0 {
        bezier.cubic-t-for-distance(..curve, dist, samples: samples)
      } else {
        0
      }

      let pt = bezier.cubic-point(..curve, t)
      let dir = if flex {
        let t-base = bezier.cubic-t-for-distance(..curve, dist + m.at("length", default: 0) + min-sample-length,
          samples: samples)
        vector.sub(pt, bezier.cubic-point(..curve, t-base))
      } else {
        vector.scale(bezier.cubic-derivative(..curve, t), -1)
      }
      if vector.len(dir) == 0 {break} // TODO: Emit warning

      dir = vector.norm(dir)
      let norm = calc-normal(dir, mark-style)

      let tip = pt
      let old-dist = dist
      drawables += (m.draw)(dir, norm, tip, mark-style)
      dist += m.at("length", default: 0)

      if mark-style.shorten-to == auto or mark-style.shorten-to == i {
        shorten-start = if m.reverse {
          old-dist
        } else {
          dist
        }
        pt-start = if m.reverse {
          tip
        } else {
          vector.sub(pt, vector.scale(dir, m.at("length", default: 0)))
        }
      }

      dist += m.at("gap", default: 0) + mark-style.sep
    }
  }

  // Draw end mark-style
  if end != none {
    let dist = 0
    for (i, m) in end.enumerate() {
      let t = if dist > 0 {
        bezier.cubic-t-for-distance(..curve, -dist, samples: samples)
      } else {
        1
      }

      let pt = bezier.cubic-point(..curve, t)
      let dir = if flex {
        let t-base = bezier.cubic-t-for-distance(..curve, -dist - m.at("length", default: 0) - min-sample-length,
          samples: samples)
        vector.sub(pt, bezier.cubic-point(..curve, t-base))
      } else {
        bezier.cubic-derivative(..curve, t)
      }
      if vector.len(dir) == 0 {break} // TODO: Emit warning

      dir = vector.norm(dir)
      let norm = calc-normal(dir, mark-style)

      let tip = pt
      let old-dist = dist
      drawables += (m.draw)(dir, norm, tip, mark-style)
      dist += m.at("length", default: 0)

      if mark-style.shorten-to == auto or mark-style.shorten-to == i {
        shorten-end = if m.reverse {
          old-dist
        } else {
          dist
        }
        pt-end = if m.reverse {
          tip
        } else {
          vector.sub(pt, vector.scale(dir, m.at("length", default: 0)))
        }
      }

      if m.reverse {
        dist += m.at("length", default: 0)
      }

      dist += m.at("gap", default: 0) + mark-style.sep
    }
  }

  curve = _shorten-curve(curve, calc.max(0, shorten-start), pt-start, style, start: true)
  curve = _shorten-curve(curve, calc.min(0, -shorten-end), pt-end, style, start: false)

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

  let (start, end) = prepare-start-end(ctx, mark-style)

  // Offset start
  if start.len() > 0 {
    let mark = start.at(0)
    let off = mark.at("offset", default: 0)

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

  // Offset end
  if end.len() > 0 {
    let mark = end.at(0)
    let off = mark.at("offset", default: 0)

    let r = r-at(stop-angle)
    stop-angle += (off * 360deg) / (2 * calc.pi * r)
  }

  let arc-center = vector.sub(arc-start, (calc.cos(start-angle) * rx,
                                          calc.sin(start-angle) * ry))
  let pt-at(angle) = vector.add(arc-center,
    (calc.cos(angle) * rx, calc.sin(angle) * ry, 0))

  let orig-start = start-angle
  let drawables = ()

  // Draw start marks
  let angle = start-angle
  for (i, m) in start.enumerate() {
    let length = calc.max(m.at("length", default: 0), 0.0001)
    let r = r-at(angle)
    let angle-offset = (length * 360deg) / (2 * calc.pi * r)

    let pt = pt-at(angle)

    let dir = vector.norm(vector.sub(pt, pt-at(angle + angle-offset)))
    let norm = calc-normal(dir, mark-style)

    let old-angle = angle
    drawables += (m.draw)(dir, norm, pt, mark-style)

    if mark-style.shorten-to == auto or mark-style.shorten-to == i {
      start-angle = if m.reverse {
        old-angle
      } else {
        angle + angle-offset
      }
    }

    let angle-offset = ((length + m.at("gap", default: 0) + mark-style.sep) * 360deg) / (2 * calc.pi * r)
    angle += angle-offset
  }

  // Reposition the arc
  if orig-start != start-angle {
    let diff = vector.sub((calc.cos(start-angle) * rx, calc.sin(start-angle) * ry),
                          (calc.cos(orig-start) * rx, calc.sin(orig-start) * ry))
    arc-start = vector.add(arc-start, diff)
  }

  // Draw end marks
  let angle = stop-angle
  for (i, m) in end.enumerate() {
    let length = calc.max(m.at("length", default: 0), 0.0001)
    let r = r-at(angle)

    let angle-offset = (length * 360deg) / (2 * calc.pi * r)

    let pt = pt-at(angle)

    let dir = vector.norm(vector.sub(pt, pt-at(angle - angle-offset)))
    let norm = calc-normal(dir, mark-style)

    let old-angle = angle
    drawables += (m.draw)(dir, norm, pt, mark-style)

    if mark-style.shorten-to == auto or mark-style.shorten-to == i {
      stop-angle = if m.reverse {
        old-angle
      } else {
        angle - angle-offset
      }
    }

    let angle-offset = ((length + m.at("gap", default: 0) + mark-style.sep) * 360deg) / (2 * calc.pi * r)
    angle -= angle-offset
  }

  return (drawables, arc-start, start-angle, stop-angle)
}

#let place-marks-along-path(ctx, style, segments) = {
  
}