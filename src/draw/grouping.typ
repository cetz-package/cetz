#import "@preview/oxifmt:0.2.0": strfmt

#import "/src/process.typ"
#import "/src/intersection.typ"
#import "/src/path-util.typ"
#import "/src/styles.typ"
#import "/src/drawable.typ"
#import "/src/vector.typ"
#import "/src/util.typ"
#import "/src/coordinate.typ"
#import "/src/aabb.typ"
#import "/src/anchor.typ" as anchor_

#import "transformations.typ": move-to

/// Calculate intersection between multiple paths and create
/// one anchor per intersection point.
///
/// All resulting anchors will be named numerically, starting by 0.
/// I.e., a call `intersections("a", ...)` will generate the anchors
/// `"a.0"`, `"a.1"`, `"a.2"` to `"a.n"`, depending of the number of
/// intersections.
///
/// - name (string): Name of the node containing the anchors
/// - body (drawables): Drawables to calculate intersections for
/// - samples (int): Number of samples to use for non-linear path segments.
///   A higher sample count can give more precise results but worse performance.
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
      anchors: anchor_.setup(
        anchor => {
          anchors.at(anchor)
        },
        anchors.keys(),
        transform: none,
        name: name
      ).last(),
      drawables: drawables
    )
  },)
}

/// Group one or more elements.
///
/// All state changes but anchors remain group local. That means, that changes
/// to the transformation matrix (i.e. `rotate(...)`) are applied to the groups
/// child elements only.
///
/// A group creates compass anchors of its axis aligned bounding box, that are accessible
/// using the following names: `north`, `north-east`, `east`, `south-east`, `south`, `south-west`, `west` and `north-west`.
/// All anchors created using `anchor(<name>, <position>)` are also accessible, both in
/// the group (by name `"anchor"`) and outsides the group (by the groups name + the anchor name, i.e. `"group.anchor"`)
///
/// - name (none,string): Group element name
/// - anchor (none,string): Anchor of the group to position itself relative to.
///   This is done by calculating the distance to the groups `"default"` anchor
///   and translating all grouped elements by that distance. The groups `"default"`
///   anchor gets set to the groups `"center"` anchor, but the user can supply it's
///   own by calling `anchor("default", ...)`.
/// - ..body-style (drawables,style): Requires one positional parameter, the list of
///   the groups child elements. Accepts style key-value pairs.
#let group(name: none, anchor: none, ..body-style) = {
  assert.eq(body-style.pos().len(), 1,
    message: "Group expects exactly one positional argument.")

  let body = body-style.pos().first()
  assert(type(body) in (array, function),
    message: "Incorrect type for body")

  (ctx => {
    let style = styles.resolve(ctx, body-style.named(), root: "group")

    let bounds = none
    let drawables = ()
    let group-ctx = ctx
    group-ctx.groups.push((anchors: (:)))
    (ctx: group-ctx, drawables, bounds) = process.many(group-ctx, if type(body) == function {body(ctx)} else {body})

    // Apply bounds padding
    let bounds = if bounds != none {
      let padding = util.as-padding-dict(style.padding)
      for (k, v) in padding {
        padding.insert(k, util.resolve-number(ctx, v))
      }

      aabb.padded(bounds, padding)
    }

    let (transform, anchors) = anchor_.setup(
      anchor => {
        let anchors = (:)
        if bounds != none {
          let bounds = bounds
          (bounds.low.at(1), bounds.high.at(1)) = (bounds.high.at(1), bounds.low.at(1))
          let mid = aabb.mid(bounds)
          anchors += (
            north: (mid.at(0), bounds.high.at(1)),
            north-east: bounds.high,
            east: (bounds.high.at(0), mid.at(1)),
            south-east: (bounds.high.at(0), bounds.low.at(1)),
            south: (mid.at(0), bounds.low.at(1)),
            south-west: bounds.low,
            west: (bounds.low.at(0), mid.at(1)),
            north-west: (bounds.low.at(0), bounds.high.at(1)),
            center: mid,
          )
        }
        // Custom anchors need to be added last to override the cardinal anchors.
        anchors += group-ctx.groups.last().anchors
        return anchors.at(anchor)
      },
      group-ctx.groups.last().anchors.keys() + if bounds != none { ("north", "north-east", "east", "south-east", "south", "south-west", "west", "north-west", "center") },
      name: name,
      default: if bounds != none { "center" } else { none },
      offset-anchor: anchor
    )
    return (
      ctx: ctx,
      name: name,
      anchors: anchors,
      drawables: drawable.apply-transform(transform, drawables),
    )
  },)
}

/// Create a new named anchor.
///
/// An anchor is a named position insides a group, that can be referred to
/// by other positions. Anchors can not be defined outsides groups, trying so
/// will emit an error.
///
/// Setting an anchor which name already exists overwrites the previously defined
/// one.
///
/// - name (string): Anchor name
/// - position (position): The anchors position
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
    return (ctx: ctx, name: name, anchors: anchor_.setup(anchor => position, ("default",), default: "default", name: name, transform: none).last())
  },)
}

/// Copy multiple anchors from one element into the current group.
///
/// - element (string): Element name
/// - filter (auto,array): If set to an array, the function copies only
///   anchors that are both in the source element and the filter list
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

    let calc-anchors = ctx.nodes.at(element).anchors
    let anchors = calc-anchors(())
    if filter != auto {
      anchors = anchors.filter(a => a in filter)
    }

    let new = {
      let d = (:)
      for a in anchors {
        d.insert(a, calc-anchors(a))
      }
      d
    }

    // Add each anchor as own element
    for (k, v) in new {
      ctx.nodes.insert(k, (anchors: (name => {
        if name == () { return ("default",) }
        else if name == "default" { v }
      })))
    }

    // Add anchors to group
    ctx.groups.last().anchors += new

    return (ctx: ctx)
  },)
}

/// Place multiple anchors along a path
///
/// - path (drawable): Single drawable
/// - ..anchors (array): List of anchor dictionaries of the form `(pos: <float>, name: <string>)`, where
///   `pos` is a relative position on the path from `0` to `1`.
/// - name: (auto,string): If auto, take the name of the passed drawable. Otherwise sets the
///   elements name
#let place-anchors(path, ..anchors, name: auto) = {
  let name = if name == auto and "name" in path.first() {
    path.first().name
  } else {
    name
  }
  assert(type(name) == str, message: "Name must be of type string")
  
  return (ctx => {
    let (ctx, drawables) = process.many(ctx, path)
    
    assert(drawables.first().type == "path")
    let s = drawables.first().segments
    
    let out = (:)
    for a in anchors.pos() {
      assert("name" in a, message: "Anchor must have a name set")
      out.insert(a.name, path-util.point-on-path(s, a.pos))
    }

    return (
      ctx: ctx,
      name: name,
      anchors: anchor_.setup(
        anchor => {
          out.at(anchor)
        },
        out.keys(),
        name: name,
        transform: none
      ).last(),
      drawables: drawables
    )
  },)
}

/// Modify the current canvas context
///
/// A context object holds the canvas' state, such as the element dictionary,
/// the current transformation matrix, group and canvas unit length. The following
/// fields are considered stable:
/// - `length` (length): Length of one canvas unit as typst length
/// - `transform` (cetz.matrix): Current 4x4 transformation matrix
/// - `debug` (bool): True if the canvas' debug flag is set
///
/// - callback (function): Function accepting a context object and returning the new one: `(ctx) => <ctx>`
#let set-ctx(callback) = {
  assert(type(callback) == function)
  return (ctx => (ctx: callback(ctx)),)
}

/// Get the current context
///
/// Some functions such as `coordinate.resolve(...)` or `styles.resolve(...)` require a context object
/// as argument. See `set-ctx` for a description of the context object.
///
/// - callback (function): Function accepting the current context object and returning drawables or `none`
#let get-ctx(callback) = {
  assert(type(callback) == function)
  (ctx => {
    let body = callback(ctx)
    if body != none {
      let (ctx, drawables) = process.many(ctx, callback(ctx))
      return (ctx: ctx, drawables: drawables)
    }
    return (ctx: ctx)
  },)
}

/// Iterates through all anchors of an element, calling a callback per anchor
///
/// - name (string): The target elements name to iterate over
/// - callback (function): Callback function accepting an anchor name string: `(name) => {}` that
///   must return drawables or `none`.
#let for-each-anchor(name, callback) = {
  get-ctx(ctx => {
    assert(
      name in ctx.nodes,
      message: strfmt("Unknown element {} in elements {}", name, repr(ctx.nodes.keys()))
    )
    for anchor in (ctx.nodes.at(name).anchors)(()) {
      move-to(name + "." + anchor)
      callback(anchor)
    }
  })
}

/// Place elements on a specific layer
///
/// A layer determines the position of an element in the draw queue. A lower
/// layer is drawn before a higher layer.
///
/// Layers can be used to draw behind or in front of other elements, even if
/// the other elements got created before/later. An example would be drawing
/// a background behind a text, but using the texts calculated bounding box for
/// positioning the background.
///
/// - layer (number): Layer number. The default layer of elements is layer 0.
/// - body (drawables): Elements to draw on the layer specified.
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

/// Place one or more marks along a path
///
/// Mark items must get passed as positional arguments. A `mark-item` is an dictionary
/// of the format: `(mark: "<symbol>", pos: <float>)`, where the position `pos` is a
/// relative position from `0` to `1` along the path.
///
/// - name (none,string): Element name
/// - path (drawable): A single drawable
/// - ..marks-style (mark-item,style): Positional `mark-item`s and style key-value pairs
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
          style,
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
