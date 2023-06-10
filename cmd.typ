#import "matrix.typ"
#import "vector.typ"
#import "util.typ"

#let typst-path = path

#let content(ctx, x, y, w, h, c) = {
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

// Calculate bounding points for a list of path segments
#let path-bounds(segments, samples: 25) = {
  let bounds = ()

  for s in segments {
    let type = s.at(0)
    if type == "line" {
      bounds += s.slice(1)
    } else if type == "quad" {
      let (a, b, c) = s.slice(1)
      bounds.push(a)
      bounds.push(b)
      bounds += range(1, samples).map(x =>
        util.bezier-quadratic-pt(a, b, c, x / samples))
    } else if type == "cube" {
      let (a, b, c, d) = s.slice(1)
      bounds.push(a)
      bounds.push(b)
      bounds += range(1, samples).map(x =>
        util.bezier-cubic-pt(a, b, c, d, x / samples))
    }
  }

  return bounds
}

#let path(ctx, close: false, fill: auto, stroke: auto,
           ..segments) = {
  ((
    type: "path",
    fill: if fill == auto { ctx.fill } else { fill },
    stroke: if stroke == auto { ctx.stroke } else { stroke },
    close: close,
    segments: segments.pos(),
    bounds: path-bounds(segments.pos()),
    draw: (self) => {
      let relative = (orig, c) => {
        return vector.sub(c, orig)
      }

      let vertices = ()
      for s in self.segments {
        let type = s.at(0)
        let coordinates = s.slice(1)
        
        assert(type in ("line", "quad", "cube"),
               message: "Path segments must be of type line, quad or cube")
        
        if type == "quad" {
          let a = coordinates.at(0)
          let b = coordinates.at(1)
          let ctrla = relative(a, coordinates.at(2))
          let ctrlb = relative(b, coordinates.at(2))

          vertices.push((a, (0em, 0em), ctrla))
          vertices.push((b, (0em, 0em), (0em, 0em)))
        } else if type == "cube" {
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
          stroke: self.stroke, 
          fill: self.fill,
          closed: self.close, 
          ..vertices
          )
        )
    },
  ),)
}

// Approximate ellipse using 4 quadratic bezier curves
#let ellipse(ctx, x, y, z, rx, ry, fill: auto, stroke: auto) = {
  let m = 0.551784
  let mx = m * rx
  let my = m * ry
  let left = x - rx
  let right = x + rx
  let top = y + ry
  let bottom = y - ry

  path(ctx, fill: fill, stroke: stroke,
       ("cube", (x, top, z), (right, y, z),
                (x + m * rx, top, z), (right, y + m * ry, z)),
       ("cube", (right, y, z), (x, bottom, z),
                (right, y - m * ry), (x + m * rx, bottom, z)),
       ("cube", (x, bottom, z), (left, y, z),
                (x - m * rx, bottom, z), (left, y - m * ry, z)),
       ("cube", (left, y, z), (x, top, z),
                (left, y + m * ry, z), (x - m * rx, top, z)))
}

#let arc(ctx, x, y, z, start, stop, radius, mode: "OPEN", fill: auto, stroke: auto) = {
  let samples = calc.abs(int((stop - start) / 1deg))
  path(ctx,
    fill: fill, stroke: stroke,
    close: mode != "OPEN",
    ("line", ..range(0, samples+1).map(i => {
      let angle = start + (stop - start) * i / samples
      (
        x - radius*calc.cos(start) + radius*calc.cos(angle),
        y - radius*calc.sin(start) + radius*calc.sin(angle),
        z
      )
    }) + if mode == "PIE" {
      ((x - radius*calc.cos(start), y - radius*calc.sin(start), z),
       (x, y, z),)
    } else {
      ()
    })
  )
}

#let arrow-head(ctx, from, to, symbol, fill: auto, stroke: auto) = {
  assert(symbol in (">", "<", "|", "<>", "o"), message: "Unknown arrow head: " + symbol)
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
      (("line", from, (vector.add(from, n)),
                to, (vector.add(from, vector.neg(n)))),)
  }

  let bar() = {
      let n = vector.scale(odir, .5)
      (("line", vector.add(to, n), vector.sub(to, n)),)
  }

  let diamond() = {
      let from = vector.add(from, vector.scale(dir, .5))
      let to = vector.add(to, vector.scale(dir, .5))
      let n = vector.add(vector.scale(dir, .5),
                         vector.scale(odir, .5))
      (("line", from, (vector.add(from, n)),
                to, (vector.add(to, vector.neg(n)))),)
  }

  let circle() = {
    let from = vector.add(from, vector.scale(dir, .5))
    let to = vector.add(to, vector.scale(dir, .5))
    let c = vector.add(from, vector.scale(dir, .5))
    let pts = ()
    let r = vector.len(dir) / 2

    return ellipse(ctx, c.at(0), c.at(1), c.at(2), r, r).first().segments
  }
  path(
    ctx,
    ..if symbol == ">" {
      triangle()
    } else if symbol == "<" {
      triangle(reverse: true)
    } else if symbol == "|" {
      bar()
    } else if symbol == "<>" {
      diamond()
    } else if symbol == "o" {
      circle()
    },
    close: symbol != "|",
    fill: fill,
    stroke: stroke,
  )
}

