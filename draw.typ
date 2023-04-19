#import "vector.typ"
#import "matrix.typ"
#import "cmd.typ"

#let typst-rotate = rotate

#let fill(color) = {
  ((
    modify-ctx: ctx => {
      ctx.fill = color
      return ctx
    }
  ),)
}

#let stroke(color) = {
  ((
    modify-ctx: ctx => {
      ctx.stroke = color
      return ctx
    }
  ),)
}

#let move-to(pt) = {
  ((
    modify-ctx: ctx => {
      let pt = (ctx.pos-to-pt)(pt)
      ctx.prev.pt = pt
      ctx.prev.bounds = (l: pt, r: pt, t: pt, b: pt)
      return ctx
    }
  ),)
}

// Rotate on z-axis (defaul) or specified axes if `angle` is of type
// dictionary
#let rotate(angle) = {
  ((
    modify-ctx: ctx => {
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
    }
  ),)
}

// Translate
#let translate(x, y, z) = ((
  (modify-ctx: ctx => {
    ctx.transform-stack.last().translate = matrix.transform-translate(x,y,z)
    return ctx
  })
),)

// Register anchor `name` at position `pos`.
#let anchor(name, pos) = ((
(
  name: name,
  positions: ctx => {
    (pos,)
  },
  anchors: (ctx, pos) => {
    (default: pos)
  },
  render: (ctx, pos) => {()})
),)

// Group
#let group(..body) = ((
(
  modify-ctx: ctx => {
    ctx.transform-stack.push(ctx.transform-stack.last())
    return ctx
  },
  children: ctx => {
    let (old-fill, old-stroke) = (ctx.fill, ctx.stroke)
    (..body.pos(), fill(old-fill), stroke(old-stroke))
  },
  finalize: (ctx) => {
    let _ = ctx.transform-stack.pop()
    return ctx
  }
)
),)

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

#let line(start, end, cycle: false, mark-begin: none, mark-end: none, name: none) = {
  ((
    name: name,
    coordinates: (
      start, end
    ),
    custom-anchors: (start, end) => {
      (
        start: start,
        end: end,
      )
    },
    render: (ctx, start, end) => {
      cmd.path(ctx, start, end)
      if mark-begin != none or mark-end != none {
        let n = vector.mul(vector.norm(vector.sub(start, end)), ctx.mark-size)
        if mark-begin != none {
          cmd.arrow-head(ctx, start, vector.sub(start, n), mark-begin)
        }
        if mark-end != none {
          cmd.arrow-head(ctx, end, vector.sub(end, n), mark-end)
        }
      }

    }
  ),)
}

#let rect(a, b, name: none) = ((
  (
    name: name,
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
      let (x1, y1) = a
      let (x2, y2) = b
      path-cmd(ctx, (x1, y1), (x2, y1), (x2, y2), (x1, y2), cycle: true)
    },
  )
),)

// #let pt-on-circle(center, x-rad, y-rad, start, end, i) = {
//   let (x, y) = center
//   let angle = start + (end - start) * i
//   (
//     x + calc.cos(angle) * x-rad,
//     y + calc.sin(angle) * y-rad
//   )
// }

#let arc(position, start, stop, radius: 1, name: none, anchor: none) = {
  ((
    name: name,
    anchor: anchor,
    default-anchor: "start",
    coordinates: (position,),
    custom-anchors: (position) => {
      let (x,y) = position
      (
        start: position,
        end: (
          x - radius*calc.sin(start) + radius*calc.sin(stop),
          y - radius*calc.cos(start) + radius*calc.cos(stop),
        ),
        origin: (
          x - radius*calc.sin(start),
          y - radius*calc.cos(start),
        )
      )
    },
    render: (ctx, position) => {
      cmd.arc(ctx, position.first(), position.last(), start, stop, radius)
    }
  ),)
}

#let circle(center, radius: 1, name: none, anchor: none) = {
  ((
    name: name,
    coordinates: (center,),
    default-anchor: "center",
    anchor: anchor,
    // anchors: (ctx, center) => {
    //   let radius = radius.at(0)
    //   (center: center,
    //    start: pt-on-circle(center, radius, radius, start, end, 0),
    //    end: pt-on-circle(center, radius, radius, start, end, 1),
    //    default: center)
    // },
    render: (ctx, center) => {
      cmd.arc(ctx, center.first(), center.last()+radius, 0deg, 360deg, radius, close: true)
    }
  ),)
}

// Render content
// NOTE: Content itself is not transformed by the canvas transformations!
//       native transformation matrix support from typst would be required.
#let content(
  pt,
  ct,
  angle: 0deg,
  anchor: none,
  name: none
  ) = {(
  (
    name: name,
    coordinates: (pt,),
    anchor: anchor,
    default-anchor: "center",
    render: (ctx, pt) => {
      let (x, y) = pt

      let size = measure(ct, ctx.style)
      let tw = size.width / ctx.length
      let th = size.height / ctx.length
      let w = (calc.abs(calc.sin(angle) * th) + calc.abs(calc.cos(angle) * tw))
      let h = (calc.abs(calc.cos(angle) * th) + calc.abs(calc.sin(angle) * tw))

      // x += w/2
      // y -= h/2
      cmd.content(
        ctx,
        x,
        y,
        w,
        h,
        move(
          dx: -tw/2 * ctx.length,
          dy: -th/2 * ctx.length,
          typst-rotate(angle, ct)
        )
      )
    }
  ),)
}

// Merge multiple paths
#let merge-path(..body, cycle: false) = ((
  (
    children: ctx => {
      body.pos()
    },
    finalize-children: (ctx, children) => {
      let merged = none
      for child in children {
        assert(child.cmd == "path")
        if merged == none {
          merged = child
        } else {
          merged.vertices += child.vertices
        }
      }
      merged.close = cycle
      merged.fill = ctx.fill
      merged.stroke = ctx.stroke
      return (merged,)
    }
  )
),)

// Render shadow of children by rendering them twice
#let shadow(color: gray, offset-x: .1, offset-y: .1, ..body) = ((
(
  children: ctx => {
    (
      group(
        // FIXME: only modify stroke color!
        fill(color), stroke(color),
        translate(offset-x, offset-y, 0),
        ..body.pos(),
      ),
      translate(0, 0, 0),
      ..body.pos()
    )
  },
)
),)
