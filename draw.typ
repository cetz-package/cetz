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

// Move to coordinate `pt`
// @param pt coordinate
#let move-to(pt) = ((
   coordinates: (pt, ),
   render: (ctx, pt) => (),
),)

// Rotate on z-axis (default) or specified axes if `angle` is of type
// dictionary
#let rotate(angle) = {
  ((
    before: ctx => {
      if type(angle) == "dictionary" {
        let (x, y, z) = (0deg, 0deg, 0deg)
        if "x" in angle { x = angle.x }
        if "y" in angle { y = angle.y }
        if "z" in angle { z = angle.z }
        ctx.transform.do.push(matrix.transform-rotate-xyz(x, y, z))
        ctx.transform.undo.push(matrix.transform-rotate-xyz(-x, -y, -z))
      } else {
        ctx.transform.do.push(matrix.transform-rotate-z(angle))
        ctx.transform.undo.push(matrix.transform-rotate-z(angle))
      }
      return ctx
    }
  ),)
}

// Scale canvas
// @param factor float
#let scale(f) = ((
  before: ctx => {
    ctx.transform.do.push(matrix.transform-scale(f))
    ctx.transform.undo.push(matrix.transform-scale(1/f))
    return ctx
  }
),)

// Translate
#let translate(vec) = {
  ((
    before: ctx => {
      let (x,y,z) = util.resolve-coordinate(ctx, vec)
      ctx.transform.do.push(matrix.transform-translate(x, y, z))
      ctx.transform.undo.push(matrix.transform-translate(-x, -y, -z))
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
  coordinates: (from, to),
  render: (ctx, from, to) => {
    arrow-head-cmd(ctx, from, to, symbol)
  }
),)

#let line(..pts, close: false,
          mark-begin: none,
          mark-end: none,
          mark-size: auto,
          name: none) = {
  ((
    name: name,
    coordinates: pts.pos(),
    custom-anchors: (..pts) => {
      (
        start: pts.pos().first(),
        end: pts.pos().last(),
      )
    },
    render: (ctx, ..pts) => {
      cmd.path(ctx, close: close, ..pts)

      let mark-size = if mark-size != auto {mark-size} else {ctx.mark-size}
      if mark-begin != none {
        let (start, end) = (pts.pos().at(1), pts.pos().at(0))
        let n = vector.scale(vector.norm(vector.sub(end, start)),
                             mark-size)
        start = vector.sub(end, n)
        cmd.arrow-head(ctx, start, end, mark-begin)
      }
      if mark-end != none {
        let (start, end) = (pts.pos().at(-2), pts.pos().at(-1))
        let n = vector.scale(vector.norm(vector.sub(end, start)),
                             mark-size)
        start = vector.sub(end, n)
        cmd.arrow-head(ctx, start, end, mark-end)
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
      let (x1, y1, z1) = a
      let (x2, y2, z2) = b
      cmd.path(ctx, close: true, (x1, y1, z1), (x2, y1, z2), (x2, y2, z2), (x1, y2, z1))
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
      let (x, y, z) = position
      (
        start: position,
        end: (
          x + radius*calc.sin(stop),
          y + radius*calc.cos(stop),
          z,
        ),
        origin: (
          x + radius*calc.sin(start),
          y + radius*calc.cos(start),
          z,
        )
      )
    },
    render: (ctx, position) => {
      let (x, y, z) = position
      cmd.arc(ctx, x, y, z, start, stop, radius, mode: mode)
    }
  ),)
}

#let circle(center, radius: 1, name: none, anchor: none) = {
  ((
    name: name,
    coordinates: (center, ),
    default-anchor: "center",
    anchor: anchor,
    render: (ctx, center) => {
      let (x, y, z) = center
      cmd.arc(ctx, x, y + radius, z, 0deg, 360deg, radius, mode: "CLOSE")
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
      let (x, y, ..) = pt

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

#let bezier(start, end, ..ctrl, samples: 100, name: none) = {
  let len = ctrl.pos().len()
  assert(len >= 1 and len <= 2,
         message: "Bezier curve expects 1 or 2 control points. Got " + str(len))
  return ((
    name: name,
    coordinates: (start, end, ..ctrl.pos()),
    custom-anchors: (start, end, ..ctrl) => {
      let a = (start: start, end: end)
      for (i, c) in ctrl.pos().enumerate() {
        a.insert("ctrl-" + str(i), c)
      }
      return a
    },
    render: (ctx, start, end, ..ctrl) => {
      ctrl = ctrl.pos()
      let f = if len == 1 {
        t => util.bezier-quadratic-pt(start, end, ctrl.first(), t)
      } else {
        t => util.bezier-cubic-pt(start, end, ctrl.first(), ctrl.last(), t)
      }
      cmd.path(
        ctx,
        ..(
          start,
          ..range(1, samples).map(i => f(i/samples)),
          end
        )
      )
    }
  ),)
}

// Merge multiple paths
#let merge-path(body, close: false) = ((
  children: body,
  finalize-children: (ctx, children) => {
    let merged = ()
    for child in children {
      merged += child.coordinates
    }
    return cmd.path(ctx, ..merged, close: close)
  }
),)

// Render shadow of children by rendering them twice
#let shadow(color: gray, offset-x: .1, offset-y: -.1, body) = ((
  children: (
    ..group({
      fill(color); stroke(color)
      translate((offset-x, offset-y, 0))
      body
    }),
    ..body,
  ),
),)
