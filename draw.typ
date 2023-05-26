#import "vector.typ"
#import "matrix.typ"
#import "cmd.typ"
#import "util.typ"
#import "coordinate.typ"
// #import "collisions.typ"

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
#let move-to(pt) = {
  let t = coordinate.resolve-system(pt)
  ((
    coordinates: (pt, ),
    render: (ctx, pt) => (),
  ),)
}

// Rotate on z-axis (default) or specified axes if `angle` is of type
// dictionary
#let rotate(angle) = {
  ((
    before: ctx => {
      let angle = angle
      if type(angle) == "array" {
        if type(angle.first()) == "function" {
          angle = coordinate.resolve(ctx, angle)
        }
      }
      if type(angle) == "angle" {
        ctx.transform.do.push(matrix.transform-rotate-z(angle))
        ctx.transform.undo.push(matrix.transform-rotate-z(-angle))
      } else if type(angle) == "dictionary" {
        let (x, y, z) = (0deg, 0deg, 0deg)
        if "x" in angle { x = angle.x }
        if "y" in angle { y = angle.y }
        if "z" in angle { z = angle.z }
        ctx.transform.do.push(matrix.transform-rotate-xyz(x, y, z))
        ctx.transform.undo.push(matrix.transform-rotate-xyz(-x, -y, -z))
      } else {
        panic("Invalid angle format '" + repr(angle) + "'")
      }
      return ctx
    }
  ),)
}

// Scale canvas
// @param factor float
#let scale(f) = ((
  before: ctx => {
    let inv = if type(f) == "dictionary" {
      (x: 1/f.x, y: 1/f.y, z: 1/f.z)
    } else {
      1/f
    }
    ctx.transform.do.push(matrix.transform-scale(f))
    ctx.transform.undo.push(matrix.transform-scale(inv))
    return ctx
  }
),)

// Translate
#let translate(vec) = {
  ((
    before: ctx => {
      let (x,y,z) = coordinate.resolve(ctx, vec)
      ctx.transform.do.push(matrix.transform-translate(x, -y, z))
      ctx.transform.undo.push(matrix.transform-translate(-x, y, -z))
      return ctx
    }
  ),)
}

// Register anchor `name` at position.
#let anchor(name, position) = {
  let t = coordinate.resolve-system(position)
  ((
    name: name,
    coordinates: (position,),
    custom-anchors: (position) => (default: position),
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
      let nodes = ctx.nodes
      ctx = self.ctx
      // panic(self)
      if name != none {
        ctx.nodes.insert(name, nodes.at(name))
      }
      return ctx
    }
  ),)
}

#let arrow-head(from, to, symbol: ">") = {
  let t = (from, to).map(coordinate.resolve-system)
  ((
    coordinates: (from, to),
    render: (ctx, from, to) => {
      cmd.arrow-head(ctx, from, to, symbol)
    }
  ),)
}

#let line(..pts, close: false,
          mark-begin: none,
          mark-end: none,
          mark-size: auto,
          name: none) = {
  let t = pts.pos().map(coordinate.resolve-system)
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

#let rect(a, b, name: none, anchor: none) = {
  let t = (a, b).map(coordinate.resolve-system)
  ((
    name: name,
    default-anchor: "center",
    anchor: anchor,
    coordinates: (a, b),
    render: (ctx, a, b) => {
      let (x1, y1, z1) = a
      let (x2, y2, z2) = b
      cmd.path(ctx, close: true, (x1, y1, z1), (x2, y1, z2), (x2, y2, z2), (x1, y2, z1))
    },
  ),)
}

#let arc(position, start, stop, radius: 1, mode: "OPEN", name: none, anchor: none) = {
  let t = coordinate.resolve-system(position)
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
          x - radius*calc.cos(start) + radius*calc.cos(stop),
          y - radius*calc.sin(start) + radius*calc.sin(stop),
          z,
        ),
        origin: (
          x - radius*calc.cos(start),
          y - radius*calc.sin(start),
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

// Render ellipse
// @param center  Center coordinate
// @param radius  Radius or array of x and y radius
#let circle(center, radius: 1, name: none, anchor: none) = {
  let t = coordinate.resolve-system(center)
  ((
    name: name,
    coordinates: (center, ),
    anchor: anchor,
    render: (ctx, center) => {
      let (x, y, z) = center
      let (rx, ry) = if type(radius) == "array" {radius} else {(radius, radius)}.map(util.resolve-number.with(ctx))
      cmd.ellipse(ctx, x, y, z, rx, ry)
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
  ) = {
  let t = coordinate.resolve-system(pt)
  ((
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
  assert(len in (1, 2), message: "Bezier curve expects 1 or 2 control points. Got " + str(len))
  let coordinates = (start, end, ..ctrl.pos())
  let t = coordinates.map(coordinate.resolve-system)
  return ((
    name: name,
    coordinates: coordinates,
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
    let pos = none
    while children.len() > 0 {
      let child = children.remove(0)
      assert(child.ctrl == 0, message: "FIXME: Bezier paths can not be merged!")

      // Revert path order, if end < start
      if merged.len() > 0 {
        if (vector.len(vector.sub(child.coordinates.last(), pos)) <
            vector.len(vector.sub(child.coordinates.first(), pos))) {
           child.coordinates = child.coordinates.rev()
        }
      }

      // Append child
      merged += child.coordinates

      // Sort next children by distance
      pos = merged.last()
      children = children.sorted(key: a => {
        calc.min(
          vector.len(vector.sub(a.coordinates.first(), pos)),
          vector.len(vector.sub(a.coordinates.last(), pos))
        )
      })
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

// Calculate the intersections of two named paths
// #let intersections(path-1, path-2, name: "intersection") = {
//   ((
//     name: name,
//     custom-anchors-ctx: (ctx) => {
//       let (ps1, ps2) = (path-1, path-2).map(x => ctx.nodes.at(x).paths)
//       let anchors = (:)
//       for p1 in ps1 {
//         for p2 in ps2 {
//           let cs = collisions.poly-poly(p1, p2)
//           if cs != none {
//             for c in cs {
//               anchors.insert(str(anchors.len()+1), util.revert-transform(ctx.transform, c))
//             }
//           }
//         }
//       }
//       anchors
//     },
//   ),)
// }

#let grid(from, to, step: 1, name: none, help-lines: false) = {
  let t = (from, to).map(coordinate.resolve-system)
  ((
    name: name,
    coordinates: (from, to),
    render: (ctx, from, to) => {
      let stroke = if help-lines {
        0.2pt + gray
      } else {
        auto
      }
      let (x-step, y-step) = if type(step) == "dictionary" {
        (
          if "x" in step {step.x} else {1},
          if "y" in step {step.y} else {1},
        )
      } else {
        (step, step)
      }.map(util.resolve-number.with(ctx))

      if x-step != 0 {
        for x in range(int((to.at(0) - from.at(0)) / x-step)+1) {
          x *= x-step
          x += from.at(0)
          cmd.path(ctx, (x, from.at(1)), (x, to.at(1)), stroke: stroke)
        }
      }

      if y-step != 0 {
        for y in range(int((to.at(1) - from.at(1)) / y-step)+1) {
          y *= y-step
          y += from.at(1)
          cmd.path(ctx, (from.at(0), y), (to.at(0), y), stroke: stroke)
        }
      }
    }
  ),)
}