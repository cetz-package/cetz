#import "vector.typ"
#import "matrix.typ"
#import "cmd.typ"
#import "util.typ"

#let typst-rotate = rotate

#let fill(color) = {
  ((
    before: ctx => {
      ctx.fill = color
      return ctx
    }
  ),)
}

#let stroke(color) = {
  ((
    before: ctx => {
      ctx.stroke = color
      return ctx
    }
  ),)
}

#let move-to(pt) = {
  ((
    before: ctx => {
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
    before: ctx => {
      if type(angle) == "dictionary" {
        for (key, value) in angle {
          ctx.transform.insert("rotate-"+key,
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
        ctx.transform.rotate = matrix.transform-rotate-z(angle)
      }

      return ctx
    }
  ),)
}

// Translate
#let translate(vec) = {
  ((
    before: ctx => {
      let (x,y) = util.abs-coordinate(ctx, vec)
      // assert(vec != "and.out", message: repr((x,y)))
      if "translate" in ctx.transform {
        let t = ctx.transform.translate
        ctx.transform.translate = matrix.transform-translate(x + t.at(0).at(3), y + t.at(1).at(3), 0)
      } else {
        ctx.transform.translate = matrix.transform-translate(x,y,0)
      }
      return ctx
    }
  ),)
}

// Register anchor `name` at position.
#let anchor(name, position) = {
  ((
    name: name,
    coordinates: (position,),
    after: (ctx, position) => {
      assert(ctx.groups.len() > 0, message: "Anchor '" + name + "' created outside of group!")
      ctx.groups.last().anchors.insert(name, position)
      // panic(ctx.groups)
      return ctx
    }
  ),)
}

// Group
#let group(name: none, anchor: none, body) = {
  ((
    name: name,
    anchor: anchor,
    default-anchor: "center",
    before: ctx => {
      ctx.groups.push((
        ctx: ctx,
        anchors: (:),
      ))
      return ctx
    },
    children: body,
    custom-anchors-ctx: (ctx) => ctx.groups.last().anchors,
    after: (ctx) => {
      let self = ctx.groups.pop()
      let anchors = ctx.anchors
      ctx = self.ctx
      // panic(self)
      if name != none {
        ctx.anchors.insert(name, anchors.at(name))
      }
      return ctx
    }
  ),)
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

#let line(start, end, mark-begin: none, mark-end: none, name: none) = {
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

#let rect(a, b, name: none, anchor: none) = ((
  (
    name: name,
    default-anchor: "center",
    anchor: anchor,
    coordinates: (a, b),
    render: (ctx, a, b) => {
      let (x1, y1) = a
      let (x2, y2) = b
      cmd.path(ctx, (x1, y1), (x2, y1), (x2, y2), (x1, y2), close: true)
    },
  )
),)

#let arc(position, start, stop, radius: 1, mode: "OPEN", name: none, anchor: none) = {
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
      cmd.arc(ctx, position.first(), position.last(), start, stop, radius, mode: mode)
    }
  ),)
}

#let circle(center, radius: 1, name: none, anchor: none) = {
  ((
    name: name,
    coordinates: (center,),
    default-anchor: "center",
    anchor: anchor,
    render: (ctx, center) => {
      cmd.arc(ctx, center.first(), center.last()+radius, 0deg, 360deg, radius, mode: "CLOSE")
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
