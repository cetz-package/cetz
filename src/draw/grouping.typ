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
#import "/src/deps.typ"
#import deps.oxifmt: strfmt

#import "transformations.typ": move-to

/// Hides an element.
///
/// Hidden elements are not drawn to the canvas, are ignored when calculating bounding boxes and discarded by `merge-path`. All
/// other behaviours remain the same as a non-hidden element.
///
/// #example(```
/// set-style(radius: .5)
/// intersections("i", {
///   circle((0,0), name: "a")
///   circle((1,2), name: "b")
///   // Use a hidden line to find the border intersections
///   hide(line("a.center", "b.center"))
/// })
/// line("i.0", "i.1")
/// ```)
///
/// - body (element): One or more elements to hide
#let hide(body) = {
  if type(body) == array {
    return body.map(f => {
      (ctx) => {
        let element = f(ctx)
        if "drawables" in element {
          element.drawables = element.drawables.map(d => {
            d.hidden = true
            return d
          })
        }
        return element
      }
    })
  }
  return body
}

/// Calculates the intersections between multiple paths and creates one anchor
/// per intersection point.
///
/// All resulting anchors will be named numerically, starting at 0.
/// i.e., a call `intersections("a", ...)` will generate the anchors
/// `"a.0"`, `"a.1"`, `"a.2"` to `"a.n"`, depending of the number of
/// intersections.
///
/// #example(```
/// intersections("i", {
///   circle((0, 0))
///   bezier((0,0), (3,0), (1,-1), (2,1))
///   line((0,-1), (0,1))
///   rect((1.5,-1),(2.5,1))
/// })
/// for-each-anchor("i", (name) => {
///   circle("i." + name, radius: .1, fill: blue)
/// })
/// ```)
///
/// You can also use named elements:
///
/// #example(```
/// circle((0,0), name: "a")
/// rect((0,0), (1,1), name: "b")
/// intersections("i", "a", "b")
/// for-each-anchor("i", (name) => {
///   circle("i." + name, radius: .1, fill: blue)
/// })
/// ```)
///
/// You can calculate intersections with hidden elements by using @@hide().
///
/// - name (string): Name to prepend to the generated anchors. (Not to be confused with other `name` arguments that allow the use of anchor coordinates.)
/// - ..elements (elements,string): Elements and/or element names to calculate intersections with.
///   Elements referred to by name are (unlike elements passed) not drawn by the intersections function!
/// - samples (int): Number of samples to use for non-linear path segments. A higher sample count can give more precise results but worse performance.
#let intersections(name, ..elements, samples: 10) = {
  samples = calc.clamp(samples, 2, 2500)

  assert(type(name) == str and name != "",
    message: "Intersection must have a name, got:" + repr(name))
  assert(elements.pos() != (),
    message: "You must at least give one element to intersections.")

  return (ctx => {
    let ctx = ctx

    // List of drawables to calc intersections for;
    // grouped by element.
    let named-drawables = ()
    // List of drawables passed as elements to calc intersections for;
    // grouped by element.
    let drawables = ()

    for elem in elements.pos() {
      if type(elem) == str {
        assert(elem in ctx.nodes,
          message: "No such element '" + elem + "' in elements " + repr(ctx.nodes.keys()))
        named-drawables.push(ctx.nodes.at(elem).drawables)
      } else {
        for sub in elem {
          let sub-drawables = ()
          (ctx: ctx, drawables: sub-drawables, ..) = process.element(ctx, sub)
          if sub-drawables != none and sub-drawables != () {
            drawables.push(sub-drawables)
          }
        }
      }
    }

    let elems = named-drawables + drawables
    let pts = ()
    if elems.len() > 1 {
      for (i, elem-1) in elems.enumerate() {
        for j in range(i + 1, elems.len()) {
          let elem-2 = elems.at(j)
          for path-1 in elem-1 {
            for path-2 in elem-2 {
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
      drawables: drawables.flatten()
    )
  },)
}

/// Groups one or more elements together. This element acts as a scope, all state changes such as transformations and styling only affect the elements in the group. Elements after the group are not affected by the changes inside the group.
///
/// #example(```
/// // Create group
/// group({
///   stroke(5pt)
///   scale(.5); rotate(45deg)
///   rect((-1,-1),(1,1))
/// })
/// rect((-1,-1),(1,1))
/// ```)
///
/// = parameters
///
/// = Styling
/// *Root* `group`
///
/// == Keys
///   #show-parameter-block("padding", ("none", "number", "array", "dictionary"), default: none, [How much padding to add around the group's bounding box. `none` applies no padding. A number applies padding to all sides equally. A dictionary applies padding following Typst's `pad` function: https://typst.app/docs/reference/layout/pad/. An array follows CSS like padding: `(y, x)`, `(top, x, bottom)` or `(top, right, bottom, left)`.])
///
/// = Anchors
///   Supports border and path anchors. However they are created based on the axis aligned bounding box of all the child elements of the group.
///
/// You can add custom anchors to the group by using the `anchor` element while in the scope of said group, see `anchor` for more details. You can also copy over anchors from named child element by using the `copy-anchors` element as they are not accessible from outside the group.
///
/// The default anchor is "center" but this can be overridden by using `anchor` to place a new anchor called "default".
///
/// - body (elements, function): Elements to group together. A least one is required. A function that accepts `ctx` and returns elements is also accepted.
/// - anchor (none, string): Anchor to position the group and it's children relative to. For translation the difference between the groups `"default"` anchor and the passed anchor is used.
/// - name (none, string):
/// - ..style (style):
#let group(body, name: none, anchor: none, ..style) = {
  assert(type(body) in (array, function), message: "Incorrect type for body, expected an array or function. Instead got: " + repr(body))
  // No extra positional arguments from the style sink
  assert.eq(
    style.pos(),
    (),
    message: "Unexpected positional arguments: " + repr(style.pos()),
  )
  (ctx => {
    let style = styles.resolve(ctx.style, merge: style.named(), root: "group")

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

    // Calculate a bounding box path used for border
    // anchor calculation.
    let (center, width, height, path) = if bounds != none {
      (bounds.low.at(1), bounds.high.at(1)) = (bounds.high.at(1), bounds.low.at(1))
      let center = aabb.mid(bounds)
      let (width, height, _) = aabb.size(bounds)
      let path = drawable.path(
        path-util.line-segment((
          (bounds.low.at(0), bounds.high.at(1)),
          bounds.high,
          (bounds.high.at(0), bounds.low.at(1)),
          bounds.low,
        )), close: true)
      (center, width, height, path)
    } else { (none, none, none, none) }

    let anchors = group-ctx.groups.last().anchors

    let (transform, anchors) = anchor_.setup(
      anchor => ((center: center, default: center) + anchors).at(anchor),
      (anchors.keys() + ("center",)).dedup(),
      name: name,
      default: if bounds != none { "default" },
      offset-anchor: anchor,
      path-anchors: bounds != none,
      border-anchors: bounds != none,
      radii: (width, height),
      path: path,
    )
    return (
      ctx: ctx,
      name: name,
      anchors: anchors,
      drawables: drawable.apply-transform(transform, drawables),
    )
  },)
}

/// Creates a new anchor for the current group. This element can only be used inside a group otherwise it will panic. The new anchor will be accessible from inside the group by using just the anchor's name as a coordinate.
///
/// #example(```
/// // Create group
/// group(name: "g", {
///   circle((0,0))
///   anchor("x", (.4, .1))
///   circle("x", radius: .2)
/// })
/// circle("g.x", radius: .1)
/// ```)
///
/// - name (string): The name of the anchor
/// - position (coordinate): The position of the anchor
#let anchor(name, position) = {
  assert(name != none and name != "" and not name.starts-with("."),
    message: "Anchors must not be none, \"\" or start with \".\"!")

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

/// Copies multiple anchors from one element into the current group. Panics when used outside of a group. Copied anchors will be accessible in the same way anchors created by the `anchor` element are.
///
/// - element (string): The name of the element to copy anchors from.
/// - filter (auto,array): When set to `auto` all anchors will be copied to the group. An array of anchor names can instead be given so only the anchors that are in the element and the list will be copied over.
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

/// An advanced element that allows you to modify the current canvas context. 
///
/// A context object holds the canvas' state, such as the element dictionary,
/// the current transformation matrix, group and canvas unit length. The following
/// fields are considered stable:
/// - `length` (length): Length of one canvas unit as typst length
/// - `transform` (cetz.matrix): Current 4x4 transformation matrix
/// - `debug` (bool): True if the canvas' debug flag is set
///
/// #example(```
/// // Setting a custom transformation matrix
/// set-ctx(ctx => {
///   let mat = ((1, 0, .5, 0),
///              (0, 1,  0, 0),
///              (0, 0,  1, 0),
///              (0, 0,  0, 1))
///   ctx.transform = mat
///   return ctx
/// })
/// circle((z: 0), fill: red)
/// circle((z: 1), fill: blue)
/// circle((z: 2), fill: green)
/// ```)
///
/// - callback (function): A function that accepts the context dictionary and only returns a new one.
#let set-ctx(callback) = {
  assert(type(callback) == function)
  return (ctx => (ctx: callback(ctx)),)
}

/// An advanced element that allows you to read the current canvas context through a callback and return elements based on it.
///
/// #example(```
/// // Print the transformation matrix
/// get-ctx(ctx => {
///   content((), [#repr(ctx.transform)])
/// })
/// ```)
///
/// - callback (function): A function that accepts the context dictionary and can return elements.
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

/// Iterates through all anchors of an element and calls a callback for each one.
///
/// #example(```
/// // Label nodes anchors
/// rect((0, 0), (2,2), name: "my-rect")
/// for-each-anchor("my-rect", (name) => {
///    content((), box(inset: 1pt, fill: white, text(8pt, [#name])), angle: -30deg)
/// })
/// ```)
///
/// - name (string): The name of the element with the anchors to loop through.
/// - callback (function): A function that takes the anchor name and can return elements.
#let for-each-anchor(name, callback, exclude: ()) = {
  get-ctx(ctx => {
    assert(
      name in ctx.nodes,
      message: strfmt("Unknown element {} in elements {}", name, repr(ctx.nodes.keys()))
    )
    for anchor in (ctx.nodes.at(name).anchors)(()) {
      if anchor == none or (anchor in exclude) { continue }
      move-to(name + "." + anchor)
      callback(anchor)
    }
  })
}

/// Places elements on a specific layer.
///
/// A layer determines the position of an element in the draw queue. A lower
/// layer is drawn before a higher layer.
///
/// Layers can be used to draw behind or in front of other elements, even if
/// the other elements were created before or after. An example would be drawing
/// a background behind a text, but using the text's calculated bounding box for
/// positioning the background.
///
/// #example(```
/// // Draw something behind text
/// set-style(stroke: none)
/// content((0, 0), [This is an example.], name: "text")
/// on-layer(-1, {
///   circle("text.north-east", radius: .3, fill: red)
///   circle("text.south", radius: .4, fill: green)
///   circle("text.north-west", radius: .2, fill: blue)
/// })
/// ```)
///
/// - layer (float, integer): The layer to place the elements on. Elements placed without `on-layer` are always placed on layer 0.
/// - body (elements): Elements to draw on the layer specified.
#let on-layer(layer, body) = {
  assert(type(layer) in (int, float), message: "Layer must be a float or integer, 0 being the default layer. Got: " + repr(layer))
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

// DEPRECATED TODO: Remove
#let place-anchors(path, name, ..anchors) = {
  panic("place-anchors got removed. Use path anchors `(name: <element>, anchor: <number, ratio>)` instead.")
}

// DEPRECATED TODO: Remove
#let place-marks(path, ..marks-style, name: none) = {
  panic("place-marks got removed. Use the `pos:` key of marks for manual mark positioning.")
}
