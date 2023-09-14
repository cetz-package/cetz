#import "vector.typ"
#import "matrix.typ"
#import "cmd.typ"
#import "util.typ"
#import "path-util.typ"
#import "coordinate.typ"
#import "bezier.typ": to-abc, quadratic-through-3points, cubic-through-3points, quadratic-to-cubic, cubic-point
#import "intersection.typ"
#import "styles.typ"

#let typst-rotate = rotate
#let typst-measure = measure
#let typst-angle = angle
#let typst-center = center

// Measure content in canvas coordinates
#let measure(cnt, ctx) = {
  let size = typst-measure(cnt, ctx.typst-style)

  // Transformation matrix:
  // sx .. .. .
  // .. sy .. .
  // .. .. sz .
  // .. .. .. 1
  let sx = ctx.transform.at(0).at(0)
  let sy = ctx.transform.at(1).at(1)

  return (calc.abs(size.width / ctx.length / sx),
          calc.abs(size.height / ctx.length / sy))
}

/// Set current style
///
/// - ..style (any): Style key/value pairs
#let set-style(..style) = {
  assert.eq(style.pos().len(), 0,
            message: "set-style takes no positional arguments" )
  ((
    style: style.named()
  ),)
}

/// Set current fill style
///
/// Shorthand for `set-style(fill: <fill>)`
///
/// - fill (paint): Fill style
#let fill(fill) = ((style: (fill: fill)),)

/// Set current stroke style
///
/// Shorthand for `set-style(stroke: <fill>)`
///
/// - stroke (stroke): Stroke style
#let stroke(stroke) = ((style: (stroke: stroke)),)

/// Set current coordinate
///
/// The current coordinate can be used via `()` (empty coordinate).
/// It is also used as base for relative coordinates if not specified
/// otherwise.
///
/// - pt (coordinate): Coordinate to move to
#let move-to(pt) = {
  let t = coordinate.resolve-system(pt)
  ((
    coordinates: (pt, ),
    render: (ctx, pt) => (),
  ),)
}

/// Rotate on z-axis (default) or specified axes if `angle` is of type
/// dictionary.
///
/// - angle (typst-angle,dictionary): Angle (z-axis) or dictionary of the
///                                   form `(x: <typst-angle>, y: <angle>, z: <angle>)`
///                                   specifying per axis rotation typst-angle.
#let rotate(angle) = {
  let resolve-typst-angle(angle) = {
    return if type(angle) == typst-angle {
      matrix.transform-rotate-z(-angle)
    } else if type(angle) == dictionary {
      matrix.transform-rotate-xyz(
          -angle.at("x", default: 0deg),
          -angle.at("y", default: 0deg),
          -angle.at("z", default: 0deg),
        )
    } else {
      panic("Invalid angle format '" + repr(angle) + "'")
    }
  }

  let needs-resolve = (type(angle) == array and
                       type(angle.first()) == function)
  return ((
    push-transform: if needs-resolve { 
      ctx => matrix.mul-mat(ctx.transform, resolve-typst-angle(
        coordinate.resolve-function(coordinate.resolve, ctx, angle)))
    } else {
      resolve-typst-angle(angle)
    }
  ),)
}

/// Push scale matrix
///
/// - factor (float,dictionary): Scaling factor for all axes or per axis scaling
///                              factor dictionary.
#let scale(factor) = ((
  push-transform: matrix.transform-scale(factor)
),)

/// Push translation matrix
///
/// - vec (vector,dictionary): Translation vector
/// - pre (bool): Specify matrix multiplication order
///               - false: `World = World * Translate`
///               - true:  `World = Translate * World`
#let translate(vec, pre: true) = {
  let resolve-vec(vec) = {
    let (x,y,z) = if type(vec) == dictionary {
      (
        vec.at("x", default: 0),
        vec.at("y", default: 0),
        vec.at("z", default: 0),
      )
    } else if type(vec) == array {
      if vec.len() == 2 {
        vec + (0,)
      } else {
        vec
      }
    } else {
      panic("Invalid angle format '" + repr(vec) + "'")
    }
    return matrix.transform-translate(x, -y, z)
  }

  let needs-resolve = type(vec) == array and type(vec.first()) == function
  ((
    push-transform: if needs-resolve {
      if pre {
        ctx => matrix.mul-mat(resolve-vec(coordinate.resolve-function(
          coordinate.resolve, ctx, vec)), ctx.transform)
      } else {
        ctx => matrix.mul-mat(ctx.transform,
          resolve-vec(coordinate.resolve-function(
            coordinate.resolve, ctx, vec)))
      }
    } else {
      if pre {
        ctx => matrix.mul-mat(resolve-vec(vec), ctx.transform)
      } else {
        ctx => matrix.mul-mat(ctx.transform, resolve-vec(vec))
      }
    },
  ),)
}

/// Sets the given position as the origin
///
/// - origin (coordinate): Coordinate to set as new origin
#let set-origin(origin) = {
  return ((
    push-transform: ctx => {
      let (x,y,z) = vector.sub(
        util.apply-transform(ctx.transform, coordinate.resolve(ctx, origin)),
        util.apply-transform(ctx.transform, (0,0,0)))
      return matrix.mul-mat(matrix.transform-translate(x, y, z),
                            ctx.transform)
    }
  ),)
}

/// Span rect between `from` and `to` as "viewport" with bounds `bounds`.
///
/// - from (coordinate): Bottom-Left corner coordinate
/// - to (coordinate): Top right corner coordinate
/// - bounds (vector): Bounds vector
#let set-viewport(from, to, bounds: (1, 1, 1)) = ((
  push-transform: ctx => {
    let bounds = vector.as-vec(bounds, init: (1, 1, 1))

    let (fx,fy,fz) = coordinate.resolve(ctx, from)
    let (tx,ty,tz) = coordinate.resolve(ctx, to)

    // Compute scaling
    let (sx,sy,sz) = vector.sub((tx,ty,tz), (fx,fy,fz)).enumerate().map(
      ((i, v)) => if bounds.at(i) == 0 {0} else {v / bounds.at(i)})

    let t = matrix.transform-translate(fx, fy, fz)
    let s = matrix.transform-scale((x: sx, y: sy, z: sz))
    return matrix.mul-mat(ctx.transform, matrix.mul-mat(t, s))
  }
),)

/// Register anchor `name` at position.
///
/// This only works inside a group!
///
/// - name (string): Anchor name
/// - position (coordinate): Coordinate
#let anchor(name, position) = {
  let t = coordinate.resolve-system(position)
  ((
    name: name,
    coordinates: (position,),
    custom-anchors: (position) => (default: position),
    after: (ctx, position) => {
      assert(ctx.groups.len() > 0, message: "Anchor '" + name + "' created outside of group!")
      ctx.groups.last().anchors.insert(name, ctx.nodes.at(name).anchors.default)
      return ctx
    }
  ),)
}

/// Copy anchors of element to current group
///
/// - element (string): Source element to copy anchors from
/// - filter (none,array): Name of anchors to copy or `none` to copy all
#let copy-anchors(element, filter: none) = ((
  after: ctx => {
    assert(ctx.groups.len() > 0,
      message: "copy-anchors with name=none is only allowed inside a group")
    assert(element in ctx.nodes,
      message: "copy-anchors: Could not find element '" + element + "'")

    if filter == none {
      ctx.groups.last().anchors += ctx.nodes.at(element).anchors
    } else {
      let d = (:)
      for k in filter { d.insert(k, ctx.nodes.at(element).anchors.at(k)) }
      ctx.groups.last().anchors += d
    }
    return ctx
  },
),)

/// Modify the canvas' context
///
/// - callback (function): Function of the form `ctx => ctx` that returns the
///                        new canvas context.
#let set-ctx(callback) = {
  assert(type(callback) == function)
  ((
    before: callback,
  ),)
}

/// Get the canvas' context and return children
///
/// - body (function): Function of the form `ctx => elements` that receives the
///                    current context and returns draw commands.
#let get-ctx(body) = {
  assert(type(body) == function)
  ((
    children: ctx => {
      let c = body(ctx)
      return if c == none { () } else { c }
    },
  ),)
}

/// Push a group
///
/// A group has a local transformation matrix.
/// Groups can be used to get an elements bounding box, as they
/// set default anchors (top, top-left, ..) to the bounding box of
/// their children.
///
/// Note: You can pass `content` a function of the form `ctx => draw-cmds`
/// which returns the groups children. This way you get access to the
/// groups context dictionary.
///
/// - name (string): Element name
/// - anchor (string): Element origin
/// - body (elements, function): Children or function of the form (`ctx => elements`)
#let group(name: none, anchor: none, body) = {
  let body = if body == none { () } else { body }
  ((
    name: name,
    anchor: anchor,
    default-anchor: "center",
    before: ctx => {
      ctx.groups.push((
        ctx: ctx,
        anchors: (:),
      ))
      return ctx
    },
    children: body,
    custom-anchors-ctx: ctx => {
      let anchors = ctx.groups.last().anchors
      for (k,v) in anchors {
        anchors.insert(k, util.revert-transform(ctx.transform, v))
      }
      return anchors
    },
    after: (ctx) => {
      let self = ctx.groups.pop()
      let nodes = ctx.nodes
      ctx = self.ctx
      if name != none {
        ctx.nodes.insert(name, nodes.at(name))
      }
      return ctx
    }
  ),)
}

/// Draw body on layer
///
/// This can be used to draw elements behind already drawn elements by
/// using a lower layer value (i.e -1). The layer value can be seen as a z-index.
/// 
/// - layer (number): Layer to draw the children at. The base layer is at 0
///                   and all layers are drawn from low to high.
/// - body (elements, function): Child elements or function (`ctx => elements`)
#let on-layer(layer, body) = {
  assert(type(layer) in ("integer", "float"),
    message: "Layer must be numeric, 0 being the default layer.")
  ((
    children: body,
    finalize-children: (ctx, cmds) => {
      cmds.map(c => {
        if c.at("z-index", default: none) == none {
          c.z-index = layer
        }
        return c
      })
    }
  ),)
}

/// Draw a mark or "arrow head" between two coordinates
///
/// *Style root:* `mark`.
///
/// Its styling influences marks being drawn on paths (`line`, `bezier`, ...).
///
/// - from (coordinate): Source coordinate
/// - to (coordinate): Target coordinate
/// - ..style (style): Style
#let mark(from, to, ..style) = {
  assert.eq(style.pos(), (), message: "Unexpected positional arguments: " + repr(style.pos()))
  let style = style.named()
  let t = (from, to).map(coordinate.resolve-system)
  ((
    coordinates: (from, to),
    render: (ctx, from, to) => {
      let style = styles.resolve(ctx.style, style, root: "mark")
      cmd.mark(from, to, style.symbol, fill: style.fill, stroke: style.stroke)
    }
  ),)
}

/// Draw a line or poly-line
///
/// Draws a line (a direct path between points) to the canvas.
/// If multiple coordinates are given, a line is drawn between each
/// consecutive one.
///
/// *Style root:* `line`.
///
/// *Anchors:*
///   - start -- First coordinate
///   - end   -- Last coordinate
///
/// - ..pts-style (coordinate,style): - Coordinates to draw the line(s) between.
///                                     A min. of two points must be given.
///                                   - Style attribute to set
/// - close (bool): Close path. If `true`, a straight line is drawn from
///                 the last back to the first coordinate, closing the path.
/// - name (string): Element name
#let line(..pts-style, close: false, name: none) = {
  // Extra positional arguments from the pts-style
  // sink are interpreted as coordinates.
  let (pts, style) = (pts-style.pos(), pts-style.named())
  assert(pts.len() >= 2,
    message: "Line must have a minimum of two points")

  // Coordinate check
  let t = pts.map(coordinate.resolve-system)
  ((
    name: name,
    coordinates: pts,
    custom-anchors: (..pts) => {
      let pts = pts.pos()
      (
        start: pts.first(),
        end: pts.last(),
      )
    },
    render: (ctx, ..pts) => {
      let pts = pts.pos()
      let style = styles.resolve(ctx.style, style, root: "line")
      cmd.path(close: close, ("line", ..pts),
        fill: style.fill, stroke: style.stroke)

      if style.mark.start != none or style.mark.end != none {
        let style = style.mark
        if style.start != none {
          let (start, end) = (pts.at(1), pts.at(0))
          let n = vector.scale(vector.norm(vector.sub(end, start)),
                              style.size)
          start = vector.sub(end, n)
          cmd.mark(start, end, style.start,
            fill: style.fill, stroke: style.stroke)
        }
        if style.end != none {
          let (start, end) = (pts.at(-2), pts.at(-1))
          let n = vector.scale(vector.norm(vector.sub(end, start)),
            style.size)
          start = vector.sub(end, n)
          cmd.mark(start, end, style.end,
            fill: style.fill, stroke: style.stroke)
        }
      }
    }
  ),)
}

/// Draw a rect from `a` to `b`
///
/// *Style root:* `rect`.
///
/// *Anchors*:
/// - center: Center
/// - top-left: Top left
/// - top-right: Top right
/// - bottom-left: Bottom left
/// - bottom-left: Bottom right
/// - top: Mid between top-left and top-right
/// - left: Mid between top-left and bottom-left
/// - right: Mid between top-right and bottom-right
/// - bottom: Mid between bottom-left and bottom-right
///
/// - a (coordinate): Bottom-Left coordinate
/// - b (coordinate): Top-Right coordinate
/// - name (string): Element name
/// - anchor (string): Element origin
/// - ..style (style): Style
#let rect(a, b, name: none, anchor: none, ..style) = {
  // Coordinate check
  let t = (a, b).map(coordinate.resolve-system)

  // No extra positional arguments from the style sink
  assert.eq(style.pos(), (), message: "Unexpected positional arguments: " + repr(style.pos()))
  let style = style.named()
  ((
    name: name,
    default-anchor: "center",
    anchor: anchor,
    coordinates: (a, b),
    custom-anchors: (a, b) => {
      let c = vector.sub(b, a)
      let (w, h, d) = c
      (
        bottom-left: a,
        bottom: vector.add(a, (w / 2, 0, d / 2)),
        bottom-right: vector.add(a, (w, 0, d)),
        top-left: vector.sub(b, (w, 0, d)),
        top: vector.sub(b, (w / 2, 0, d / 2)),
        top-right: b,
        left: vector.add(a, (0, h / 2, d / 2)),
        right: vector.sub(b, (0, h / 2, d / 2)),
        center: vector.add(a, (w / 2, h / 2, d / 2)),
      )
    },
    render: (ctx, a, b) => {
      let style = styles.resolve(ctx.style, style, root: "rect")
      let (x1, y1, z1) = a
      let (x2, y2, z2) = b
      cmd.path(close: true, fill: style.fill, stroke: style.stroke,
              ("line", (x1, y1, z1), (x2, y1, z2),
                       (x2, y2, z2), (x1, y2, z1)))
    },
  ),)
}

/// Draw an arc
///
/// *Style root:* `arc`.
///
/// Exactly two arguments of `start`, `stop` and `delta` must be set to a value other
/// than `auto`. You can set the radius of the arc by setting the `radius` style option, which accepts a `float` or tuple of floats for setting the x/y radius.
/// You can set the arcs draw mode using the style `mode`, which accepts the
/// values `"PIE"`, `"CLOSE"` and `"OPEN"` (default). If set to `"PIE"`, the first and
/// last points of the arc's path are it's center. If set to `"CLOSE"`, the path is closed.
///
/// The arc curve is approximated using 1-4 cubic bezier curves.
///
/// - position (coordinate): Start coordinate
/// - start (auto,angle): Start angle
/// - stop (auto,angle): End angle
/// - delta (auto,angle): Angle delta
/// - name (none,string): Element name
/// - anchor (none,string): Element anchor
/// - ..style (style): Style
#let arc(position, start: auto, stop: auto, delta: auto, name: none, anchor: none, ..style) = {
  // Start, stop, delta check
  assert((start, stop, delta).filter(it => {it == auto}).len() == 1,
         message: "Exactly two of three options start, stop and delta should be defined.")

  // No extra positional arguments from the style sink
  assert.eq(style.pos(), (),
            message: "Unexpected positional arguments: " + repr(style.pos()))
  let style = style.named()

  // Coordinate check
  let t = coordinate.resolve-system(position)

  let start-angle = if start == auto {stop - delta} else {start}
  let stop-angle = if stop == auto {start + delta} else {stop}
  ((
    name: name,
    anchor: anchor,
    default-anchor: "start",
    coordinates: (position,),
    custom-anchors-ctx: (ctx, position) => {
      let style = styles.resolve(ctx.style, style, root: "arc")
      let (x, y, z) = position
      let (rx, ry) = util.resolve-radius(style.radius)
        .map(util.resolve-number.with(ctx))
      (
        start: position,
        end: (
          x - rx*calc.cos(start-angle) + rx*calc.cos(stop-angle),
          y - ry*calc.sin(start-angle) + ry*calc.sin(stop-angle),
          z,
        ),
        origin: (
          x - rx*calc.cos(start-angle),
          y - ry*calc.sin(start-angle),
          z,
        )
      )
    },
    render: (ctx, position) => {
      let style = styles.resolve(ctx.style, style, root: "arc")
      let (rx, ry) = util.resolve-radius(style.radius)
        .map(util.resolve-number.with(ctx))

      let (x, y, z) = position
      cmd.arc(x, y, z, start-angle, stop-angle, rx, ry,
        mode: style.mode, fill: style.fill, stroke: style.stroke)
    }
  ),)
}

/// Draw a circle or an ellipse
///
/// *Style root:* `circle`.
///
/// The ellipses radii can be specified by its style field `radius`, which can be of
/// type `float` or a tuple of two `float`'s specifying the x/y radius. 
///
/// - center (coordinate): Center coordinate
/// - name (string): Element name
/// - anchor (string): Element anchor
/// - ..style (style): Style
#let circle(center, name: none, anchor: none, ..style) = {
  // No extra positional arguments from the style sink
  assert.eq(style.pos(), (), message: "Unexpected positional arguments: " + repr(style.pos()))
  let style = style.named()

  // Coordinate check
  let t = coordinate.resolve-system(center)
  ((
    name: name,
    coordinates: (center, ),
    anchor: anchor,
    render: (ctx, center) => {
      let style = styles.resolve(ctx.style, style, root: "circle")
      let (x, y, z) = center
      let (rx, ry) = util.resolve-radius(style.radius).map(util.resolve-number.with(ctx))
      cmd.ellipse(x, y, z, rx, ry, fill: style.fill, stroke: style.stroke)
    }
  ),)
}

/// Execute callback for each anchor with the name of the anchor
///
/// The position of the anchor is set as the current position.
///
/// - node-prefix (string): Anchor node name
/// - callback (function): Callback of the form `anchor-name => elements`
///
/// Example:
///   `for-each-anchor("my-node", (name) => { content((), [#name]) })`
#let for-each-anchor(node-prefix, callback) = {
  ((
    children: (ctx) => {
      let names = ctx.nodes.at(node-prefix).at("anchors", default: (:))
      for (name, _) in names {
        move-to(node-prefix + "." + name)
        callback(name)
      }
    },
  ),)
}

/// Draw a circle through three points
///
/// *Style root:* `circle`.
///
/// *Anchors:*
///   - a -- Point a
///   - b -- Point b
///   - c -- Point c
///   - center -- Calculated center
///
/// - a (coordinate): Point 1
/// - b (coordinate): Point 2
/// - c (coordinate): Point 3
/// - name (string): Element name
/// - anchor (string): Element name
#let circle-through(a, b, c, name: none, anchor: none, ..style) = {
  ((
    name: name,
    anchor: anchor,
    coordinates: (a, b, c),
    transform-coordinates: (ctx, a, b, c) => {
      let center = util.calculate-circle-center-3pt(a, b, c)
      assert(center != none, message: "Could not calculate circle center")

      (a, b, c, center)
    },
    custom-anchors: (a, b, c, center) => {
      (a: a, b: b, c: c, center: center)
    },
    render: (ctx, a, b, c, center) => {
      let style = styles.resolve(ctx.style, style.named(), root: "circle")

      let (x, y, ..) = center
      let r = vector.dist(a, (x, y, 0))

      cmd.ellipse(x, y, 0, r, r, fill: style.fill, stroke: style.stroke)
    }
  ),)
}

/// Render content
///
/// *Style root:* `content`.
///
/// *Style keys:*
///   / padding (`float`): Set vertical and horizontal padding
///   / frame (`string`, `none`): Set frame style (`none`, `"rect"`, `"circle"`)
///                               The frame inherits the `stroke` and `fill` style.
///
/// NOTE: Content itself is not transformed by the canvas transformations!
///       native transformation matrix support from typst would be required.
///
/// The following positional arguments are supported:
///   / `coordinate`, `content`: Place content at coordinate
///   / `coordinate` a, `coordinate` b, `content`: Place content in rect between a and b
///
/// - angle (angle,coordinate): Rotation angle or coordinate relative to the first
///                             coordinate used for angle calculation
/// - anchor (string): Anchor to use as origin. Defaults to `"center"` if one coordinate
///                    is set or `"top-left"` if two coordinates are set.
/// - name (string): Node name
/// - clip (bool): Clip content inside rect
/// - ..style-args (coordinate,content,style): Named arguments are used for for styling
///     while positional args can be of `coordinate` or `content`, see the description
///     above.
#let content(angle: 0deg,
             clip: false,
             anchor: none,
             name: none,
             ..style-args) = {
  let args = style-args.pos()
  let style = style-args.named()
  
  let (a, b, ct) = (none, auto, none)
  if args.len() == 2 {
    (a, ct) = args
  } else if args.len() == 3 {
    (a, b, ct) = args
  } else {
    panic("Invalid arguments to content. Expecting 2 or 3 argumnents, got " +
          str(args.len))
  }

  let _ = coordinate.resolve-system(a)

  assert(b != none)
  let auto-size = b == auto
  if not auto-size {
    let _ = coordinate.resolve-system(b)
  } else {
    b = a
  }

  let c = a
  if type(angle) != typst-angle {
    c = angle
    let _ = coordinate.resolve-system(c)
  }

  let get-angle(a, b) = {
    if type(angle) != typst-angle {
      return vector.angle2(a, b)
    }
    return angle
  }

  let frame-fns = (
    rect: (ctx, style, center, tl, tr, bl, br) => {
      cmd.path(("line", tl, tr, br, bl), close: true,
        stroke: style.stroke, fill: style.fill)
      },
    circle: (ctx, style, center, tl, tr, bl, br) => {
      let (x, y, z) = util.calculate-circle-center-3pt(tl, bl, br)
      let r = vector.dist((x, y, z), tl)
      cmd.ellipse(x, y, z, r, r,
        stroke: style.stroke, fill: style.fill)
      },
  )

  ((
    name: name,
    coordinates: (a, b, c),
    anchor: anchor,
    default-anchor: if auto-size { "center" } else { "top-left" },
    transform-coordinates: (ctx, a, b, c) => {
      let style = styles.resolve(ctx.style, style, root: "content")
      let padding = util.resolve-number(ctx, style.padding)
      let angle = get-angle(a, c)
      let (w, h, ..) = if auto-size {
        measure(ct, ctx)
      } else {
        vector.sub(b, a)
      }
      w = calc.abs(w) + 2 * padding
      h = calc.abs(h) + 2 * padding
      let x-dir = vector.scale((calc.cos(angle), -calc.sin(angle), 0), w/2)
      let y-dir = vector.scale((calc.sin(angle), calc.cos(angle), 0), h/2)
      let tr-dir = vector.add(x-dir, y-dir)
      let tl-dir = vector.sub(x-dir, y-dir)

      let center = if auto-size {
        a
      } else {
        vector.add(a, (w / 2, -h / 2, 0))
      }

      return (
        center, // center
        vector.sub(center, tl-dir), // tl
        vector.add(center, tr-dir), // tr
        vector.sub(center, tr-dir), // bl
        vector.add(center, tl-dir), // br
        vector.sub(center, x-dir), // left
        vector.add(center, x-dir), // right
        vector.sub(center, y-dir), // bottom
        vector.add(center, y-dir), // top
      )
    },
    custom-anchors-ctx: (ctx, center, tl, tr, bl, br, left, right, bottom, top) => {
      return (
        center:       center,
        bottom:       bottom,
        below:        bottom,
        top:          top,
        above:        top,
        left:         left,
        right:        right,
        bottom-left:  bl,
        top-right:    tr,
        bottom-right: br,
        top-left:     tl,
      )
    },
    render: (ctx, center, tl, tr, bl, br, l, r, b, t) => {
      if vector.dist(l, r) == 0 or vector.dist(t, b) == 0 {
        return ()
      }

      let (x, y, ..) = center 
      let style = styles.resolve(ctx.style, style, root: "content")
      let padding = util.resolve-number(ctx, style.padding)
      let angle = get-angle(tl, tr)
      let (tw, th, ..) = if auto-size {
        measure(ct, ctx)
      } else {
        (vector.len(vector.sub(r, l)),
         vector.len(vector.sub(b, t)), 0)
      }
      let w = (calc.abs(calc.sin(angle) * th) +
               calc.abs(calc.cos(angle) * tw)) + padding * 2
      let h = (calc.abs(calc.cos(angle) * th) +
               calc.abs(calc.sin(angle) * tw)) + padding * 2

      let ct = if auto-size {
        let (width: width, height: height) = typst-measure(ct, ctx.typst-style)
        block(width: width,
              height: height,
              inset: 0cm,
              outset: 0cm,
              ct)
      } else {
        block(width: tw * ctx.length,
              height: th * ctx.length,
              ct)
      }

      let frame-fn = if style.frame != none {
        frame-fns.at(style.frame, default: none)
      }
      if frame-fn != none {
        frame-fn(ctx, style, center, tl, tr, bl, br)
      }

      let (width: width, height: height) = typst-measure(ct, ctx.typst-style)
      cmd.content(
        x,
        y,
        w,
        h,
        move(
          dx: -width/2,
          dy: -height/2,
          typst-rotate(angle, ct, origin: typst-center + horizon)
        )
      )
    }
  ),)
}

// Helper function for rendering marks for a cubic bezier
#let _render-cubic-marks(start, end, c1, c2, style) = {
  if style.mark != none {
    let style = style.mark
    let offset = 0.001
    if style.start != none {
      let dir = vector.scale(vector.norm(
        vector.sub(cubic-point(start, end, c1, c2, 0 + offset),
                   start)), style.size)
      cmd.mark(vector.sub(start, dir), start, style.start,
        fill: style.fill, stroke: style.stroke)
    }
    if style.end != none {
      let dir = vector.scale(vector.norm(
        vector.sub(cubic-point(start, end, c1, c2, 1 - offset),
                   end)), style.size)
      cmd.mark(vector.add(end, dir), end, style.end,
        fill: style.fill, stroke: style.stroke)
    }
  }
}

/// Draw a quadratic or cubic bezier line
///
/// *Style root:* `bezier`.
///
/// *Anchors:*
///   - start    -- First coordinate
///   - end      -- Last coordinate
///   - ctrl-(n) -- Control point (n)
///
/// - start (coordinate): Start point
/// - end (coordinate): End point
/// - ..ctrl-style (coordinate,style): Control points or Style attributes
/// - name (string): Element name
#let bezier(start, end, ..ctrl-style, name: none) = {
  // Extra positional arguments are treated like control points.
  let (ctrl, style) = (ctrl-style.pos(), ctrl-style.named())

  // Control point check
  let len = ctrl.len()
  assert(len in (1, 2), message: "Bezier curve expects 1 or 2 control points. Got " + str(len))
  let coordinates = (start, end, ..ctrl)

  // Coordinates check
  let t = coordinates.map(coordinate.resolve-system)
  return ((
    name: name,
    coordinates: (start, end, ..ctrl),
    transform-coordinates: (ctx, s, e, ..ctrl) => {
      let ctrl = ctrl.pos()
      if ctrl.len() == 1 {
        return quadratic-to-cubic(s, e, ..ctrl)
      }
      return (s, e, ..ctrl)
    },
    custom-anchors: (start, end, ..ctrl) => {
      let a = (start: start, end: end)
      for (i, c) in ctrl.pos().enumerate() {
        a.insert("ctrl-" + str(i), c)
      }
      return a
    },
    render: (ctx, start, end, c1, c2) => {
      let style = styles.resolve(ctx.style, style, root: "bezier")
      cmd.path(
        ("cubic", start, end, c1, c2),
        fill: style.fill, stroke: style.stroke
      )
      _render-cubic-marks(start, end, c1, c2, style)
    }
  ),)
}

/// Draw a quadratic bezier from a to c through b
///
/// *Style root:* `bezier`.
///
/// - s (coordinate): Start point
/// - b (coordinate): Passthrough point
/// - e (coordinate): End point
/// - name (string): Element name
/// - ..style (style): Style
#let bezier-through(s, b, e, name: none, ..style) = {
  ((
    name: name,
    coordinates: (s, b, e),
    transform-coordinates: (ctx, s, b, e) => {
      cubic-through-3points(s, b, e)
    },
    custom-anchors: (s, e, ..c) => {
      let anchors = (start: s, end: e)
      for (i, ctrl) in c.pos().enumerate() {
        anchors.insert("ctrl-" + str(i + 1), ctrl)
      }
      return anchors
    },
    render: (ctx, s, e, ..c) => {
      let style = styles.resolve(ctx.style, style.named(), root: "bezier")

      let c = c.pos()
      cmd.path(("cubic", s, e, ..c),
               fill: style.fill,
               stroke: style.stroke)
      _render-cubic-marks(s, e, ..c, style)
    }
  ),)
}

/// Create anchors along a path
///
/// NOTE: This function is supposed to be replaced by a
///       new coordinate syntax!
///
/// - path (path): Path
/// - ..anchors (positional): List of dictionaries of the format:
///   `(name: string, pos: float)`, where pos is in range [0, 1].
/// - name (string): Element name, uses paths name, if auto
#let place-anchors(path, ..anchors, name: auto) = {
  let name = if name == auto and "name" in path.first() {
    path.first().name
  } else {
    name
  }
  assert(type(name) == str, message: "Name must be of type string")

  ((
    name: name,
    children: path,
    custom-anchors-drawables: (drawables) => {
      if drawables.len() == 0 { return () }

      let out = (:)
      let s = drawables.first().segments
      for a in anchors.pos() {
        assert("name" in a, message: "Anchor must have a name set")
        out.insert(a.name, path-util.point-on-path(s, a.pos))
      }
      return out
    },
  ),)
}

/// NOTE: This function is supposed to be removed!
///
/// Put marks on a path
///
/// - path (path): Path
/// - ..marks-style (positional,named): Array of dictionaries of the format:
///     (mark: string,    Mark symbol
///      pos: float,      Position between 0 and 1
///      name: string?    Optional anchor name
///      scale: float?,   Optional scale
///      stroke: stroke?, Optional stroke style
///      fill: fill?)     Optional fill style
///   and style keys.
#let place-marks(path,
                 ..marks-style,
                 name: none) = {
((
  name: name,
  children: path,
  custom-anchors-drawables: (drawables) => {
    if drawables.len() == 0 { return () }

    let s = drawables.first().segments
    let anchors = (
      start: path-util.point-on-path(s, 0),
      end: path-util.point-on-path(s, 1))
    for m in marks-style.pos() {
      if "name" in m {
        anchors.insert(m.name, path-util.point-on-path(s, m.pos))
      }
    }
    return anchors
  },
  finalize-children: (ctx, children) => {
    let style = styles.resolve(ctx.style, marks-style.named(), root: "mark")

    let p = children.first()
    (p,);

    for m in marks-style.pos() {
      let size = m.at("size", default: style.size)
      let fill = m.at("fill", default: style.fill)
      let stroke = m.at("stroke", default: style.stroke)

      let (pt, dir) = path-util.direction(p.segments, m.pos,
                                          scale: size)
      if pt != none {
        cmd.mark(vector.add(pt, dir), pt, m.mark,
                 fill: fill,
                 stroke: stroke)
      }
    }
  }
),)
}

/// Emit one anchor per intersection of all elements
/// inside body.
///
/// - body (elements): Element body
/// - name (string): Element name
/// - samples (int): Number of samples to use for linearizing curves.
///                  Raising this gives more precision but slows down
///                  calculation.
#let intersections(body, name: none, samples: 10) = {
  assert(name != none, message: "Intersection element name must be set")
  samples = calc.min(calc.max(2, samples), 2500)
  ((
    name: name,
    children: body,
    add-default-anchors: false,
    custom-anchors-drawables: (children) => {
      if children.len() == 0 { return () }

      let pts = ()

      let anchors = (:)
      for i in range(children.len()) {
        for j in range(i + 1, children.len()) {
          if i != j {
            let isect = intersection.path-path(children.at(i),
                                               children.at(j),
                                               samples: samples)
            for pt in isect {
              if not pt in pts { pts.push(pt) }
            }
          }
        }
      }

      for pt in pts {
        anchors.insert(str(anchors.len()), pt)
      }
      return anchors
    },
  ),)
}

/// Merge multiple paths
///
/// - body (any): Body
/// - close (bool): If true, the path is automatically closed
/// - name (string): Element name
#let merge-path(body, close: false, name: none, ..style) = {
  // No extra positional arguments from the style sink
  assert.eq(style.pos(), (),
            message: "Unexpected positional arguments: " + repr(style.pos()))
  let style = style.named()
  ((
    name: name,
    children: body,
    finalize-children: (ctx, children) => {
      let segments = ()
      let pos = none

      let segment-begin = (s) => {
        return s.at(1)
      }

      let segment-end = (s) => {
        let type = s.at(0)
        if type == "line" {
          return s.last()
        } else {
          return s.at(2)
        }
      }

      while children.len() > 0 {
        
        let child = children.remove(0)
        assert("segments" in child,
                message: "Object must contain path segments")
        if child.segments.len() == 0 { continue }

        // Revert path order, if end < start
        //if segments.len() > 0 {
        //  if (vector.dist(segment-end(child.segments.last()), pos) <
        //      vector.dist(segment-begin(child.segments.first()), pos)) {
        //     child.segments = child.segments.rev()
        //  }
        //}

        // Connect "jumps" with linear lines to prevent typsts path impl.
        // from using weird cubic ones.
        if segments.len() > 0 {
          let end = segment-end(segments.last())
          let begin = segment-begin(child.segments.first())
          if vector.dist(end, begin) > 0 {
            segments.push(("line", segment-begin(child.segments.first())))
          }
        }

        // Append child
        segments += child.segments

        // Sort next children by distance
        pos = segment-end(segments.last())
        children = children.sorted(key: a => {
          return vector.len(vector.sub(segment-begin(a.segments.first()), pos))
        })
      }
      
      let style = styles.resolve(ctx.style, style)
      cmd.path(..segments, close: close, stroke: style.stroke, fill: style.fill)
    }
  ),)
}

/// Render shadow of children by rendering them twice
///
/// *Style root:* `shadow`.
///
/// - body (canvas): Child elements
/// - ..style (style): Style
#let shadow(body, ..style) = {
  // No extra positional arguments from the style sink
  assert.eq(style.pos(), (), message: "Unexpected positional arguments: " + repr(style.pos()))
  let style = style.named()
  ((
    children: ctx => {
      let style = styles.resolve(ctx.style, style, root: "shadow")
      return (
      ..group({
        set-style(fill: style.color, stroke: style.color)
        translate((style.offset-x, style.offset-y, 0))
        body
      }),
      ..body,
      )
    },
  ),)
}

/// Draw a grid
///
/// *Style root:* `grid`.
///
/// - from (coordinate): Start point
/// - to (coordinate): End point
/// - step (float,dictionary): Distance between grid lines. If passed a
///                            dictionary, $x$ and $y$ step can be set via the
///                            keys `x` and `y` (`(x: <step>, y: <step>)`).
/// - name (string): Element name
/// - help-lines (bool): Styles the grid using thin gray lines
/// - ..style (style): Style
#let grid(from, to, step: 1, name: none, help-lines: false, ..style) = {
  let t = (from, to).map(coordinate.resolve-system)
  ((
    name: name,
    coordinates: (from, to),
    render: (ctx, from, to) => {
      let style = styles.resolve(ctx.style, style.named())
      let stroke = if help-lines {
        0.2pt + gray
      } else {
        style.stroke
      }
      let (x-step, y-step) = if type(step) == dictionary {
        (
          if "x" in step {step.x} else {1},
          if "y" in step {step.y} else {1},
        )
      } else {
        (step, step)
      }.map(util.resolve-number.with(ctx))

      if x-step != 0 {
        for x in range(int((to.at(0) - from.at(0)) / x-step)+1) {
          x *= x-step
          x += from.at(0)
          cmd.path(("line", (x, from.at(1)), (x, to.at(1))), fill: style.fill, stroke: style.stroke)
        }
      }

      if y-step != 0 {
        for y in range(int((to.at(1) - from.at(1)) / y-step)+1) {
          y *= y-step
          y += from.at(1)
          cmd.path(("line", (from.at(0), y), (to.at(0), y)), fill: style.fill, stroke: style.stroke)
        }
      }
    }
  ),)
}
