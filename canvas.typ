#import "matrix.typ"
#import "vector.typ"
#import "draw.typ"
#import "cmd.typ"

// Convert absolute, relative or anchor coordinate to absolute coordinate
#let abs-coordinate(ctx, c) = {
  // Use previous position
  if c == () {
    return ctx.prev.pt
  }

  // Allow strings as shorthand for anchors
  if type(c) == "string" {
      let parts = c.split(".")
      if parts.len() == 1 {
        c = (node: parts.at(0))
      } else {
        c = (node: parts.slice(0, -1).join("."), at: parts.at(-1))
      }
  }

  if type(c) == "dictionary" {
    if "node" in c {
      assert(c.node in ctx.anchors, message: "Unknown node '" + c.node + "'")
      let node = ctx.anchors.at(c.node)
      if "at" in c {
        assert( c.at in node, message: "Unknown anchor '" + c.at + "' of " + repr(node))
        return node.at(c.at)
      }
      return node.default
    }

    // Add relative positions to previous position
    if "rel" in c {
      return vector.add(ctx.prev.pt, abs-coordinate(ctx, c.rel))
    }

    panic("Not implemented")
  }

  // Transform lengths with unit to canvas lenght
  return c.map(x => if type(x) == "length" {
    // HACK ALERT!
    if repr(x).ends-with("em") {
      float(repr(x).slice(0, -2)) * em-size.width / ctx.length
    } else {
      float(x / ctx.length)
    }
  } else {
    float(x)
  })
}

// Compute bounding box of points
#let bounding-box(pts, init: none) = {
  let bounds = init
  if type(pts) == "array" {
    for (i, pt) in pts.enumerate() {
      if init == none and i == 0 {
        bounds = (l: pt.at(0), r: pt.at(0), t: pt.at(1), b: pt.at(1))
      }
      bounds.l = calc.min(bounds.l, pt.at(0))
      bounds.r = calc.max(bounds.r, pt.at(0))
      bounds.t = calc.min(bounds.t, pt.at(1))
      bounds.b = calc.max(bounds.b, pt.at(1))
    }
    } else if type(pts) == "dictionary" {
      if init == none {
        bounds = pts
      } else {
        bounds.l = calc.min(bounds.l, pts.l)
        bounds.r = calc.max(bounds.r, pts.r)
        bounds.t = calc.min(bounds.t, pts.t)
        bounds.b = calc.max(bounds.b, pts.b)
      }
    } else {
      panic(pts)
      panic("Expected array of vectors or bbox dictionary!")
    }
  return bounds
}

// Apply all transformation matrices `queue` in order on `vec`.
#let apply-transform(queue, vec) = {
  for m in queue.values() {
    if m != none {
      vec = matrix.mul-vec(m, vector.as-vec(
        vec, init: (0, 0, 0, 1)))
    }
  }
  return vec.slice(0, 2)
}


// Recursive element traversal function which takes the current ctx, bounds and also returns them (to allow modifying function locals of the root scope)
#let process-element(element, ctx) = {
  if element == none { return }
  let drawables = ()

  let bounds = none

  // Allow to modify the context
  if "modify-ctx" in element {
    ctx = (element.modify-ctx)(ctx)
  }

  // // Render children
  // if "children" in element {
  //   let child-drawables = ()
  //   for child in (element.children)(ctx) {
  //     let r = render-element(child, ctx)
  //     ctx = r.ctx
  //     bounds = bounding-box(r.bounds, init: bounds)
  //     child-drawables += r.drawables
  //   }

  //   if "finalize-children" in element {
  //     drawables += (element.finalize-children)(ctx, child-drawables)
  //   } else {
  //     drawables += child-drawables
  //   }
  // }

  
  // Query element for points
  let coordinates = ()
  if "coordinates" in element {
    for c in element.coordinates {
      c = abs-coordinate(ctx, c)
      ctx.prev.pt = c
      coordinates.push(c)
    }
  }

  // Render element
  if "render" in element {
    for drawable in (element.render)(ctx, ..coordinates) {
      drawable.coordinates = drawable.coordinates.map(x => apply-transform(ctx.transform-stack.last(), x))
      if "bounds" not in drawable {
        drawable.bounds = drawable.coordinates
      }
      bounds = bounding-box(drawable.bounds, init: bounds)
      // Push draw command
      drawables.push(drawable)
    }
  }

  let anchors = (:)
  if bounds != none {
    anchors = (
      center: (
        (bounds.l + bounds.r)/2,
        (bounds.b + bounds.t)/2,
      ),
      left: (
        bounds.l,
        (bounds.b + bounds.t)/2,
      ),
      right: (
        bounds.r,
        (bounds.b + bounds.t)/2,
      ),
      above: (
        (bounds.r + bounds.l)/2,
        bounds.t
      ),
      below: (
        (bounds.r + bounds.l)/2,
        bounds.b
      ),
    )
  }

  if "custom-anchors" in element {
    let prev-pt = ctx.prev.pt
    for (k, c) in (element.custom-anchors)(..coordinates) {
      c = abs-coordinate(ctx, c)
      ctx.prev.pt = c
      anchors.insert(k, c)
    }
    ctx.prev.pt = prev-pt
    // TODO: Apply transform here and apply _inverse_ transform
    //       on anchor (or all final points) in position-to-vec.
    //for (k, v) in elem-anchors {
    //  elem-anchors.at(k) = apply-transform(cur-transform, v)
    //}
    // if "default" in anchors {
    //   ctx.prev.pt = anchors.default
    // }
  }

  if "anchor" in element and type(element.anchor) == "string" {
    let translate = vector.sub(anchors.at(element.default-anchor), anchors.at(element.anchor))
    for (i, d) in drawables.enumerate() {
        drawables.at(i).coordinates = d.coordinates.map(
          c => vector.add(translate, c))
    }
    for (k, a) in anchors {
      anchors.at(k) = vector.add(translate, a)
    }
    bounds = bounding-box(
      (
        vector.add(
          translate, 
          (bounds.l, bounds.t)
        ),
        vector.add(
          translate,
          (bounds.r, bounds.b)
        )
      ),
    )
  }

  if "name" in element and type(element.name) == "string" {
    // panic((anchors, bounds))
    ctx.anchors.insert(element.name, anchors)
  }

  if ctx.debug and bounds != none {
    drawables.push(
      cmd.path(
        ctx, 
        stroke: red, 
        fill: none, 
        close: true, 
        
        (bounds.l, bounds.t),
        (bounds.r, bounds.t),
        (bounds.r, bounds.b),
        (bounds.l, bounds.b),
        ).first()
    )
  }

  if "finalize" in element {
    ctx = (element.finalize)(ctx)
  }

  return (bounds: bounds, ctx: ctx, drawables: drawables)
}


#let canvas(length: 1cm, background: none, debug: false, body) = style(st => {
  if body == none {
    return []
  }
  let em-size = measure(box(width: 1em, height: 1em), st)

  // Default transformation matrices
  let default-transform = (
    // flip-x: matrix.transform-scale((x: 1, y: -1, z: 1)),
    shear: matrix.transform-shear-z(),
  )

  // Canvas bounds
  let bounds = none

  // Canvas context object
  let ctx = (
    style: st,
    length: length,

    debug: debug,

    // Previous element position & bbox
    prev: (pt: (0, 0)),

    // Current draw attributes
    mark-size: .15,
    fill: none,
    stroke: black + 1pt,

    // Current transform stack
    transform-stack: (default-transform,),

    // Saved anchors
    anchors: (:)
  )
  
  let draw-cmds = ()
  for element in body {
    let r = process-element(element, ctx)
    if r != none {
      if r.bounds != none {
        bounds = bounding-box(r.bounds, init: bounds)
      }
      ctx = r.ctx
      draw-cmds += r.drawables
    }

  }

  if bounds == none {
    return []
  } else {
    for (k, v) in bounds {
      bounds.insert(k, v * length)
    }
  }

  // Final canvas size
  let width = calc.abs(bounds.r - bounds.l)
  let height = calc.abs(bounds.t - bounds.b)
  
  // Offset all element by canvas grow to the top/left
  let translate = matrix.transform-translate(
    (0cm - bounds.l) / length, (0cm - bounds.t) / length, 0)
  
  box(stroke: if debug {green}, width: width, height: height, fill: background, {
    for d in draw-cmds {
      d.coordinates = d.coordinates.map(
              v => 
                apply-transform(
                  (translate: translate), v
                ).map(x => ctx.length * x)
            )
      (d.draw)(d)
    }
  })
})
