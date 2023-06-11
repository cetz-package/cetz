#import "vector.typ"
#import "matrix.typ"
#import "cmd.typ"
#import "util.typ"
#import "path-util.typ"
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

#let content-padding(padding) = {
  ((
    before: ctx => {
        ctx.content-padding = padding
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
  let resolve-angle(angle) = {
    return if type(angle) == "angle" {
      matrix.transform-rotate-z(angle)
    } else if type(angle) == "dictionary" {
      matrix.transform-rotate-xyz(
          angle.at("x", default: 0deg),
          angle.at("y", default: 0deg),
          angle.at("z", default: 0deg),
        )
    } else {
      panic("Invalid angle format '" + repr(angle) + "'")
    }
  }
  return ((
    push-transform: if type(angle) == "array" and type(angle.first()) == "function" { 
      ctx => resolve-angle(coordinate.resolve-function(coordinate.resolve, ctx, angle))
    } else {
      resolve-angle(angle)
    }
  ),)
}

// Scale canvas
// @param factor float
#let scale(f) = ((
  push-transform: matrix.transform-scale(f)
),)

// Translate
#let translate(vec) = {
  let resolve-vec(vec) = {
    let (x,y,z) = if type(vec) == "dictionary" {
      (
        vec.at("x", default: 0),
        vec.at("y", default: 0),
        vec.at("z", default: 0),
      )
    } else if type(vec) == "array" {
      if vec.len() == 2 {
        vec + (0,)
      } else {
        vec
      }
    } else {
      panic("Invalid angle format '" + repr(vec) + "'")
    }
    return matrix.transform-translate(x, -y, z)
  }
  ((
    push-transform: if type(vec) == "array" and type(vec.first()) == "function" {
      ctx => resolve-vec(coordinate.resolve-function(coordinate.resolve, ctx, vec))
    } else {
      resolve-vec(vec)
    },
  ),)
}

// Sets the given position as the origin
#let set-origin(origin) = {
  return ((
    push-transform: ctx => {
      let (x,y,z) = vector.sub(util.apply-transform(ctx.transform, coordinate.resolve(ctx, origin)), util.apply-transform(ctx.transform, (0,0,0)))
      return matrix.transform-translate(x, y, z)
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
      ctx.groups.last().anchors.insert(name, ctx.nodes.at(name).anchors.default)
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
    custom-anchors-ctx: ctx => {
      let anchors = ctx.groups.last().anchors
      for (k,v) in anchors {
        anchors.insert(k, util.revert-transform(ctx.transform, v))
      }
      return anchors
    },
    after: (ctx) => {
      let self = ctx.groups.pop()
      let nodes = ctx.nodes
      ctx = self.ctx
      if name != none {
        ctx.nodes.insert(name, nodes.at(name))
      }
      return ctx
    }
  ),)
}

#let arrow-head(from, to, symbol: ">", fill: auto, stroke: auto) = {
  let t = (from, to).map(coordinate.resolve-system)
  ((
    coordinates: (from, to),
    render: (ctx, from, to) => {
      cmd.arrow-head(ctx, from, to, symbol, fill: fill, stroke: stroke)
    }
  ),)
}

#let line(..pts, close: false,
          name: none,
          fill: auto,
          stroke: auto,
          mark-begin: none,
          mark-end: none,
          mark-size: auto,
          mark-fill: auto,
          mark-stroke: auto
        ) = {
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
      cmd.path(ctx, close: close, ("line", ..pts.pos()),
               fill: fill, stroke: stroke)

      let mark-size = if mark-size != auto {mark-size} else {ctx.mark-size}
      if mark-begin != none {
        let (start, end) = (pts.pos().at(1), pts.pos().at(0))
        let n = vector.scale(vector.norm(vector.sub(end, start)),
                             mark-size)
        start = vector.sub(end, n)
        cmd.arrow-head(ctx, start, end, mark-begin, fill: mark-fill, stroke: mark-stroke)
      }
      if mark-end != none {
        let (start, end) = (pts.pos().at(-2), pts.pos().at(-1))
        let n = vector.scale(vector.norm(vector.sub(end, start)),
                             mark-size)
        start = vector.sub(end, n)
        cmd.arrow-head(ctx, start, end, mark-end, fill: mark-fill, stroke: mark-stroke)
      }
    }
  ),)
}

#let rect(a, b, name: none, anchor: none, fill: auto, stroke: auto) = {
  let t = (a, b).map(coordinate.resolve-system)
  ((
    name: name,
    default-anchor: "center",
    anchor: anchor,
    coordinates: (a, b),
    render: (ctx, a, b) => {
      let (x1, y1, z1) = a
      let (x2, y2, z2) = b
      cmd.path(ctx, close: true, fill: fill, stroke: stroke,
              ("line", (x1, y1, z1), (x2, y1, z2),
                       (x2, y2, z2), (x1, y2, z1)))
    },
  ),)
}

#let arc(position, start: auto, stop: auto, delta: auto, radius: 1, mode: "OPEN", name: none, anchor: none, fill: auto, stroke: auto) = {
  assert((start,stop,delta).filter(it=>{it == auto}).len() == 1, message: "Exactly two of three options start, stop and delta should be defined.")
  let t = coordinate.resolve-system(position)
  let start-angle = if start == auto {stop - delta} else {start}
  let stop-angle = if stop == auto {start + delta} else {stop}
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
          x - radius*calc.cos(start-angle) + radius*calc.cos(stop-angle),
          y - radius*calc.sin(start-angle) + radius*calc.sin(stop-angle),
          z,
        ),
        origin: (
          x - radius*calc.cos(start-angle),
          y - radius*calc.sin(start-angle),
          z,
        )
      )
    },
    render: (ctx, position) => {
      let (x, y, z) = position
      cmd.arc(ctx, x, y, z, start-angle, stop-angle, radius, mode: mode, fill: fill, stroke: stroke)
    }
  ),)
}

// Render ellipse
// @param center  Center coordinate
// @param radius  Radius or array of x and y radius
#let circle(center, radius: 1, name: none, anchor: none, fill: auto, stroke: auto) = {
  let t = coordinate.resolve-system(center)
  ((
    name: name,
    coordinates: (center, ),
    anchor: anchor,
    render: (ctx, center) => {
      let (x, y, z) = center
      let (rx, ry) = if type(radius) == "array" {radius} else {(radius, radius)}.map(util.resolve-number.with(ctx))
      cmd.ellipse(ctx, x, y, z, rx, ry, fill: fill, stroke: stroke)
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
  padding: auto,
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

      let padding = util.resolve-number(ctx, if padding == auto { ctx.content-padding } else { padding })
      let size = measure(ct, ctx.style)
      let tw = size.width / ctx.length 
      let th = size.height / ctx.length
      let w = (calc.abs(calc.sin(angle) * th) + calc.abs(calc.cos(angle) * tw)) + padding * 2
      let h = (calc.abs(calc.cos(angle) * th) + calc.abs(calc.sin(angle) * tw)) + padding * 2

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

#let bezier(start, end, ..ctrl, name: none, fill: auto, stroke: auto) = {
  let len = ctrl.pos().len()
  assert(len in (1, 2), message: "Bezier curve expects 1 or 2 control points. Got " + str(len))
  let coordinates = (start, end, ..ctrl.pos())
  let t = coordinates.map(coordinate.resolve-system)
  let f = if len == 1 {
    t => util.bezier-quadratic-pt(start, end, ctrl.pos().first(), t)
  } else {
    t => util.bezier-cubic-pt(start, end, ctrl.pos().first(), ctrl.pos().last(), t)
  }

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
      cmd.path(
        ctx,
        (if len == 1 { "quad" } else { "cube" }, start, end, ..ctrl),
        fill: fill, stroke: stroke
      )
    }
  ),)
}

/// Put marks on a path
///
/// - path (path): Path
/// - marks (array): Array of dictionaries of the format:
///                  (mark: string,
///                   pos: float,
///                   scale: float,
///                   stroke: stroke,
///                   fill: fill)
#let place-marks(path,
                 ..marks,
                 size: auto,
                 fill: auto,
                 stroke: auto) = {
((
  children: (path),
  finalize-children: (ctx, children) => {
    let size = if size != auto { size } else { ctx.mark-size }

    let p = children.first()
    (p,);

    for m in marks.pos() {
      let scale = m.at("scale", default: size)
      let fill = m.at("fill", default: fill)
      let stroke = m.at("stroke", default: stroke)

      let (pt, dir) = path-util.direction(p.segments, m.pos, scale: scale)
      if pt != none {
        cmd.arrow-head(
          ctx, vector.add(pt, dir), pt, m.mark, fill: fill, stroke: stroke)
      }
    }
  }
),)
}

/// Merge multiple paths
///
/// - body (any): Body
/// - close (bool): If true, the path is automatically closed
#let merge-path(body,
                close: false,
                fill: auto,
                stroke: auto) = ((
  children: body,
  finalize-children: (ctx, children) => {
    let segments = ()
    let pos = none

    let segment-begin = (s) => {
      return s.at(1)
    }

    let segment-end = (s) => {
      let type = s.at(0)
      if type == "line" {
        return s.last()
      } else {
        return s.at(2)
      }
    }

    let dist = (a, b) => {
      vector.len(vector.sub(a, b))
    }

    while children.len() > 0 {
      let child = children.remove(0)
      assert("segments" in child,
             message: "Object must contain path segments")
      if child.segments.len() == 0 { continue }

      // Revert path order, if end < start
      //if segments.len() > 0 {
      //  if (dist(segment-end(child.segments.last()), pos) <
      //      dist(segment-begin(child.segments.first()), pos)) {
      //     child.segments = child.segments.rev()
      //  }
      //}

      // Connect "jumps" with linear lines to prevent typsts path impl.
      // from using weird cubic ones.
      if segments.len() > 0 {
        let end = segment-end(segments.last())
        let begin = segment-begin(child.segments.first())
        if dist(end, begin) > 0 {
          segments.push(("line", segment-begin(child.segments.first())))
        }
      }

      // Append child
      segments += child.segments

      // Sort next children by distance
      pos = segment-end(segments.last())
      children = children.sorted(key: a => {
        return vector.len(vector.sub(segment-begin(a.segments.first()), pos))
      })
    }

    cmd.path(ctx, ..segments,
             close: close, stroke: stroke, fill: fill)
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

#let grid(from, to, step: 1, name: none, help-lines: false, fill: auto, stroke: auto) = {
  let t = (from, to).map(coordinate.resolve-system)
  ((
    name: name,
    coordinates: (from, to),
    render: (ctx, from, to) => {
      let stroke = if help-lines {
        0.2pt + gray
      } else {
        stroke
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
          cmd.path(ctx, (x, from.at(1)), (x, to.at(1)), fill: fill, stroke: stroke)
        }
      }

      if y-step != 0 {
        for y in range(int((to.at(1) - from.at(1)) / y-step)+1) {
          y *= y-step
          y += from.at(1)
          cmd.path(ctx, (from.at(0), y), (to.at(0), y), fill: fill, stroke: stroke)
        }
      }
    }
  ),)
}
