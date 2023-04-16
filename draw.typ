#import "vector.typ"
#import "matrix.typ"

#let typst-rotate = rotate

#let fill(color) = ((
  (apply: ctx => {
    ctx.fill = color
    return ctx
  })
),)

#let stroke(color) = ((
  (apply: ctx => {
    ctx.stroke = color
    return ctx
  })
),)

#let move-to(pt) = ((
  (apply: ctx => {
    let pt = (ctx.pos-to-pt)(pt)
    ctx.prev.pt = pt
    ctx.prev.bounds = (l: pt, r: pt, t: pt, b: pt)
    return ctx
  })
),)

// Rotate on z-axis (defaul) or specified axes if `angle` is of type
// dictionary
#let rotate(angle) = ((
  (apply: ctx => {
    if type(angle) == "dictionary" {
      for (key, value) in angle {
        ctx.transform-stack.last().insert("rotate-"+key,
          if key == "x" {
            matrix.transform-rotate-x(value)
          } else if key == "y" {
            matrix.transform-rotate-y(value)
          } else if key == "z" {
            matrix.transform-rotate-z(value)
          } else {
            panic("Invalid rotation axis")
          }
        )
      }
    } else {
      ctx.transform-stack.last().rotate = matrix.transform-rotate-z(angle)
    }

    return ctx
  })
),)

#let anchor(name, pos) = ((
  (positions: ctx => {
    (pos,)
  },
  anchors: (ctx, pos) => {
    let d = (:)
    d.insert(name, pos)
    return d
  },
  render: (ctx, pos) => {()})
),)

#let node(name, ..body) = ((
  (apply: ctx => {
    ctx.anchors = (:)
    ctx.transform-stack.push(ctx.transform-stack.last())
    return ctx
  },
  children: ctx => {
    body.pos()
  },
  finalize: (ctx, anchors) => {
    let _ = ctx.transform-stack.pop()
    ctx.nodes.insert(name, (
      anchor: anchors,
      bounds: ctx.prev.bounds,
      pt: ctx.prev.pt
    ))
    return ctx
  })
),)

// TODO: Replace me if this feature has native support
#let parse-stroke-color(paint) = {
  if type(paint) == "color" {
    return paint
  } else if type(paint) == "stroke" {
    // OUCH!
    return rgb(repr(paint).slice(repr(paint).position("#"), -2))
  } 
}

#let path-cmd(ctx, ..pts, cycle: false, fill: auto) = {
  if fill == auto { fill = ctx.fill }
  ((cmd: "line", pos: (..pts.pos()),
    stroke: ctx.stroke, fill: fill, close: cycle),)
}

#let rect-cmd(ctx, a, b) = {
  let (x1, y1, z1, ..) = a
  let (x2, y2, z2, ..) = b
  path-cmd(ctx, (x1, y1, z1), (x2, y1, z2),
                (x2, y2, z2), (x1, y2, z1), cycle: true)
}

#let arrow-head-cmd(ctx, from, to, symbol) = {
  if symbol == "<" {
    let tmp = to
    to = from
    from = tmp
    symbol = ">"
  }

  if symbol == ">" {
    let s = vector.sub(to, from)
    let n = (-s.at(1) / 3, s.at(0) / 3, from.at(2))
    path-cmd(ctx, from, vector.add(from, n), to,
             vector.add(from, vector.neg(n)),
             cycle: true, fill: parse-stroke-color(ctx.stroke))
  } else if symbol == "|" {
    let s = vector.sub(to, from)
    let n = (-s.at(1) / 3, s.at(0) / 3, to.at(2))
    path-cmd(ctx, vector.add(to, n),
             vector.add(to, vector.neg(n)),
             cycle: false)
  } else {
    panic("Unknown arrow head: " + symbol)
  }
}

#let arrow-head(from, to, symbol: ">") = ((
  (
    positions: ctx => {
      (from, to)
    },
    render: (ctx, from, to) => {
      arrow-head-cmd(ctx, from, to, symbol)
    }
  )
),)

#let line(..pts, cycle: false, mark-begin: none, mark-end: none) = ((
  (
    positions: ctx => {
      pts.pos()
    },
    anchors: (ctx, ..pts) => {
      (start: pts.pos().at(0),
       end: pts.pos().at(-1),
       default: pts.pos().at(-1))
    },
    render: (ctx, ..pts) => {
      path-cmd(ctx, ..pts.pos())

      if pts.pos().len() >= 2 {
        if mark-begin != none {
          let a = pts.pos().at(0)
          let b = pts.pos().at(1)
          let n = vector.mul(vector.norm(vector.sub(a, b)), ctx.mark-size)
          arrow-head-cmd(ctx, vector.sub(a, n), a, mark-begin)
        }

      if mark-end != none {
        let c = pts.pos().at(-2)
        let d = pts.pos().at(-1)
        let n = vector.mul(vector.norm(vector.sub(d, c)), ctx.mark-size)
        arrow-head-cmd(ctx, vector.sub(d, n), d, mark-end)
      }
    }
  },
  )
),)

#let rect(a, b) = ((
  (
    positions: ctx => {
      (a, b, vector.add(a, vector.div(vector.sub(b, a), 2)))
    },
    anchors: (ctx, a, b, center) => {
      let r = (
        center: center,
      )
      return r
    },
    render: (ctx, a, b, center) => {
      rect-cmd(ctx, a, b)
    },
  )
),)

#let circle(center, radius: 1,
            samples: auto,
            start: 0deg,
            end: 360deg,
            cycle: false) = ((
  (
    positions: ctx => {
      (center, (radius, 0, 0),)
    },
    anchors: (ctx, center, radius) => {
      (center: center,
       default: center)
    },
    render: (ctx, center, radius) => {
      let samples = samples
      if samples == auto {
        samples = int((end - start) / 1deg)
      }
      let radius = radius.at(0)
      let (x, y, ..) = center
      center.at(0) = x - radius
      center.at(1) = y + radius

      let l = (x - radius, y)
      let r = (x + radius, y)
      let t = (x, y - radius)
      let b = (x, y + radius)

      let pts = ()
      for i in range(0, samples + 1) {
        let angle = start + (end - start) * (i / samples)
        pts.push((x + calc.cos(angle) * radius,
                  y + calc.sin(angle) * radius,
                  center.at(2)))
      }

      path-cmd(ctx, ..pts, cycle: cycle)
    }
  )
),)

// Render content
// NOTE: Content itself is not transformed by the canvas transformations!
//       native transformation matrix support from typst would be required.
#let content(pt, ct, position: auto,
             angle: 0deg,
             handle-x: .5, handle-y: .5) = ((
  (positions: ctx => {
    (pt,)
  },
  render: (ctx, pt) => {
    let handle-x = handle-x
    let handle-y = handle-y
    let (x, y, z) = vector.as-vec(pt, init: (0, 0, 0))

    if position == "bellow" { handle-y = 0 }
    if position == "above"  { handle-y = 1 }
    if position == "left"   { handle-x = 1 }
    if position == "right"  { handle-x = 0 }
    if position == "on"     { handle-x = .5; handle-y = .5 }    

    let bounds = measure(ct, ctx.style)
    let tw = bounds.width / ctx.length
    let th = bounds.height / ctx.length
    let w = (calc.abs(calc.sin(angle) * th) + calc.abs(calc.cos(angle) * tw))
    let h = (calc.abs(calc.cos(angle) * th) + calc.abs(calc.sin(angle) * tw))
    x -= w * handle-x
    y -= h * handle-y

    let tl = (x, y, z, 1)
    let tr = (x + w, y, z, 1)
    let bl = (x, y - h, z, 1)
    let br = (x + w, y - h, z, 1)
    
    ((cmd: "content", pos: (pt,), content:
      move(dx: -bounds.width/2 + w/2*ctx.length - w * ctx.length * handle-x,
           dy: -bounds.height/2 + h/2*ctx.length - h * ctx.length * handle-y,
           typst-rotate(angle, ct)), bounds: (tl, tr, bl, br)), )
    }
  )
),)
