#import "matrix.typ"
#import "vector.typ"
#import "util.typ"
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
    bounds: path-util.bounds(segments),
    draw: (self) => {
      let relative = (orig, c) => {
        return vector.sub(c, orig)
      }

      let vertices = ()
      for s in self.segments {
        let type = s.at(0)
        let coordinates = s.slice(1)
        
        assert(type in ("line", "quadratic", "cubic"),
               message: "Path segments must be of type line, quad or cube")
        
        if type == "quadratic" {
          // TODO: Typst path implementation does not support quadratic
          //       curves.
          // let a = coordinates.at(0)
          // let b = coordinates.at(1)
          // let ctrla = relative(a, coordinates.at(2))
          // let ctrlb = relative(b, coordinates.at(2))
          // vertices.push((a, (0em, 0em), ctrla))
          // vertices.push((b, (0em, 0em), (0em, 0em)))
          let a = coordinates.at(0)
          let b = coordinates.at(1)
          let c = coordinates.at(2)

          let samples = path-util.ctx-samples((:)) //(ctx)
          vertices.push(a)
          for i in range(0, samples) {
            vertices.push(util.bezier-quadratic-pt(a, b, c, i / samples))
          }
          vertices.push(b)
        } else if type == "cubic" {
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

#let arc(x, y, z, start, stop, rx, ry, mode: "OPEN", fill: none, stroke: none) = {
  let samples = calc.abs(int((stop - start) / 1deg))
  path(
    fill: fill, stroke: stroke,
    close: mode != "OPEN",
    ("line", ..range(0, samples+1).map(i => {
      let angle = start + (stop - start) * i / samples
      (
        x - rx*calc.cos(start) + rx*calc.cos(angle),
        y - ry*calc.sin(start) + ry*calc.sin(angle),
        z
      )
    }) + if mode == "PIE" {
      ((x - rx*calc.cos(start), y - ry*calc.sin(start), z),
       (x, y, z),)
    } else {
      ()
    })
  )
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

