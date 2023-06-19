#import "vector.typ"
#import "matrix.typ"
#import "cmd.typ"
#import "util.typ"
#import "path-util.typ"
#import "coordinate.typ"
// #import "collisions.typ"
#import "styles.typ"

#let typst-rotate = rotate

#let set-style(..style) = {
  assert.eq(style.pos().len(), 0, message: "set-style takes no positional arguments" )
  ((
    style: style.named()
  ),)
}

#let fill(fill) = {
  ((
    style: (fill: fill)
  ),)
}

#let stroke(stroke) = {
  ((
    style: (stroke: stroke)
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

#let line(..pts-style, close: false, name: none) = {

  // Extra positional arguments from the pts-style sink are interpreted as coordinates.
  let (pts, style) = (pts-style.pos(), pts-style.named())

  // Coordinate check
  let t = pts.map(coordinate.resolve-system)
  ((
    name: name,
    coordinates: pts,
    custom-anchors: (..pts) => {
      let pts = pts.pos()
      (
        start: pts.first(),
        end: pts.last(),
      )
    },
    render: (ctx, ..pts) => {
      let pts = pts.pos()
      let style = styles.resolve(ctx.style, style, root: "line")
      cmd.path(close: close, ("line", ..pts.pos()), fill: style.fill, stroke: style.stroke)

      if style.mark.start != none or style.mark.end != none {
        let style = style.mark
        if style.start != none {
          let (start, end) = (pts.at(1), pts.at(0))
          let n = vector.scale(vector.norm(vector.sub(end, start)),
                              style.size)
          start = vector.sub(end, n)
          cmd.arrow-head(start, end, style.start, fill: style.fill, stroke: style.stroke)  
        }
        if style.end != none {
          let (start, end) = (pts.at(-2), pts.at(-1))
          let n = vector.scale(vector.norm(vector.sub(end, start)), style.size)
          start = vector.sub(end, n)
          cmd.arrow-head(start, end, style.end, fill: style.fill, stroke: style.stroke)
        }
      }
    }
  ),)
}

#let rect(a, b, name: none, anchor: none, ..style) = {
  // Coordinate check
  let t = (a, b).map(coordinate.resolve-system)

  // No extra positional arguments from the style sink
  assert.eq(style.pos(), (), message: "Unexpected positional arguments: " + repr(style.pos()))
  let style = style.named()
  ((
    name: name,
    default-anchor: "center",
    anchor: anchor,
    coordinates: (a, b),
    render: (ctx, a, b) => {
      let style = styles.resolve(ctx.style, style, root: "rect")
      let (x1, y1, z1) = a
      let (x2, y2, z2) = b
      cmd.path(close: true, fill: style.fill, stroke: style.stroke,
              ("line", (x1, y1, z1), (x2, y1, z2),
                       (x2, y2, z2), (x1, y2, z1)))
    },
  ),)
}

#let arc(position, start: auto, stop: auto, delta: auto, name: none, anchor: none, ..style) = {
  // Start, stop, delta check
  assert((start,stop,delta).filter(it=>{it == auto}).len() == 1, message: "Exactly two of three options start, stop and delta should be defined.")

  // No extra positional arguments from the style sink
  assert.eq(style.pos(), (), message: "Unexpected positional arguments: " + repr(style.pos()))
  let style = style.named()

  // Coordinate check
  let t = coordinate.resolve-system(position)

  let start-angle = if start == auto {stop - delta} else {start}
  let stop-angle = if stop == auto {start + delta} else {stop}
  ((
    name: name,
    anchor: anchor,
    default-anchor: "start",
    coordinates: (position,),
    custom-anchors-ctx: (ctx, position) => {
      let style = styles.resolve(ctx.style, style, root: "arc")
      let (x, y, z) = position
      let (rx, ry) = util.resolve-radius(style.radius).map(util.resolve-number.with(ctx))
      (
        start: position,
        end: (
          x - rx*calc.cos(start-angle) + rx*calc.cos(stop-angle),
          y - ry*calc.sin(start-angle) + ry*calc.sin(stop-angle),
          z,
        ),
        origin: (
          x - rx*calc.cos(start-angle),
          y - ry*calc.sin(start-angle),
          z,
        )
      )
    },
    render: (ctx, position) => {
      let style = styles.resolve(ctx.style, style, root: "arc")
      let (x, y, z) = position
      let (rx, ry) = util.resolve-radius(style.radius).map(util.resolve-number.with(ctx))
      cmd.arc(x, y, z, start-angle, stop-angle, rx, ry, mode: style.mode, fill: style.fill, stroke: style.stroke)
    }
  ),)
}

// Render ellipse
#let circle(center, name: none, anchor: none, ..style) = {
  // No extra positional arguments from the style sink
  assert.eq(style.pos(), (), message: "Unexpected positional arguments: " + repr(style.pos()))
  let style = style.named()

  // Coordinate check
  let t = coordinate.resolve-system(center)
  ((
    name: name,
    coordinates: (center, ),
    anchor: anchor,
    render: (ctx, center) => {
      let style = styles.resolve(ctx.style, style, root: "circle")
      let (x, y, z) = center
      let (rx, ry) = util.resolve-radius(style.radius).map(util.resolve-number.with(ctx))
      cmd.ellipse(x, y, z, rx, ry, fill: style.fill, stroke: style.stroke)
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
  name: none,
  ..style
  ) = {
  // No extra positional arguments from the style sink
  assert.eq(style.pos(), (), message: "Unexpected positional arguments: " + repr(style.pos()))
  let style = style.named()

  // Coordinate check
  let t = coordinate.resolve-system(pt)
  ((
    name: name,
    coordinates: (pt,),
    anchor: anchor,
    default-anchor: "center",
    render: (ctx, pt) => {
      let (x, y, ..) = pt
      let style = styles.resolve(ctx.style, style, root: "content")
      let padding = util.resolve-number(ctx, style.padding)
      let size = measure(ct, ctx.typst-style)
      let tw = size.width / ctx.length 
      let th = size.height / ctx.length
      let w = (calc.abs(calc.sin(angle) * th) + calc.abs(calc.cos(angle) * tw)) + padding * 2
      let h = (calc.abs(calc.cos(angle) * th) + calc.abs(calc.sin(angle) * tw)) + padding * 2

      // x += w/2
      // y -= h/2
      cmd.content(
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

/// Draw a quadratic or cubic bezier line
///
/// - start (coordinate): Start point
/// - end (coordinate): End point
/// - ..ctrl (coordinate): Control points
#let bezier(start, end, ..ctrl-style, name: none) = {
  // Extra positional arguments are treated like control points.
  let (ctrl, style) = (ctrl-style.pos(), ctrl-style.named())

  // Control point check
  let len = ctrl.len()
  assert(len in (1, 2), message: "Bezier curve expects 1 or 2 control points. Got " + str(len))
  let coordinates = (start, end, ..ctrl)

  // Coordiantes check
  let t = coordinates.map(coordinate.resolve-system)
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
      let style = styles.resolve(ctx.style, style, root: "bezier")
      ctrl = ctrl.pos()
      cmd.path(
        (if len == 1 { "quadratic" } else { "cubic" }, start, end, ..ctrl),
        fill: style.fill, stroke: style.stroke
      )
    }
  ),)
}

/// NOTE: This function is supposed to be REPLACED by a
///       new coordinate syntax!
///
/// Create anchors along a path
///
/// - path (path): Path
/// - anchors (positional): Dictionaries of the format:
///     (name: string, pos: float)
/// - name (string): Element name, uses paths name, if auto
#let place-anchors(path, ..anchors, name: auto) = {
  let name = if name == auto and "name" in path.first() {
    path.first().name
  } else {
    name
  }
  assert(type(name) == "string", message: "Name must be of type string")

  ((
    name: name,
    children: path,
    custom-anchors-drawables: (drawables) => {
      if drawables.len() == 0 { return () }

      let out = (:)
      let s = drawables.first().segments
      for a in anchors.pos() {
        assert("name" in a, message: "Anchor must have a name set")
        out.insert(a.name, path-util.point-on-path(s, a.pos))
      }
      return out
    },
  ),)
}

/// NOTE: This function is supposed to be removed!
///
/// Put marks on a path
///
/// - path (path): Path
/// - marks (positional): Array of dictionaries of the format:
///     (mark: string,
///      pos: float,
///      scale: float,
///      stroke: stroke,
///      fill: fill)
#let place-marks(path,
                 ..marks,
                 size: auto,
                 fill: auto,
                 stroke: auto,
                 name: none) = {
((
  name: name,
  children: path,
  custom-anchors-drawables: (drawables) => {
    if drawables.len() == 0 { return () }

    let anchors = (:)
    let s = drawables.first().segments
    for m in marks.pos() {
      if "name" in m {
        anchors.insert(m.name, path-util.point-on-path(s, m.pos))
      }
    }
    return anchors
  },
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
/// - name (string): Element name
#let merge-path(body, close: false, name: none, ..style) = {
  // No extra positional arguments from the style sink
  assert.eq(style.pos(), (), message: "Unexpected positional arguments: " + repr(style.pos()))
  let style = style.named()
  ((
    name: name,
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

      while children.len() > 0 {
        
        let child = children.remove(0)
        assert("segments" in child,
                message: "Object must contain path segments")
        if child.segments.len() == 0 { continue }

        // Revert path order, if end < start
        //if segments.len() > 0 {
        //  if (vector.dist(segment-end(child.segments.last()), pos) <
        //      vector.dist(segment-begin(child.segments.first()), pos)) {
        //     child.segments = child.segments.rev()
        //  }
        //}

        // Connect "jumps" with linear lines to prevent typsts path impl.
        // from using weird cubic ones.
        if segments.len() > 0 {
          let end = segment-end(segments.last())
          let begin = segment-begin(child.segments.first())
          if vector.dist(end, begin) > 0 {
            segments.push(("line", segment-begin(child.segments.first())))
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

        // Append child
        segments += child.segments

        // Sort next children by distance
        pos = segment-end(segments.last())
        children = children.sorted(key: a => {
          return vector.len(vector.sub(segment-begin(a.segments.first()), pos))
        })
      }
      
      let style = styles.resolve(ctx.style, style)
      cmd.path(..segments, close: close, stroke: style.stroke, fill: style.fill)
  ),)
}

// Render shadow of children by rendering them twice
#let shadow(body, ..style) = {
  // No extra positional arguments from the style sink
  assert.eq(style.pos(), (), message: "Unexpected positional arguments: " + repr(style.pos()))
  let style = style.named()
  ((
    children: ctx => {
      let style = styles.resolve(ctx.style, style, root: "shadow")
      return (
      ..group({
        set-style(fill: style.color, stroke: style.color)
        translate((style.offset-x, style.offset-y, 0))
        body
      }),
      ..body,
      )
    },
  ),)
}

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

#let grid(from, to, step: 1, name: none, help-lines: false, ..style) = {
  let t = (from, to).map(coordinate.resolve-system)
  ((
    name: name,
    coordinates: (from, to),
    render: (ctx, from, to) => {
      let style = styles.resolve(ctx.style, style.named())
      let stroke = if help-lines {
        0.2pt + gray
      } else {
        style.stroke
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
          cmd.path(("line", (x, from.at(1)), (x, to.at(1))), fill: style.fill, stroke: style.stroke)
        }
      }

      if y-step != 0 {
        for y in range(int((to.at(1) - from.at(1)) / y-step)+1) {
          y *= y-step
          y += from.at(1)
          cmd.path(("line", (from.at(0), y), (to.at(0), y)), fill: style.fill, stroke: style.stroke)
        }
      }
    }
  ),)
}
