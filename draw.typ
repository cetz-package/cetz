#import "vector.typ"
#import "matrix.typ"
#import "cmd.typ"
#import "util.typ"
#import "path-util.typ"
#import "coordinate.typ"
#import "bezier.typ": to-abc, quadratic-through-3points, cubic-through-3points
// #import "collisions.typ"
#import "styles.typ"

#let typst-rotate = rotate
#let typst-measure = measure

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
/// - param (coordinate): Coordinate to move to
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
/// - angle (angle,dictionary): Angle (z-axis) or dictionary of the
///                             form `(x: <angle>, y: <angle>, z: <angle>)`
///                             specifying per axis rotation angle.
#let rotate(angle) = {
  let resolve-angle(angle) = {
    return if type(angle) == "angle" {
      matrix.transform-rotate-z(-angle)
    } else if type(angle) == "dictionary" {
      matrix.transform-rotate-xyz(
          -angle.at("x", default: 0deg),
          -angle.at("y", default: 0deg),
          -angle.at("z", default: 0deg),
        )
    } else {
      panic("Invalid angle format '" + repr(angle) + "'")
    }
  }

  let needs-resolve = (type(angle) == "array" and
                       type(angle.first()) == "function")
  return ((
    push-transform: if needs-resolve { 
      ctx => matrix.mul-mat(ctx.transform, resolve-angle(
        coordinate.resolve-function(coordinate.resolve, ctx, angle)))
    } else {
      resolve-angle(angle)
    }
  ),)
}

/// Push scale matrix
///
/// World = World * Scale
///
/// - factor (float,dictionary): Scaling factor for all axes or per axis scaling
///                              factor dictionary.
#let scale(factor) = ((
  push-transform: matrix.transform-scale(factor)
),)

/// Push translation matrix
///
/// World = Translation * World
///
/// - vec (vector,dictionary): Translation vector
/// - pre (bool): Matrix multiplication order
///               - false: World = World * Translate
///               - true:  World = Translate * World
#let translate(vec, pre: true) = {
  let resolve-vec(vec) = {
    let (x,y,z) = if type(vec) == "dictionary" {
      (
        vec.at("x", default: 0),
        vec.at("y", default: 0),
        vec.at("z", default: 0),
      )
    } else if type(vec) == "array" {
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

  let needs-resolve = type(vec) == "array" and type(vec.first()) == "function"
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

/// Push a group
///
/// A group has a local transformation matrix.
/// Groups can be used to get an elements bounding box, as they
/// set default anchors (top, top-left, ..) to the bounding box of
/// their children.
///
/// - name (string): Element name
/// - anchor (string): Element origin
/// - body (draw,function): Children or function of the form (ctx => array)
#let group(name: none, anchor: none, body) = {
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

/// Draw a mark between two coordinates
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

/// Draw a poly-line
///
/// Style root: `line`.
/// Anchors:
///   - start -- First coordinate
///   - end   -- Last coordinate
///
/// - ..pts (coordinate): Points
/// - ..style (style): Style
/// - close (bool): Close path
/// - name (string): Element name
#let line(..pts-style, close: false, name: none) = {
  // Extra positional arguments from the pts-style
  // sink are interpreted as coordinates.
  let (pts, style) = (pts-style.pos(), pts-style.named())

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
/// Style root: `rect`.
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

/// Draw ellipse
///
/// Style root: `circle`.
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
/// - callback (function): Callback (anchor-name) => cmd
///
/// Example:
///   for-each-anchor("my-node", (name) => { content((), [#name]) })
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

/// Draw circle through three points
///
/// Style root: `circle`.
/// Anchors:
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
    transform-coordinates: (a, b, c) => {
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
/// Style root: `content`.
///
/// NOTE: Content itself is not transformed by the canvas transformations!
///       native transformation matrix support from typst would be required.
///
/// - pt (coordinate): Content coordinate
/// - ct (content): Content
/// - angle (angle,coordinate): Rotation angle or second coordinate to use for
///                             angle calculation
/// - anchor (string): Anchor to use as origin
/// - name (string): Node name
#let content(
  pt,
  ct,
  angle: 0deg,
  anchor: none,
  name: none,
  ..style
  ) = {
  // Angle can be either an angle or a second coordinate
  assert(type(angle) in ("angle", "array"))

  // No extra positional arguments from the style sink
  assert.eq(style.pos(), (), message: "Unexpected positional arguments: " + repr(style.pos()))
  let style = style.named()

  // Coordinate check
  let t = coordinate.resolve-system(pt)

  let pt2 = pt
  if type(angle) != "angle" {
    pt2 = angle
    let t = coordinate.resolve-system(pt2)
  }

  let get-angle(a, b) = {
    if type(angle) != "angle" {
      return vector.angle2(a, b)
    }
    return angle
  }

  ((
    name: name,
    coordinates: (pt, pt2,),
    anchor: anchor,
    default-anchor: "center",
    custom-anchors-ctx: (ctx, pt, pt2) => {
      let style = styles.resolve(ctx.style, style, root: "content")
      let padding = util.resolve-number(ctx, style.padding)
      let angle = get-angle(pt, pt2)
      let (w, h) = measure(ct, ctx)
      let x-dir = vector.scale((calc.cos(angle), -calc.sin(angle), 0), w/2)
      let y-dir = vector.scale((calc.sin(angle), calc.cos(angle), 0), h/2)
      let tr-dir = vector.add(x-dir, y-dir)
      let tl-dir = vector.sub(x-dir, y-dir)

      return (
        center:       pt,
        bottom:       vector.sub(pt, y-dir),
        below:        vector.sub(pt, y-dir),
        top:          vector.add(pt, y-dir),
        above:        vector.add(pt, y-dir),
        left:         vector.sub(pt, x-dir),
        right:        vector.add(pt, x-dir),
        bottom-left:  vector.sub(pt, tr-dir),
        top-right:    vector.add(pt, tr-dir),
        bottom-right: vector.add(pt, tl-dir),
        top-left:     vector.sub(pt, tl-dir),
      )
    },
    render: (ctx, pt, pt2) => {
      let (x, y, ..) = pt
      let style = styles.resolve(ctx.style, style, root: "content")
      let padding = util.resolve-number(ctx, style.padding)
      let angle = get-angle(pt, pt2)
      let (tw, th) = measure(ct, ctx)
      let w = (calc.abs(calc.sin(angle) * th) +
               calc.abs(calc.cos(angle) * tw)) + padding * 2
      let h = (calc.abs(calc.cos(angle) * th) +
               calc.abs(calc.sin(angle) * tw)) + padding * 2

      let (width: width, height: height) = typst-measure(ct, ctx.typst-style)
      cmd.content(
        x,
        y,
        w,
        h,
        move(
          dx: -width/2,
          dy: -height/2,
          typst-rotate(angle, ct)
        )
      )
    }
  ),)
}

/// Draw a quadratic or cubic bezier line
///
/// Style root: `bezier`.
/// Anchors:
///   - start    -- First coordinate
///   - end      -- Last coordinate
///   - ctrl-<n> -- Control point <n>
///
/// - start (coordinate): Start point
/// - end (coordinate): End point
/// - ..ctrl (coordinate): Control points
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
    custom-anchors: (start, end, ..ctrl) => {
      let a = (start: start, end: end)
      for (i, c) in ctrl.pos().enumerate() {
        a.insert("ctrl-" + str(i), c)
      }
      return a
    },
    render: (ctx, start, end, ..ctrl) => {
      let style = styles.resolve(ctx.style, style, root: "bezier")
      ctrl = ctrl.pos()
      cmd.path(
        (if len == 1 { "quadratic" } else { "cubic" }, start, end, ..ctrl),
        fill: style.fill, stroke: style.stroke
      )
    }
  ),)
}

/// Draw a quadratic bezier from a to c through b
///
/// Style root: `bezier`.
///
/// - s (coordinate): Start point
/// - b (coordinate): Passthrough point
/// - e (coordinate): End point
/// - deg (int): Degree (2 or 3) of the bezier curve
/// - name (string): Element name
/// - ..style (style): Style
#let bezier-through(s, b, e, deg: 3, name: none, ..style) = {
  assert(deg in (2, 3), message: "Only beziers of degree 2 or 3 are supported")
  ((
    name: name,
    coordinates: (s, b, e),
    transform-coordinates: (s, b, e) => {
      if deg == 2 {
        quadratic-through-3points(s, b, e)
      } else {
        cubic-through-3points(s, b, e)
      }
    },
    custom-anchors: (s, b, e, ..c) => {
      let anchors = (start: s, end: e)
      for (i, ctrl) in c.pos().enumerate() {
        anchors.insert("ctrl-" + str(i + 1), ctrl)
      }
      return anchors
    },
    render: (ctx, s, e, ..c) => {
      let style = styles.resolve(ctx.style, style.named(), root: "bezier")

      let c = c.pos()
      if c.len() == 1 {
        cmd.path(("quadratic", s, e, ..c),
                 fill: style.fill,
                 stroke: style.stroke)
      } else {
        cmd.path(("cubic", s, e, ..c),
                 fill: style.fill,
                 stroke: style.stroke)
      }
    }
  ),)
}

/// NOTE: This function is supposed to be REPLACED by a
///       new coordinate syntax!
///
/// Create anchors along a path
///
/// - path (path): Path
/// - anchors (positional): Dictionaries of the format:
///     (name: string, pos: float)
/// - name (string): Element name, uses paths name, if auto
#let place-anchors(path, ..anchors, name: auto) = {
  let name = if name == auto and "name" in path.first() {
    path.first().name
  } else {
    name
  }
  assert(type(name) == "string", message: "Name must be of type string")

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
/// - marks (positional): Array of dictionaries of the format:
///     (mark: string,
///      pos: float,
///      scale: float,
///      stroke: stroke,
///      fill: fill)
#let place-marks(path,
                 ..marks,
                 size: auto,
                 fill: none,
                 stroke: black + 1pt,
                 name: none) = {
((
  name: name,
  children: path,
  custom-anchors-drawables: (drawables) => {
    if drawables.len() == 0 { return () }

    let anchors = (:)
    let s = drawables.first().segments
    for m in marks.pos() {
      if "name" in m {
        anchors.insert(m.name, path-util.point-on-path(s, m.pos))
      }
    }
    return anchors
  },
  finalize-children: (ctx, children) => {
    let size = if size != auto { size } else { ctx.style.mark.size }

    let p = children.first()
    (p,);

    for m in marks.pos() {
      let scale = m.at("scale", default: size)
      let fill = m.at("fill", default: fill)
      let stroke = m.at("stroke", default: stroke)

      let (pt, dir) = path-util.direction(p.segments, m.pos, scale: scale)
      if pt != none {
        cmd.mark(vector.add(pt, dir), pt, m.mark, fill: fill, stroke: stroke)
      }
    }
  }
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
/// Style root: `shadow`.
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

// Calculate the intersections of two named paths
// #let intersections(path-1, path-2, name: "intersection") = {
//   ((
//     name: name,
//     custom-anchors-ctx: (ctx) => {
//       let (ps1, ps2) = (path-1, path-2).map(x => ctx.nodes.at(x).paths)
//       let anchors = (:)
//       for p1 in ps1 {
//         for p2 in ps2 {
//           let cs = collisions.poly-poly(p1, p2)
//           if cs != none {
//             for c in cs {
//               anchors.insert(str(anchors.len()+1), util.revert-transform(ctx.transform, c))
//             }
//           }
//         }
//       }
//       anchors
//     },
//   ),)
// }

/// Draw a grid
///
/// Style root: `grid`.
///
/// - from (coordinate): Start point
/// - end (coordinate): End point
/// - step (float,dictionary): Distance between grid lines. If passed a
///                            dictionary, x and y step can be set via the
///                            keys `x` and `y`.
/// - name (string): Element name
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
      let (x-step, y-step) = if type(step) == "dictionary" {
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
