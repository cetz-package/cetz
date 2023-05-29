#import "matrix.typ"
#import "vector.typ"

#let typst-path = path

#let content(ctx, x, y, w, h, c) = {
  ((
    type: "content",
    coordinates: ((x,y),),
    bounds: (
      (x + w/2, y - h/2),
      (x - w/2, y + h/2)
    ),
    draw: (self) => {
      let (x, y) = self.coordinates.first()
      place(
        dx: x, dy: y, 
        c
      )
    },
  ),)
}

#let path(ctx, close: false, fill: auto, stroke: auto, ctrl: 0,
          ..vertices) = {
  ((
    type: "path",
    fill: if fill == auto { ctx.fill } else { fill },
    stroke: if stroke == auto { ctx.stroke } else { stroke },
    close: close,
    ctrl: ctrl,
    coordinates: vertices.pos(),
    draw: (self) => {
      let pts = ()
      let relative = (orig, c) => {
        return vector.sub(c, orig)
      }
      if self.ctrl == 0 {
        pts = self.coordinates
      } else if self.ctrl == 1 {
        for i in range(0, int(self.coordinates.len() / 2)) {
          i *= 2
          let pt = self.coordinates.at(i)
          pts.push((pt, relative(pt, self.coordinates.at(i + 1))))
        }
      } else if self.ctrl == 2 {
        for i in range(0, int(self.coordinates.len() / 3)) {
          i *= 3
          let pt = self.coordinates.at(i)
          pts.push((pt,
                    relative(pt, self.coordinates.at(i + 1)),
                    relative(pt, self.coordinates.at(i + 2))))
        }
      }

      place(
        typst-path(
          stroke: self.stroke, 
          fill: self.fill,
          closed: self.close, 
          ..pts
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
  path(ctx, close: true, ctrl: 2, fill: fill, stroke: stroke,
       (x, top, z), (x - m * rx, top, z), (x + m * rx, top, z),
       (right, y, z), (right, y + m * ry, z), (right, y - m * ry, z),
       (x, bottom, z), (x + m * rx, bottom, z), (x - m * rx, bottom, z),
       (left, y, z), (left, y - m * ry, z), (left, y + m * ry, z),)
}

#let arc(ctx, x, y, z, start, stop, radius, mode: "OPEN", fill: auto, stroke: auto) = {
  let samples = int((stop - start) / 1deg)
  path(ctx,
    fill: fill, stroke: stroke,
    close: mode == "CLOSE",
    ..range(0, samples+1).map(i => {
      let angle = start + (stop - start) * i / samples
      (
        x - radius*calc.cos(start) + radius*calc.cos(angle),
        y - radius*calc.sin(start) + radius*calc.sin(angle),
        z
      )
    }) + if mode == "PIE" {
      ((x - radius*calc.cos(start), y - radius*calc.sin(start), z),)
    } else {
      ()
    }
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
      (from, (vector.add(from, n)), to, (vector.add(from, vector.neg(n))))
  }

  let bar() = {
      let n = vector.scale(odir, .5)
      (vector.add(to, n), vector.sub(to, n))
  }

  let diamond() = {
      let from = vector.add(from, vector.scale(dir, .5))
      let to = vector.add(to, vector.scale(dir, .5))
      let n = vector.add(vector.scale(dir, .5),
                         vector.scale(odir, .5))
      (from, (vector.add(from, n)), to, (vector.add(to, vector.neg(n))))
  }

  let circle() = {
      let from = vector.add(from, vector.scale(dir, .5))
      let to = vector.add(to, vector.scale(dir, .5))
      let c = vector.add(from, vector.scale(dir, .5))
      let pts = ()
      let r = vector.len(dir) / 2
      for a in range(0, 360, step: 20) {
          pts.push((c.at(0) + calc.cos(a * 1deg) * r,
                    c.at(1) + calc.sin(a * 1deg) * r,
                    c.at(2)))
      }
      return pts
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

