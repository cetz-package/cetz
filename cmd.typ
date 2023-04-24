#import "matrix.typ"
#import "vector.typ"

#let typst-path = path

#let content(ctx, x, y, w, h, c) = ((
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

#let path(ctx, close: false, fill: auto, stroke: auto, ..vertices) = {
  if fill == auto { fill = ctx.fill }
  if stroke == auto { stroke = ctx.stroke }
  ((
    fill: if fill == auto { ctx.fill } else { fill },
    stroke: if stroke == auto { ctx.stroke } else { stroke },
    close: close,
    coordinates: vertices.pos(),
    draw: (self) => {
      place(
        typst-path(
          stroke: self.stroke, 
          fill: self.fill,
          closed: self.close, 
          ..self.coordinates
          )
        )
    },
  ),)
}

#let arc(ctx, x, y, z, start, stop, radius, mode: "OPEN") = {
  let samples = int((stop - start) / 1deg)
  path(ctx,
    close: mode == "CLOSE",
    ..range(0, samples+1).map(i => {
      let angle = start + (stop - start) * i / samples
      (
        x - radius*calc.sin(start) + radius*calc.sin(angle),
        y - radius*calc.cos(start) + radius*calc.cos(angle),
        z
      )
    }) + if mode == "PIE" {
      ((x - radius*calc.sin(start), y - radius*calc.cos(start), z),)
    } else {
      ()
    }
  )
}

#let arrow-head(ctx, from, to, symbol) = {
  let dir = vector.sub(to, from)
  let odir = (-dir.at(1), dir.at(0), dir.at(2))

  if symbol == "<" {
    let tmp = to
    to = from
    from = tmp
    symbol = ">"
  }

  let triangle() = {
      let n = vector.scale(odir, .4)
      (from, (vector.add(from, n)), to, (vector.add(from, vector.neg(n))))
  }

  let bar() = {
      let n = vector.scale(odir, .5)
      (vector.add(to, n), vector.sub(to, n))
  }

  let diamond() = {
      let n = vector.add(vector.scale(dir, .5),
                         vector.scale(odir, .5))
      (from, (vector.add(from, n)), to, (vector.add(to, vector.neg(n))))
  }

  let circle() = {
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

  if symbol == ">" {
    path(ctx, ..triangle(), close: true, fill: ctx.fill)
  } else if symbol == "|" {
    path(ctx, ..bar())
  } else if symbol == "<>" {
    path(ctx, ..diamond(), close: true, fill: ctx.fill)
  } else if symbol == "o" {
    path(ctx, ..circle(), close: true, fill: ctx.fill)
  } else {
    panic("Unknown arrow head: " + symbol)
  }
}

