#import "matrix.typ"
#import "vector.typ"
#import "util.typ"
#import "bezier.typ"
#import "path-util.typ"

#let typst-path = path

#let content(x, y, w, h, c) = {
  ((
    type: "content",
    segments: (("pt", (x,y)),),
    bounds: (
      (x + w/2, y - h/2),
      (x - w/2, y + h/2)
    ),
    draw: (self) => {
      let (x, y) = self.segments.first().at(1)
      place(
        dx: x, dy: y, 
        c
      )
    },
  ),)
}

#let path(close: false, fill: none, stroke: none,
           ..segments) = {
  let segments = segments.pos()

  // Add a closing segment to make path calculations
  // consider it.
  if close {
    let (s0, sn) = (segments.first(), segments.last())
    segments.push(("line",
                   path-util.segment-end(sn),
                   path-util.segment-begin(s0)))
  }
  ((
    type: "path",
    close: close,
    segments: segments,
    draw: (self) => {
      let relative = (orig, c) => {
        return vector.sub(c, orig)
      }

      let vertices = ()
      for s in self.segments {
        let type = s.at(0)
        let coordinates = s.slice(1)
        
        assert(type in ("line", "cubic"),
               message: "Path segments must be of type line, cubic")
        
        if type == "cubic" {
          let a = coordinates.at(0)
          let b = coordinates.at(1)
          let ctrla = relative(a, coordinates.at(2))
          let ctrlb = relative(b, coordinates.at(3))

          vertices.push((a, (0em, 0em), ctrla))
          vertices.push((b, ctrlb, (0em, 0em)))
        } else {
          vertices += coordinates
        }
      }

      place(
        typst-path(
          stroke: stroke, 
          fill: fill,
          closed: self.close, 
          ..vertices
          )
        )
    },
  ),)
}

// Approximate ellipse using 4 quadratic bezier curves
#let ellipse(x, y, z, rx, ry, fill: none, stroke: none) = {
  let m = 0.551784
  let mx = m * rx
  let my = m * ry
  let left = x - rx
  let right = x + rx
  let top = y + ry
  let bottom = y - ry

  path(fill: fill, stroke: stroke,
       ("cubic", (x, top, z), (right, y, z),
                 (x + m * rx, top, z), (right, y + m * ry, z)),
       ("cubic", (right, y, z), (x, bottom, z),
                 (right, y - m * ry), (x + m * rx, bottom, z)),
       ("cubic", (x, bottom, z), (left, y, z),
                 (x - m * rx, bottom, z), (left, y - m * ry, z)),
       ("cubic", (left, y, z), (x, top, z),
                 (left, y + m * ry, z), (x - m * rx, top, z)))
}

// Draw an elliptical arc approximated by up to 4
// cubic bezier curves.
#let arc(x, y, z, start, stop, rx, ry, mode: "OPEN", fill: none, stroke: none) = {
  let delta = calc.max(-360deg, calc.min(stop - start, 360deg))
  if delta < 0deg {
    delta = 360deg + delta
  }

  let num-curves = calc.max(1, calc.min(calc.ceil(delta / 90deg), 4))

  let position = (x, y, z)

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
    let k = 4/3 * calc.tan(d / 4)

    let sx = x + rx * calc.cos(start)
    let sy = y + ry * calc.sin(start)
    let ex = x + rx * calc.cos(stop)
    let ey = y + ry * calc.sin(stop)

    let s = (sx, sy, z, 1)
    let c1 = (x + rx * (calc.cos(start) - k * calc.sin(start)),
              y + ry * (calc.sin(start) + k * calc.cos(start)), z, 1)
    let c2 = (x + rx * (calc.cos(stop) + k * calc.sin(stop)),
              y + ry * (calc.sin(stop) - k * calc.cos(stop)), z, 1)
    let e = (ex, ey, z, 1)

    segments.push(("cubic", s, e, c1, c2))
  }

  if mode == "PIE" and calc.abs(delta) < 360deg {
    segments.insert(0, ("line", (x, y, z), segments.first().at(1)))
    segments.push(("line", segments.last().at(2), (x, y, z)))
  }

  path(..segments, fill: fill, stroke: stroke, close: mode != "OPEN")
}

#let mark(from, to, symbol, fill: none, stroke: none) = {
  assert(symbol in (">", "<", "|", "<>", "o"), message: "Unknown arrow head: " + symbol)
  let dir = vector.sub(to, from)
  let odir = (-dir.at(1), dir.at(0), dir.at(2))

  if symbol == "<" {
    let tmp = to
    to = from
    from = tmp
  }

  let style = (
    fill: fill,
    stroke: stroke
  )

  let triangle(reverse: false) = {
      let outset = if reverse { 1 } else { 0 }
      let from = vector.add(from, vector.scale(dir, outset))
      let to = vector.add(to, vector.scale(dir, outset))
      let n = vector.scale(odir, .4)

      if fill != none {
        // Draw a filled triangle
        path(("line", from, (vector.add(from, n)),
                        to, (vector.add(from, vector.neg(n)))),
              close: true,
              ..style)
      } else {
        // Draw open arrow
        path(("line", (vector.add(from, n)), to,
                      (vector.add(from, vector.neg(n)))),
              close: false,
              ..style)
      }
  }

  let bar() = {
      let n = vector.scale(odir, .5)
      path(("line", vector.add(to, n), vector.sub(to, n)),
           ..style)
  }

  let diamond() = {
      let from = vector.add(from, vector.scale(dir, .5))
      let to = vector.add(to, vector.scale(dir, .5))
      let n = vector.add(vector.scale(dir, .5),
                         vector.scale(odir, .5))
      path(("line", from, (vector.add(from, n)),
                      to, (vector.add(to, vector.neg(n)))),
           close: true,
           ..style)
  }

  let circle() = {
    let from = vector.add(from, vector.scale(dir, .5))
    let to = vector.add(to, vector.scale(dir, .5))
    let c = vector.add(from, vector.scale(dir, .5))
    let pts = ()
    let r = vector.len(dir) / 2

    ellipse(c.at(0), c.at(1), c.at(2), r, r, ..style)
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

