#import "matrix.typ"
#import "vector.typ"
#import "draw.typ"

#let canvas(length: 1cm, fill: none, ..body) = style(st => {
  let em-size = measure(box(width: 1em, height: 1em), st)

  // Default transformation matrices
  let default-transform = (
    flip-x: matrix.transform-scale((x: 1, y: -1, z: 1)),
    shear: matrix.transform-shear-z(),
  )

  // Apply all transformation matrices `queue` in order
  // on `vec`.
  let apply-transform(queue, vec) = {
    for m in queue.values() {
      if m != none {
        vec = matrix.mul-vec(m, vector.as-vec(
          vec, init: (0, 0, 0, 1)))
      }
    }
    return vec
  }

  // Translate absolute, relative or anchor position
  // to absolute canvas position
  let position-to-vec(v, ctx) = {
    // Use previous position
    if v == () {
      return ctx.prev.pt
    }

    // Allow strings as shorthand for anchors
    if type(v) == "string" {
       let parts = v.split(".")
       if parts.len() == 1 {
         v = (node: parts.at(0))
       } else {
         v = (node: parts.slice(0, -1).join("."), at: parts.at(-1))
       }
    }

    if type(v) == "dictionary" {
      if "node" in v {
        assert(v.node in ctx.anchors, message: "Unknown node '" + v.node + "'")
        let node = ctx.anchors.at(v.node)
        if "at" in v {
          assert( v.at in node, message: "Unknown anchor '" + v.at + "' of " + repr(node))
          return node.at(v.at)
        }
        return node.default
      }

      // Add relative positions to previous position
      if "rel" in v {
        return vector.add(vector.as-vec(ctx.prev.pt, init: (0,0,0)),
          vector.as-vec(position-to-vec(v.rel, ctx),
                        init: (0, 0, 0)))
      }

      panic("Not implemented")
    }

    // Transform lengths with unit to canvas lenght
    return v.map(x => if type(x) == "length" {
      // HACK ALERT!
      if repr(x).ends-with("em") {
        float(repr(x).slice(0, -2)) * em-size.width / length
      } else {
        float(x / length)
      }
    } else {
      float(x)
    })
  }

  // Compute bounding box of points
  let bounding-box(pts, init: none) = {
    let bounds = init
    for (i, pt) in pts.enumerate() {
      if init == none and i == 0 {
        bounds = (l: pt.at(0), r: pt.at(0), t: pt.at(1), b: pt.at(1))
      }
      bounds.l = calc.min(bounds.l, pt.at(0))
      bounds.r = calc.max(bounds.r, pt.at(0))
      bounds.t = calc.min(bounds.t, pt.at(1))
      bounds.b = calc.max(bounds.b, pt.at(1))
    }
    return bounds
  }

  // Canvas bounds
  let bounds = none

  // Canvas context object
  let ctx = (
    style: st,
    length: length,

    // Previous element position & bbox
    prev: (pt: (0, 0, 0)),

    // Current draw attributes
    mark-size: .15,
    fill: none,
    stroke: black + 1pt,

    // Current transform stack
    transform-stack: (default-transform,),

    // Saved anchors
    anchors: (:)
  )
  
  let drawables = ()
  for b in body.pos() {
    // Recursive element traversal function
    // which takes the current ctx, bounds and also
    // returns them (to allow modifying function locals
    // of the root scope)
    let render-element(b, ctx, bounds) = {
      if b == none { return }
      let drawables = ()

      for element in b {
        // Allow to modify the context
        if "apply" in element {
          ctx = (element.apply)(ctx)
        }

        // Render children
        if "children" in element {
          let child-drawables = ()
          for child in (element.children)(ctx) {
            let r = render-element(child, ctx, bounds)
            ctx = r.ctx
            bounds = r.bounds
            child-drawables += r.drawables
          }

          if "finalize-children" in element {
            drawables += (element.finalize-children)(ctx, child-drawables)
          } else {
            drawables += child-drawables
          }
        }

        // Update context functions
        ctx.pos-to-pt = (p) => {
          return vector.as-vec(position-to-vec(p, ctx), init: (0,0,0))
        }

        // Render element
        if "render" in element {
          let cur-transform = ctx.transform-stack.last()

          // Query element for points
          let abs = ()
          if "positions" in element {
            for p in (element.positions)(ctx) {
              p = vector.as-vec(position-to-vec(p, ctx), init: (0,0,0,1))
              ctx.prev.pt = p
              abs.push(p)
            }
          }

          // Allow the element to store anchors
          if "anchors" in element and "name" in element and type(element.name) == "string" {
            let elem-anchors = (element.anchors)(ctx, ..abs)
            // TODO: Apply transform here and apply _inverse_ transform
            //       on anchor (or all final points) in position-to-vec.
            //for (k, v) in elem-anchors {
            //  elem-anchors.at(k) = apply-transform(cur-transform, v)
            //}
            if "default" in elem-anchors {
              ctx.prev.pt = elem-anchors.default
            }

            ctx.anchors.insert(element.name, elem-anchors)
          }

          let element-bounds = none
          for (i, draw) in (element.render)(ctx, ..abs).enumerate() {
            if "pos" in draw {
              draw.pos = draw.pos.map(x => apply-transform(cur-transform, x))

              // Remember last bounding box
              element-bounds = bounding-box(draw.pos, init: element-bounds)

              // Grow canvas
              bounds = bounding-box(draw.pos.map(x =>
                vector.mul(x, length)), init: bounds)

              // Push draw command
              drawables.push(draw)
            }

            if "bounds" in draw {
              draw.bounds = draw.bounds.map(
                x => apply-transform(cur-transform, x))

              // Remember last bounding box
              element-bounds = bounding-box(draw.bounds, init: element-bounds)

              // Grow canvas
              bounds = bounding-box(draw.bounds.map(x =>
                vector.mul(x, length)), init: bounds)
            }
          }

          // TODO: Create default anchors for bounding box
        }

        if "finalize" in element {
          ctx = (element.finalize)(ctx)
        }
      }

      return (bounds: bounds,
              ctx: ctx,
              drawables: drawables)
    }

    let r = render-element(b, ctx, bounds)
    if r != none {
      bounds = r.bounds
      ctx = r.ctx
      drawables += r.drawables
    }
  }

  if bounds == none {
    return []
  }

  // Final canvas size
  let width = calc.abs(bounds.r - bounds.l)
  let height = calc.abs(bounds.t - bounds.b)
  
  // Offset all element by canvas grow to the top/left
  let translate = matrix.transform-translate(
    (0cm - bounds.l) / length, (0cm - bounds.t) / length, 0)

  let draw = (
    line: (self, ..pos) => {
      place(path(stroke: self.stroke, fill: self.fill,
                 closed: self.close, ..pos))
    },
    rect: (self, a, b) => {
      let (x1, y1) = a
      let (x2, y2) = b
      place(path(stroke: self.stroke, fill: self.fill, closed: true,
        a, (x2, y1), b, (x1, y2)))
    },
    content: (self, pt) => {
      place(dx: pt.at(0), dy: pt.at(1), self.content)
    }
  );
  
  box(width: width, height: height, fill: fill, {
    for d in drawables {
      draw.at(d.cmd)(d, ..d.pos.map(v =>
        apply-transform((translate: translate), v).slice(0, 2)
          .map(x => length * x)))
    }
  })
})
