#import "path-util.typ"
#import "vector.typ"
#import "util.typ"

#let apply-transform(transform, drawables) = {
  if type(drawables) == dictionary {
    drawables = (drawables,)
  }
  if drawables.len() == 0 {
    return ()
  }
  for drawable in drawables {
    if drawable.type == "path" {
      drawable.segments = drawable.segments.map(s => {
        return (s.at(0),) + util.apply-transform(transform, ..s.slice(1))
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
  if close {
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
    stroke: stroke
  )
}

#let content(pos, width, height, body) = {
  return (
    type: "content",
    pos: pos,
    width: width,
    height: height,
    body: body,
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
    segments.insert(0, path-util.line-segment(((x, y, z), segments.first().at(1))))
    segments.push(path-util.line-segment((segments.last().at(2), (x, y, z))))
  }
  // panic(segments)

  return path(
    fill: fill,
    stroke: stroke,
    close: mode != "OPEN",
    segments
  )
}

#let mark(from, to, symbol, style) = {
  let scaling  = style.at("scale", default: 1)
  let width    = calc.abs(style.at("width", default: .1) * scaling)
  let length   = calc.abs(style.at("length", default: .15) * scaling)
  let inset    = calc.min(style.at("inset", default: 0) * scaling, length)
  let stroke   = style.stroke
  let fill     = style.fill

  let reverse  = symbol == "<"
  let dir      = vector.norm(if reverse {
    vector.sub(from, to)
  } else {
    vector.sub(to, from)
  })
  let norm-dir = (-dir.at(1), dir.at(0), dir.at(2))

  // Generic positions
  //
  //    t      t - tip
  //   /|\
  //  / | \    base - root
  // '--m--'   m - base + inset
  //
  // ^--|--^   w - half width
  let t    = to
  let base = vector.sub(t, vector.scale(dir, length))
  let m    = vector.add(base, vector.scale(dir, inset))
  let w    = vector.scale(norm-dir, width / 2)

  let triangle() = {
    let a = vector.sub(base, w)
    let b = vector.add(base, w)

    if fill != none {
      // Draw a filled triangle
      path(
        path-util.line-segment((a, t, b, m)),
        close: true,
        fill: fill,
        stroke: stroke
      )
    } else {
      // Draw open arrow
      path(
        path-util.line-segment((a, t, b)),
        fill: fill,
        stroke: stroke
      )
    }
  }

  let harpoon(side: "left") = {
    let s = if side == "left" {
      vector.sub(base, w)
    } else {
      vector.add(base, w)
    }

    path(path-util.line-segment((t, s, m)),
      fill: fill,
      stroke: stroke,
      close: true)
  }

  let bar() = {
    let n = vector.scale(norm-dir, width / 2)
    path(
      path-util.line-segment((vector.add(t, n), vector.sub(t, n))),
      stroke: stroke
    )
  }

  let diamond() = {
    let mid = vector.add(t, vector.scale(vector.sub(base, t), .5))
    let a = vector.sub(mid, w)
    let b = vector.add(mid, w)

    path(
      path-util.line-segment((base, a, t, b)),
      close: true,
      fill: fill,
      stroke: stroke
    )
  }

  if symbol == ">" {
    triangle()
  } else if symbol == "<" {
    triangle()
  } else if symbol == "|" {
    bar()
  } else if symbol == "<>" {
    diamond()
  } else if symbol == "left-harpoon" {
    harpoon(side: "left")
  } else if symbol == "right-harpoon" {
    harpoon(side: "right")
  } else {
    panic("Invalid arrow head: " + symbol)
  }
}
