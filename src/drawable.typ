#import "path-util.typ"
#import "vector.typ"
#import "util.typ"

#let apply-transform(transform, drawables) = {
  if type(drawables) == dictionary {
    drawables = (drawables,)
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

#let mark(from, to, symbol, size, fill: none, stroke: none) = {
  assert(symbol in (">", "<", "|", "<>", "o"), message: "Unknown arrow head: " + symbol)
  let n = vector.scale(vector.norm(vector.sub(to, from)), size)
  let from = vector.sub(to, n)
  let dir = vector.sub(to, from)
  let odir = (-dir.at(1), dir.at(0), dir.at(2))

  if symbol == "<" {
    let tmp = to
    to = from
    from = tmp
  }

  let triangle(reverse: false) = {
    let outset = if reverse { 1 } else { 0 }
    let from = vector.add(from, vector.scale(dir, outset))
    let to = vector.add(to, vector.scale(dir, outset))
    let n = vector.scale(odir, .4)

    if fill != none {
      // Draw a filled triangle
      path(
        path-util.line-segment(
          (from, vector.add(from, n), to, vector.add(from, vector.neg(n)))
        ),
        close: true,
        fill: fill,
        stroke: stroke
      )
    } else {
      // Draw open arrow
      path(
        path-util.line-segment(
          (vector.add(from, n), to, vector.add(from, vector.neg(n)))
        ),
        fill: fill,
        stroke: stroke
      )
    }
  }

  let bar() = {
      let n = vector.scale(odir, .5)
      path(
        path-util.line-segment((vector.add(to, n), vector.sub(to, n))),
        stroke: stroke
      )
  }

  let diamond() = {
      let from = vector.add(from, vector.scale(dir, .5))
      let to = vector.add(to, vector.scale(dir, .5))
      let n = vector.add(vector.scale(dir, .5),
                         vector.scale(odir, .5))
      path(
        path-util.line-segment(
          (from, vector.add(from, n), to, vector.add(to, vector.neg(n)))
        ),
        close: true,
        fill: fill,
        stroke: stroke
      )
  }

  let circle() = {
    let from = vector.add(from, vector.scale(dir, .5))
    let to = vector.add(to, vector.scale(dir, .5))
    let c = vector.add(from, vector.scale(dir, .5))
    let pts = ()
    let r = vector.len(dir) / 2

    ellipse(c.at(0), c.at(1), c.at(2), r, r, fill: fill, stroke: stroke)
  }

  if symbol == ">" {
    triangle()
  } else if symbol == "<" {
    triangle(reverse: true)
  } else if symbol == "|" {
    bar()
  } else if symbol == "<>" {
    diamond()
  } else if symbol == "o" {
    circle()
  }
}
