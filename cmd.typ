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

#let arrow-head(ctx, from, to, symbol) = {
  if symbol == "<" {
    let tmp = to
    to = from
    from = tmp
    symbol = ">"
  }

  if symbol == ">" {
    let s = vector.sub(to, from)
    let n = (-s.at(1) / 3, s.at(0) / 3)
    path(
      ctx, from, vector.add(from, n), to,
      vector.add(from, vector.neg(n)),
      cycle: true, 
      fill: ctx.fill
    )
  } else if symbol == "|" {
    let s = vector.sub(to, from)
    let n = (-s.at(1) / 3, s.at(0) / 3)
    path(
      ctx, 
      vector.add(to, n),
      vector.add(to, vector.neg(n)),
    )
  } else {
    panic("Unknown arrow head: " + symbol)
  }
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
      ((x - radius*calc.sin(start), y - radius*calc.cos(start)), z)
    } else {
      ()
    }
  )
}
