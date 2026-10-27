#import "util.typ"
#import "path-util.typ"
#import "aabb.typ"
#import "drawable.typ"
#import "vector.typ"

#let drawable-tag-no-bounds = drawable.TAG.no-bounds


/// Processes an element's function to get its drawables and bounds. Returns a {{dictionary}} with the key-values: `ctx` The modified context object, `bounds` The {{aabb}} of the element's drawables, `drawables` An {{array}} of the element's {{drawable}}s.
///
/// - ctx (ctx): The current context object.
/// - element-func (function): A function that when passed {{ctx}}, it should return an element dictionary.
/// - compute-bounds (bool): Enable bounds computation.
/// -> dictionary (ctx:, bounds:, drawables:)
#let element(ctx, element-func, compute-bounds: true) = {
  let bounds = none
  let element
  let anchors = (:)

  (ctx, ..element,) = element-func(ctx)

  if "drawables" in element {
    if type(element.drawables) == dictionary {
      element.drawables = (element.drawables,)
    }

    if compute-bounds {
      let points = ()
      for d in element.drawables {
        // We inline the filter here to not pay function-call cost in the hot path
        if drawable.TAG.no-bounds in d.tags {
          continue
        }

        points += if d.type == "path" {
          path-util.bounds(d.segments)
        } else if d.type == "content" {
          let (x, y, _, w, h,) = d.pos + (d.width, d.height)
          ((x - w / 2, y - h / 2, 0.0), (x + w / 2, y + h / 2, 0.0))
        }
      }

      if points.len() > 0 {
        bounds = aabb.aabb(points)
      }
    }
  }

  let name = element.at("name", default: none)
  element.name = name
  if name != none {
    assert.eq(type(name), str,
      message: "Element name must be a string")
    assert(not name.contains("."),
      message: "Invalid name for element '" + element.name + "'; name must not contain '.'")

    if "anchors" in element {
      ctx.nodes.insert(name, element)
      if ctx.groups.len() > 0 {
        ctx.groups.last().push(name)
      }
    }
  } else if element.at("leak-nodes", default: false) {
    // #930 We need to pass down nodes from scope if the parent
    //      element is a group.
    if ctx.groups.len() > 0 {
      ctx.groups.last() += ctx.nodes.keys()
    }
  }

  // Draw a debug bounding box.
  if ctx.debug and bounds != none {
    element.drawables.push(drawable.line-strip(
      (bounds.low,
        (bounds.high.at(0), bounds.low.at(1), 0.0),
        bounds.high,
        (bounds.low.at(0), bounds.high.at(1), 0.0)
      ),
      close: true,
      stroke: red,
      tags: (drawable.TAG.debug,)))
  }

  return (
    ctx: ctx,
    bounds: bounds,
    drawables: element.at("drawables", default: ()),
  )
}

// Processes a list of elements sequentially. Equivalent to calling `element`
// for each element and merging the results (see `many`), but avoids
// function calls and intermediate per-element bounds in the hot path.
#let _many-impl(ctx, body, compute-bounds) = {
  let drawables = ()

  // The running bounds. As the bounds are the component-wise minimum and
  // maximum of all points (with ties resolved to the first value, like
  // `calc.min`/`calc.max`), they can be updated point by point, which
  // yields the same result as merging per-element bounds.
  let has-bounds = false
  let (lx, ly, lz, hx, hy, hz) = (0.0, 0.0, 0.0, 0.0, 0.0, 0.0)

  for el in body {
    if ctx.debug {
      // Slow path: Debug bounding boxes need per-element bounds.
      let r = element(ctx, el, compute-bounds: compute-bounds)
      if r.bounds != none {
        for pt in (r.bounds.low, r.bounds.high) {
          let (x, y, z) = pt
          if not has-bounds {
            (lx, ly, lz, hx, hy, hz) = (x, y, z, x, y, z)
            has-bounds = true
          }
          if x < lx { lx = x }
          if hx < x { hx = x }
          if y < ly { ly = y }
          if hy < y { hy = y }
          if z < lz { lz = z }
          if hz < z { hz = z }
        }
      }
      ctx = r.ctx
      drawables += r.drawables
      continue
    }

    // Equivalent to `(ctx, ..element,) = el(ctx)`.
    let element = el(ctx)
    ctx = element.remove("ctx")

    if "drawables" in element {
      if type(element.drawables) == dictionary {
        element.drawables = (element.drawables,)
      }

      if compute-bounds {
        for d in element.drawables {
          if drawable-tag-no-bounds in d.tags {
            continue
          }

          // Collect the points relevant for the bounds of the drawable.
          let pts = ()
          let lines-only = d.type == "path"
          if lines-only {
            for (origin, _, segments) in d.segments {
              pts.push(origin)
              for seg in segments {
                if seg.len() != 2 or seg.first() != "l" {
                  lines-only = false
                  break
                }
                pts.push(seg.at(1))
              }
              if not lines-only { break }
            }
          }
          if not lines-only {
            pts = if d.type == "path" {
              path-util.bounds(d.segments)
            } else if d.type == "content" {
              let (x, y, _, w, h,) = d.pos + (d.width, d.height)
              ((x - w / 2, y - h / 2, 0.0), (x + w / 2, y + h / 2, 0.0))
            } else {
              ()
            }
          }

          // Points are normalized to three dimensions, like `aabb.aabb`.
          for pt in pts {
            let x = float(pt.at(0, default: 0.0))
            let y = float(pt.at(1, default: 0.0))
            let z = float(pt.at(2, default: 0.0))
            if not has-bounds {
              (lx, ly, lz, hx, hy, hz) = (x, y, z, x, y, z)
              has-bounds = true
            }
            if x < lx { lx = x }
            if hx < x { hx = x }
            if y < ly { ly = y }
            if hy < y { hy = y }
            if z < lz { lz = z }
            if hz < z { hz = z }
          }
        }
      }
    }

    let name = element.at("name", default: none)
    element.name = name
    if name != none {
      assert.eq(type(name), str,
        message: "Element name must be a string")
      assert(not name.contains("."),
        message: "Invalid name for element '" + element.name + "'; name must not contain '.'")

      if "anchors" in element {
        ctx.nodes.insert(name, element)
        if ctx.groups.len() > 0 {
          ctx.groups.last().push(name)
        }
      }
    } else if element.at("leak-nodes", default: false) {
      // #930 We need to pass down nodes from scope if the parent
      //      element is a group.
      if ctx.groups.len() > 0 {
        ctx.groups.last() += ctx.nodes.keys()
      }
    }

    drawables += element.at("drawables", default: ())
  }

  let bounds = if has-bounds { (low: (lx, ly, lz), high: (hx, hy, hz)) }
  return (ctx: ctx, bounds: bounds, drawables: drawables)
}

// Number of elements processed per (cached) chunk in `many`.
#let _chunk-size = 32

/// Runs the `element` function for a list of element functions and aggregates the results.
/// - ctx (ctx): The current context object.
/// - body (array): The array of element functions to process.
/// - compute-bounds (bool): Enable bounds computation.
/// -> dictionary (ctx:, bounds:, drawables:)
#let many(ctx, body, compute-bounds: true) = {
  if body.len() <= _chunk-size {
    return _many-impl(ctx, body, compute-bounds)
  }

  // Process the body in chunks. Each chunk is a separate function call
  // that is cached by Typst. If the canvas needs to be re-evaluated (e.g.
  // in a different context), unchanged chunks are then reused as a whole
  // instead of element by element. The result is the same as processing
  // all elements sequentially.
  let drawables = ()
  let bounds = none
  for i in range(0, body.len(), step: _chunk-size) {
    let r = _many-impl(ctx, body.slice(i, calc.min(i + _chunk-size, body.len())), compute-bounds)
    bounds = aabb.merge(bounds, r.bounds)
    ctx = r.ctx
    drawables += r.drawables
  }
  return (ctx: ctx, bounds: bounds, drawables: drawables)
}
