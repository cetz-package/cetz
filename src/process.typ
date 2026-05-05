#import "util.typ"
#import "path-util.typ"
#import "aabb.typ"
#import "drawable.typ"
#import "vector.typ"


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
  if compute-bounds and "drawables" in element {
    if type(element.drawables) == dictionary {
      element.drawables = (element.drawables,)
    }

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

/// Runs the `element` function for a list of element functions and aggregates the results.
/// - ctx (ctx): The current context object.
/// - body (array): The array of element functions to process.
/// - compute-bounds (bool): Enable bounds computation.
/// -> dictionary (ctx:, bounds:, drawables:)
#let many(ctx, body, compute-bounds: true) = {
  let drawables = ()
  let bounds = none

  for el in body {
    let r = element(ctx, el, compute-bounds: compute-bounds)
    if r != none {
      bounds = aabb.merge(bounds, r.bounds)

      ctx = r.ctx
      drawables += r.drawables
    }
  }
  return (ctx: ctx, bounds: bounds, drawables: drawables)
}
