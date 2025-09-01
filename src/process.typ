#import "util.typ"
#import "path-util.typ"
#import "aabb.typ"
#import "drawable.typ"
#import "vector.typ"


/// Processes an element's function to get its drawables and bounds. Returns a {{dictionary}} with the key-values: `ctx` The modified context object, `bounds` The {{aabb}} of the element's drawables, `drawables` An {{array}} of the element's {{drawable}}s.
///
/// - ctx (ctx): The current context object.
/// - element-func (function): A function that when passed {{ctx}}, it should return an element dictionary.
#let element(ctx, element-func) = {
  let bounds = none
  let element
  let anchors = (:)

  (ctx, ..element,) = element-func(ctx)
  if "drawables" in element {
    if type(element.drawables) == dictionary {
      element.drawables = (element.drawables,)
    }
    for drawable in drawable.filter-tagged(element.drawables, drawable.TAG.no-bounds) {
      bounds = aabb.aabb(
        if drawable.type == "path" {
          path-util.bounds(drawable.segments)
        } else if drawable.type == "content" {
          let (x, y, _, w, h,) = drawable.pos + (drawable.width, drawable.height)
          ((x + w / 2, y - h / 2, 0.0), (x - w / 2, y + h / 2, 0.0))
        },
        init: bounds
      )
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
  }

  if ctx.debug and bounds != none {
    element.drawables.push(drawable.line-strip(
      (bounds.low,
        (bounds.high.at(0), bounds.low.at(1), 0.0),
        bounds.high,
        (bounds.low.at(0), bounds.high.at(1), 0.0)
      ),
      close: true,
      stroke: red))
  }

  return (
    ctx: ctx,
    bounds: bounds,
    drawables: element.at("drawables", default: ()),
    element: element,
  )
}

/// Runs the `element` function for a list of element functions and aggregates the results.
/// - ctx (ctx): The current context object.
/// - body (array): The array of element functions to process.
/// -> dictionary
#let many(ctx, body) = {
  let drawables = ()
  let bounds = none
  let elements = ()

  for el in body {
    let r = element(ctx, el)
    if r != none {
      if r.bounds != none {
        let pts = (r.bounds.low, r.bounds.high,)
        bounds = aabb.aabb(pts, init: bounds)
      }
      ctx = r.ctx
      drawables += r.drawables
    }
    elements.push(r.element)
  }
  return (ctx: ctx, bounds: bounds, drawables: drawables, elements: elements)
}
