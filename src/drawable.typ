#import "vector.typ"
#import "util.typ"
#import "path-util.typ"

#let apply-transform(transform, drawables) = {
  if type(drawables) == dictionary {
    drawables = (drawables,)
  }
  if drawables.len() == 0 {
    return ()
  }
  if transform == none {
    return drawables
  }
  for drawable in drawables {
    assert(type(drawable) != array,
      message: "Expected drawable, got array: " + repr(drawable))
    if drawable.type == "path" {
      drawable.segments = drawable.segments.map(((kind, ..pts)) => {
        return (kind,) + util.apply-transform(transform, ..pts)
      })
    } else if drawable.type == "content" {
      drawable.pos = util.apply-transform(transform, drawable.pos)
    } else {
      panic()
    }
    (drawable,)
  }
}

#let path(close: false, fill: none, stroke: none, segments) = {
  let segments = segments
  // Handle case where only one segment has been passed
  if type(segments.first()) == str {
    segments = (segments,)
  }

  segments = path-util.normalize(segments)
  if close and path-util.segment-end(segments.last()) != path-util.segment-start(segments.first()) {
    segments.push(path-util.line-segment((
      path-util.segment-end(segments.last()),
      path-util.segment-start(segments.first()),
    )))
  }

  return (
    type: "path",
    close: close,
    segments: segments,
    fill: fill,
    stroke: stroke,
    hidden: false,
    bounds: true,
  )
}

#let content(pos, width, height, border, body) = {
  return (
    type: "content",
    pos: pos,
    width: width,
    height: height,
    segments: border,
    body: body,
    hidden: false,
    bounds: true,
  )
}

#let ellipse(x, y, z, rx, ry, fill: none, stroke: none) = {
  let m = 0.551784
  let mx = m * rx
  let my = m * ry
  let left = x - rx
  let right = x + rx
  let top = y + ry
  let bottom = y - ry

  path(
    (
      path-util.cubic-segment(
        (x, top, z),
        (right, y, z),
        (x + m * rx, top, z),
        (right, y + m * ry, z),
      ),
      path-util.cubic-segment(
        (right, y, z),
        (x, bottom, z),
        (right, y - m * ry, z),
        (x + m * rx, bottom, z),
      ),
      path-util.cubic-segment(
        (x, bottom, z),
        (left, y, z),
        (x - m * rx, bottom, z),
        (left, y - m * ry, z),
      ),
      path-util.cubic-segment((left, y, z), (x, top, z), (left, y + m * ry, z), (x - m * rx, top, z)),
    ),
    stroke: stroke,
    fill: fill,
    close: true,
  )
}

#let arc(x, y, z, start, stop, rx, ry, mode: "OPEN", fill: none, stroke: none) = {
  let delta = calc.max(-360deg, calc.min(stop - start, 360deg))
  let num-curves = calc.max(1, calc.min(calc.ceil(calc.abs(delta) / 90deg), 4))

  // Move x/y to the center
  x -= rx * calc.cos(start)
  y -= ry * calc.sin(start)

  // Calculation of control points is based on the method described here:
  // https://pomax.github.io/bezierinfo/#circles_cubic
  let segments = ()
  for n in range(0, num-curves) {
    let start = start + delta / num-curves * n
    let stop = start + delta / num-curves

    let d = delta / num-curves
    let k = 4 / 3 * calc.tan(d / 4)

    let sx = x + rx * calc.cos(start)
    let sy = y + ry * calc.sin(start)
    let ex = x + rx * calc.cos(stop)
    let ey = y + ry * calc.sin(stop)

    let s = (sx, sy, z)
    let c1 = (
      x + rx * (calc.cos(start) - k * calc.sin(start)),
      y + ry * (calc.sin(start) + k * calc.cos(start)),
      z,
    )
    let c2 = (
      x + rx * (calc.cos(stop) + k * calc.sin(stop)),
      y + ry * (calc.sin(stop) - k * calc.cos(stop)),
      z,
    )
    let e = (ex, ey, z)

    segments.push(path-util.cubic-segment(s, e, c1, c2))
  }

  if mode == "PIE" and calc.abs(delta) < 360deg {
    segments.push(path-util.line-segment((
      path-util.segment-end(segments.last()),
      (x, y, z),
      path-util.segment-start(segments.first()))))
  }

  return path(
    fill: fill,
    stroke: stroke,
    close: mode != "OPEN",
    segments
  )
}
