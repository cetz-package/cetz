#import "util.typ"
#import "path-util.typ"
#import "aabb.typ"
#import "drawable.typ"
#import "vector.typ"

#let element(ctx, element-func) = {
  let bounds = none
  // let drawables = ()
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
    

    // element.drawables = for drawable in element.drawables {
    //   if not drawable.at("transformed", default: false) {
    //     if drawable.type == "path" {
    //       drawable.segments = drawable.segments.map(
    //         s => {
    //           return (s.at(0),) + s.slice(1).map(util.apply-transform.with(ctx.transform))
    //         },
    //       )
    //       drawable.bounds = path-util.bounds(drawable.segments)
    //     } else if drawable.type == "content" {
    //       drawable.pos = util.apply-transform(ctx.transform, drawable.pos)
    //       let (x, y, _, w, h,) = drawable.pos + (drawable.width, drawable.height)
    //       drawable.bounds = ((x + w / 2, y - h / 2, 0), (x - w / 2, y + h / 2, 0))
    //     }

    //   }
    //   bounds = aabb.aabb(drawable.bounds, init: bounds)
    //   (drawable,)
    // }
  }

  if bounds != none and element.at("add-default-anchors", default: true) {
    let mid = aabb.mid(bounds)
    let (low: low, high: high) = bounds
    anchors += (
      center: mid,
      left: (low.at(0), mid.at(1), 0),
      right: (high.at(0), mid.at(1), 0),
      top: (mid.at(0), low.at(1), 0),
      bottom: (mid.at(0), high.at(1), 0),
      top-left: (low.at(0), low.at(1), 0),
      top-right: (high.at(0), low.at(1), 0),
      bottom-left: (low.at(0), high.at(1), 0),
      bottom-right: (high.at(0), high.at(1), 0),
    )

    // Add alternate names
    anchors.above = anchors.top
    anchors.below = anchors.bottom
  }

  if "anchors" in element {
    for (k, a,) in element.anchors {
      anchors.insert(k, a)
    }
  }

  if "default" not in anchors {
    anchors.default = if "default-anchor" in element {
      anchors.at(element.default-anchor)
    } else if "center" in anchors {
      anchors.center
    } else {
      (0, 0, 0, 1)
    }
  }

  if "anchor" in element and element.anchor != none {
    assert(
      element.anchor in anchors,
      message: "Anchor '" + element.anchor + "' not found in " + repr(anchors),
    )
    let translate = vector.sub(anchors.default, anchors.at(element.anchor))
    element.drawables = for d in element.drawables {
      if d.type == "path" {
        d.segments = d.segments.map(s => (s.at(0),) + s.slice(1).map(c => vector.add(translate, c)))
      } else if d.type == "content" {
        d.pos = vector.add(translate, d.pos)
      }
      (d,)
    }

    for (k, a,) in anchors {
      anchors.insert(k, vector.add(translate, a))
    }

    
    bounds = if bounds != none {
      aabb.aabb(
        (
          vector.add(
            translate, 
            (bounds.low.at(0), bounds.low.at(1))
          ),
          vector.add(
            translate, 
            (bounds.high.at(0), bounds.high.at(1))
          )
        )
      )
    }
  }

  if anchors != (:) and "name" in element and type(element.name) == "string" {
    ctx.nodes.insert(element.name, (anchors: anchors))
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