#import "/src/process.typ"
#import "transformations.typ": move-to
#import "/src/intersection.typ"
#import "/src/path-util.typ"
#import "/src/styles.typ"
#import "/src/drawable.typ"
#import "/src/vector.typ"
#import "/src/util.typ"
#import "/src/coordinate.typ"

#let intersections(name, body, samples: 10) = {
  samples = calc.clamp(samples, 2, 2500)

  return (ctx => {
    let (ctx, drawables, ..) = process.many(ctx, body)
    let paths = drawables.filter(d => d.type == "path")

    let pts = ()
    if paths.len() > 1 { 
      for (i, path-1) in paths.enumerate() {
        for path-2 in paths.slice(i+1) {
          for pt in intersection.path-path(
            path-1,
            path-2,
            samples: samples
          ) {
            if pt not in pts { pts.push(pt) }
          }
        }
      }
    }
    let anchors = (:)
    for (i, pt) in pts.enumerate() {
      anchors.insert(str(i), pt)
    }

    return (
      ctx: ctx,
      name: name,
      anchors: anchors,
      drawables: drawables
    )
  },)
}


#let group(name: none, anchor: none, body) = {
  assert(type(body) in (array, function), message: "Incorrect type for body")
  (
    ctx => {
      let bounds = none
      let drawables = ()
      let group-ctx = ctx
      group-ctx.groups.push((anchors: (:)))
      (ctx: group-ctx, drawables, bounds) = process.many(group-ctx, if type(body) == function {body(ctx)} else {body})
      
      return (
        ctx: ctx,
        name: name,
        anchor: anchor,
        anchors: group-ctx.groups.last().anchors,
        // bounds: bounds,
        drawables: drawables,
      )
    },
  )
}

#let anchor(name, position) = {
  coordinate.resolve-system(position)
  return (ctx => {
    assert(
      ctx.groups.len() > 0,
      message: "Anchor '" + name + "' created outside of group!",
    )
    let (ctx, position) = coordinate.resolve(ctx, position)
    position = util.apply-transform(ctx.transform, position)
    ctx.groups.last().anchors.insert(name, position)
    return (ctx: ctx, name: name, anchors: (default: position))
  },)
}

#let copy-anchors(element, filter: auto) = {
  (ctx => {
    assert(
      ctx.groups.len() > 0,
      message: "copy-anchors cannot be used outside of a group.",
    )
    assert(
      element in ctx.nodes,
      message: "copy-anchors: Could not find element '" + element + "'",
    )
    
    if filter == auto {
      ctx.groups.last().anchors += ctx.nodes.at(element).anchors
    } else {
      let d = (:)
      for k in filter {
        d.insert(k, ctx.nodes.at(element).anchors.at(k))
      }
      ctx.groups.last().anchors += d
    }
    return (ctx: ctx)
  },)
}

#let place-anchors(path, ..anchors, name: auto) = {
  let name = if name == auto and "name" in path.first() {
    path.first().name
  } else {
    name
  }
  assert(type(name) == str, message: "Name must be of type string")
  
  return (ctx => {
    let (ctx, drawables) = process.many(ctx, path)
    
    let out = (:)
    assert(drawables.first().type == "path")
    let s = drawables.first().segments
    for a in anchors.pos() {
      assert("name" in a, message: "Anchor must have a name set")
      out.insert(a.name, path-util.point-on-path(s, a.pos))
    }
    
    return (ctx: ctx, name: name, anchors: out, drawables: drawables)
  },)
}


#let set-ctx(callback) = {
  assert(type(callback) == function)
  return (ctx => (ctx: callback(ctx)),)
}

#let get-ctx(callback) = {
  assert(type(callback) == function)
  (ctx => {
    let (ctx, drawables) = process.many(ctx, callback(ctx))
    return (ctx: ctx, drawables: drawables)
  },)
}

#let for-each-anchor(name, callback) = {
  get-ctx(ctx => {
    for (anchor, _) in ctx.nodes.at(name).at("anchors", default: (:)) {
      move-to(name + "." + anchor)
      callback(anchor)
    }
  })
}

#let on-layer(layer, body) = {
  assert(type(layer) in (int, float), message: "Layer must be numeric, 0 being the default layer. Got: " + repr(layer))
  assert(type(body) in (function, array))
  return (ctx => {
    let (ctx, drawables, ..) = process.many(ctx, if type(body) == function { body(ctx) } else { body })

    drawables = drawables.map(d => {
      if d.at("z-index", default: none) == none {
        d.z-index = layer
      }
      return d
    })

    return (
      ctx: ctx,
      drawables: drawables
    )
  },)
}

#let place-marks(path, ..marks-style, name: none) = {
  let (marks, style) = (marks-style.pos(), marks-style.named())
  assert(type(path) == array and path.len() == 1 and type(path.first()) == function)
  path = path.first()
  return (ctx => {
    let (ctx, drawables) = process.element(ctx, path)
    let paths = drawables.filter(d => d.type == "path")
    assert(paths.len() > 0, message: "Cannot place marks on an element with no path.")

    let path = paths.first()
    let anchors = (
      start: path-util.point-on-path(path.segments, 0),
      end: path-util.point-on-path(path.segments, 1)
    )

    let style = styles.resolve(ctx.style, style, root: "mark")

    for mark in marks {
      let (pos, dir) = path-util.direction(path.segments, mark.pos)
      drawables.push(
        drawable.mark(
          vector.add(pos, dir),
          pos,
          mark.mark,
          style.size,
          fill: style.fill,
          stroke: style.stroke
        )
      )
      if "name" in mark {
        anchors.insert(m.name, path-util.point-on-path(path, mark.pos))
      }
    }

    return (
      ctx: ctx,
      name: name,
      drawables: drawables,
      anchors: anchors,
    )
  },)
}