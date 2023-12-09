#import "util.typ"
#import "path-util.typ"
#import "aabb.typ"
#import "drawable.typ"
#import "vector.typ"

#let element(ctx, element-func) = {
  let bounds = none
  let element
  let anchors = (:)

  (ctx, ..element,) = element-func(ctx)
  if "drawables" in element {
    if type(element.drawables) == dictionary {
      element.drawables = (element.drawables,)
    }
    for drawable in element.drawables {
      bounds = aabb.aabb(
        if drawable.type == "path" {
          path-util.bounds(drawable.segments)
        } else if drawable.type == "content" {
          let (x, y, _, w, h,) = drawable.pos + (drawable.width, drawable.height)
          ((x + w / 2, y - h / 2, 0), (x - w / 2, y + h / 2, 0))
        },
        init: bounds
      )
    }
  }
  if "name" in element and type(element.name) == "string" and "anchors" in element {
    ctx.nodes.insert(element.name, element)
  }

  if ctx.debug and bounds != none {
    element.drawables.push(drawable.path(
      path-util.line-segment((
        bounds.low,
        (bounds.high.at(0), bounds.low.at(1), 0),
        bounds.high,
        (bounds.low.at(0), bounds.high.at(1), 0)
      )),
      stroke: red,
      close: true
    ))
  }

  return (
    ctx: ctx,
    bounds: bounds,
    drawables: element.at("drawables", default: ()),
  )
}

#let many(ctx, body) = {
  let drawables = ()
  let bounds = none

  for el in body {
    let r = element(ctx, el)
    if r != none {
      if r.bounds != none {
        bounds = aabb.aabb(r.bounds, init: bounds)
      }
      ctx = r.ctx
      drawables += r.drawables
    }
  }
  return (ctx: ctx, bounds: bounds, drawables: drawables)
}
