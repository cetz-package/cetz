#import "matrix.typ"
#import "vector.typ"
#import "draw.typ"
#import "cmd.typ"
#import "util.typ"
#import "coordinate.typ"

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
      panic("Expected array of vectors or bbox dictionary, got: " + repr(pts))
    }
  return bounds
}


// Recursive element traversal function which takes the current ctx, bounds and also returns them (to allow modifying function locals of the root scope)
#let process-element(element, ctx) = {
  if element == none { return }
  let drawables = ()
  let bounds = none
  let anchors = (:)

  // Allow to modify the context
  if "before" in element {
    ctx = (element.before)(ctx)
  }

  if "push-transform" in element {
    ctx.transform = matrix.mul-mat(
      if type(element.push-transform) == "function" { (element.push-transform)(ctx) } else { element.push-transform }, 
      ctx.transform
    )
  }

  // Render children
  if "children" in element {
    let child-drawables = ()
    let children = if type(element.children) == "function" {
      (element.children)(ctx)
    } else {
      element.children
    }
    for child in children {
      let r = process-element(child, ctx)
      if r != none {
        if r.bounds != none {
          bounds = bounding-box(r.bounds, init: bounds)
        }
        ctx = r.ctx
        child-drawables += r.drawables
      }
    }

    if "finalize-children" in element {
      drawables += (element.finalize-children)(ctx, child-drawables)
    } else {
      drawables += child-drawables
    }
  }

  // Query element for points
  let coordinates = ()
  if "coordinates" in element {
    for c in element.coordinates {
      c = coordinate.resolve(ctx, c)

      // if the first element is `false` don't update the previous point
      if c.first() == false {
        // the format here is `(false, x, y, z)` so get rid of the boolean
        c = c.slice(1)
      } else {
        ctx.prev.pt = c
      }
      coordinates.push(c)
    }
  }

  // Render element
  if "render" in element {
    for drawable in (element.render)(ctx, ..coordinates) {
      // Transform position to absolute
      drawable.segments = drawable.segments.map(s => {
        return (s.at(0),) + s.slice(1).map(util.apply-transform.with(ctx.transform))
      })

      if "bounds" not in drawable {
        drawable.bounds = drawable.segments.map(s => s.slice(1)).flatten()
      } else {
        drawable.bounds = drawable.bounds.map(util.apply-transform.with(ctx.transform));
      }

      bounds = bounding-box(drawable.bounds, init: bounds)

      // Push draw command
      drawables.push(drawable)
    }
  }


  // Add default anchors
  if bounds != none {
    let mid-x = (bounds.l + bounds.r) / 2
    let mid-y = (bounds.t + bounds.b) / 2
    anchors += (
      center: (mid-x, mid-y, 0),
      left: (bounds.l, mid-y, 0),
      right: (bounds.r, mid-y, 0),
      top: (mid-x, bounds.t, 0),
      bottom: (mid-x, bounds.b, 0),
      top-left: (bounds.l, bounds.t, 0),
      top-right: (bounds.r, bounds.t, 0),
      bottom-left: (bounds.l, bounds.b, 0),
      bottom-right: (bounds.r, bounds.b, 0),
    )

    // Add alternate names
    anchors.above = anchors.top
    anchors.below = anchors.bottom
  }
  
  // Query element for (relative) anchors
  let custom-anchors = if "custom-anchors-ctx" in element {
    (element.custom-anchors-ctx)(ctx, ..coordinates)
  } else if "custom-anchors" in element {
    (element.custom-anchors)(..coordinates)
  }
  if custom-anchors != none {
    for (k, a) in custom-anchors {
      anchors.insert(k, util.apply-transform(ctx.transform, a)) // Anchors are absolute!
    }
  }

  // Query (already absolute) anchors depending on drawable
  if "custom-anchors-drawables" in element {
    for (k, a) in (element.custom-anchors-drawables)(drawables) {
      anchors.insert(k, a)
    }
  }

  if "default" not in anchors {
    anchors.default = if "default-anchor" in element {
      anchors.at(element.default-anchor)
    } else if "center" in anchors {
      anchors.center
    }
  }

  if "anchor" in element and element.anchor != none {
    assert(element.anchor in anchors,
          message: "Anchor '" + element.anchor + "' not found in " + repr(anchors))
    let translate = vector.sub(anchors.default, anchors.at(element.anchor))
    for (i, d) in drawables.enumerate() {
        drawables.at(i).segments = d.segments.map(
          s => (s.at(0),) + s.slice(1).map(c => vector.add(translate, c)))
    }

    for (k, a) in anchors {
      anchors.insert(k, vector.add(translate, a))
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
    ctx.nodes.insert(
      element.name, 
      (
        anchors: anchors,
        // Part of intersections
        // paths: for drawable in drawables {
        //   if drawable.type == "path" {
        //     (drawable.coordinates + if drawable.close {(drawable.coordinates.first(),)},)
        //   }
        // }
      )
    )
  }

  if ctx.debug and bounds != none {
    drawables.push(
      cmd.path(
        ctx, 
        stroke: red, 
        fill: none, 
        close: true, 
        ("line", (bounds.l, bounds.t),
                 (bounds.r, bounds.t),
                 (bounds.r, bounds.b),
                 (bounds.l, bounds.b))
      ).first()
    )
  }

  if "after" in element {
    ctx = (element.after)(ctx, ..coordinates)
  }

  return (bounds: bounds, ctx: ctx, drawables: drawables)
}


#let canvas(length: 1cm,        /* Length of 1.0 canvas units */
            background: none,   /* Background paint */
            debug: false, body) = layout(ly => style(st => {
  if body == none {
    return []
  }

  let length = length
  assert(type(length) in ("length", "ratio"),
         message: "length: Expected length, got " + type(length) + ".")
  if type(length) == "ratio" {
    // NOTE: Ratio length is based on width!
    length = ly.width * length
  }

  // Canvas bounds
  let bounds = none

  // Canvas context object
  let ctx = (
    style: st,
    length: length,

    debug: debug,

    // Previous element position & bbox
    prev: (pt: (0, 0, 0)),

    // Current content padding size (added around content boxes)
    content-padding: 0em,

    // Current draw attributes
    mark-size: .15,
    fill: none,
    stroke: black + 1pt,
    em-size: measure(box(width: 1em, height: 1em), st),

    // Current transform
    transform: matrix.mul-mat(
      matrix.transform-shear-z(.5),
      matrix.transform-scale((x: 1, y: -1, z: 1)),
    ),

    // Nodes, stores anchors and paths
    nodes: (:),

    // group stack
    groups: (),
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
  }

  // Final canvas size
  let width = calc.abs(bounds.r - bounds.l) * length
  let height = calc.abs(bounds.t - bounds.b) * length
  
  // Offset all element by canvas grow to the bottom/left
  let transform = matrix.transform-translate(
    -bounds.l, 
    -bounds.t, 
    0
  )
  box(stroke: if debug {green}, width: width, height: height, fill: background, {
    for d in draw-cmds {
      d.segments = d.segments.map(s => {
        return (s.at(0),) + s.slice(1).map(v => {
          return util.apply-transform(transform, v)
            .slice(0,2).map(x => ctx.length * x)
        })
      })
      (d.draw)(d)
    }
  })
}))
