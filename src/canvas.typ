#import "version.typ"
#import "drawable.typ"
#import "vector.typ"
#import "matrix.typ"
#import "util.typ"
#import "path-util.typ"
#import "aabb.typ"
#import "styles.typ"
#import "process.typ"
#import "coordinate.typ"

/// Returns an empty context object usable for calling cetz internal functions
/// outsides a canvas.
///
/// - length (length): Used to specify what 1 coordinate unit is.
/// - x (number, vector) = 1.0: Sets up the x vector of the coordinate system to `(x, 0, 0)` or to the given vector.
/// - y (number, vector) = 1.0: Sets up the y vector of the coordinate system to `(0, y, 0)` or to the given vector.
/// - z (number, vector) = 1.0: Sets up the z vector of the coordinate system to `(0, 0, z)` or to the given vector.
/// -> context
#let make-ctx(length: 1cm, x: 1.0, y: 1.0, z: 1.0) = {
  if type(length) != std.length {
    panic("Expected `length` to be of type length, got " + repr(length))
  }

  let length = if length.em != 0 {
    length.to-absolute()
  } else {
    length
  }
  assert(length / 1cm != 0, message: "Canvas length must be != 0!")

  // Prepare the coordinate system
  let resolve-number(x) = {
    return if type(x) == std.length {
      x / length
    } else {
      float(x)
    }
  }
  let x = (if type(x) != array { (x, 0.0, 0.0) } else { x }).map(resolve-number)
  let y = (if type(y) != array { (0.0, y, 0.0) } else { y }).map(resolve-number)
  let z = (if type(z) != array { (0.0, 0.0, z) } else { z }).map(resolve-number)

  return (
    version: version.version,
    length: length,
    debug: false,
    background: none,
    // Previous element position & bbox
    prev: (pt: (0.0, 0.0, 0.0)),
    style: styles.default,
    // Current transformation matrix
    transform:
      ((x.at(0, default: 1.0), y.at(0, default: 0.0), z.at(0, default: 0.0), 0.0),
       (x.at(1, default: 0.0), y.at(1, default: 1.0), z.at(1, default: 0.0), 0.0),
       (x.at(2, default: 0.0), y.at(2, default: 0.0), z.at(2, default: 1.0), 0.0),
       (0.0, 0.0, 0.0, 1.0)),
    // Nodes, stores anchors and paths
    nodes: (:),
    // Group stack
    groups: (),
    // User defined marks
    marks: (
      mnemonics: (:),
      marks: (:),
    ),
    // coordinate resolver
    resolve-coordinate: (),
    // Shared state that is not scoped by group/scope elements.
    // CeTZ itself does not use this dictionary for data.
    shared-state: (:),
  )
}

// Filters hidden drawables and orders the drawables by z-index. Also
// collects the bodies of content drawables. Separate function so that the
// result is cached across canvas re-evaluations.
#let _prepare-drawables(drawables) = {
  let has-tags = false
  let has-z-index = false
  for d in drawables {
    if d.at("tags", default: ()) != () { has-tags = true }
    if "z-index" in d { has-z-index = true }
  }
  if has-tags {
    drawables = drawable.filter-tagged(drawables, drawable.TAG.hidden)
  }

  // Order draw commands by z-index (sorting is stable, so it is a no-op
  // if no drawable has a z-index set)
  if has-z-index {
    drawables = drawables.sorted(key: (cmd) => {
      return cmd.at("z-index", default: 0)
    })
  }

  let bodies = ()
  for d in drawables {
    if d.type == "content" { bodies.push(d.body) }
  }
  (drawables, bodies)
}

// Renders a list of drawables to content. This function does not depend on
// the context; content sizes must be passed via `sizes` (one entry per
// content drawable, in order).
#let _render-drawables(drawables, bounds, offset-x, offset-y, length, sizes) = {
  let content-index = 0
  for drawable in drawables {
    if drawable.type == "path" {
      // Typst path elements have strange bounding boxes. We need to
      // offset all paths to start at (0, 0) to make gradients work.
      //
      // Single pass: check for straight lines only and compute the
      // min x / max y (equivalent to `aabb.aabb(path-util.bounds(...))`
      // in that case).
      let only-lines = true
      let (lx, hy, ..) = drawable.segments.first().first()
      for (origin, _, segments) in drawable.segments {
        let (x, y, ..) = origin
        if x < lx { lx = x }
        if hy < y { hy = y }
        for seg in segments {
          if seg.first() != "l" { only-lines = false; break }
          for pt in seg.slice(1) {
            let (x, y, ..) = pt
            if x < lx { lx = x }
            if hy < y { hy = y }
          }
        }
        if not only-lines { break }
      }
      let (low-x, high-y) = if only-lines {
        (float(lx), float(hy))
      } else {
        let path-bounds = aabb.aabb(path-util.bounds(drawable.segments))
        (path-bounds.low.at(0), path-bounds.high.at(1))
      }
      let segment-x = low-x - bounds.low.at(0)
      let segment-y = bounds.high.at(1) - high-y

      let vertices = ()
      for (origin, closed, segments) in drawable.segments {
        let (x, y, ..) = origin
        vertices.push(curve.move((( x - offset-x - segment-x) * length,
                                  (-y - offset-y - segment-y) * length)))

        for seg in segments {
          let kind = seg.first()
          if kind == "l" {
            for pt in seg.slice(1) {
              let (x, y, ..) = pt
              vertices.push(curve.line((( x - offset-x - segment-x) * length,
                                        (-y - offset-y - segment-y) * length)))
            }
          } else if kind == "c" {
            vertices.push(curve.cubic(..seg.slice(1).map(((x, y, ..)) => (
              ( x - offset-x - segment-x) * length,
              (-y - offset-y - segment-y) * length))))
          } else {
            panic(kind, seg.slice(1))
          }
        }

        if closed {
          vertices.push(curve.close(mode: "straight"))
        }
      }

      if type(drawable.stroke) == dictionary and "thickness" in drawable.stroke and type(drawable.stroke.thickness) != std.length {
        drawable.stroke.thickness *= length
      }
      place(top + left, float: false, std.curve(
        stroke: drawable.stroke,
        fill: drawable.fill,
        fill-rule: drawable.at("fill-rule", default: "non-zero"),
        ..vertices,
      ), dx: segment-x * length, dy: segment-y * length)
    } else if drawable.type == "content" {
      let (width, height) = sizes.at(content-index)
      content-index += 1
      place(top + left, float: false, move(
        dx: ( drawable.pos.at(0) - offset-x) * length - width / 2,
        dy: (-drawable.pos.at(1) - offset-y) * length - height / 2,
        drawable.body,
      ), dx: 0 * length, dy: 0 * length)
    } else {
      place(top + left, float: false, none, dx: 0 * length, dy: 0 * length)
    }
  }
}

/// Sets up a canvas for drawing on.
///
/// - length (length): Used to specify what 1 coordinate unit is. Note that ratios are no longer supported! You can wrap the canvas into a `layout(ly => canvas(length: ly.width * <ratio>, ...))`.
/// - baseline (none,number,coordinate): Specifies the coordinate to use as the baseline. Setting this the canvas behaves like a `box` element instead of a `block`.
/// - body (none, array, element): A code block in which functions from the `draw` module have been called.
/// - background (none, color): A color to be used for the background of the canvas.
/// - stroke (none, stroke): Stroke style to apply to the canvas top-level element (box or block)
/// - padding (none, number, array, dictionary) = none: How much padding to add to the canvas. `none` applies no padding. A number applies padding to all sides equally. A dictionary applies padding following Typst's `pad` function: https://typst.app/docs/reference/layout/pad/. An array follows CSS like padding: `(y, x)`, `(top, x, bottom)` or `(top, right, bottom, left)`.
/// - x (number, vector) = 1.0: Sets up the x vector of the coordinate system to `(x, 0, 0)` or to the given vector.
/// - y (number, vector) = 1.0: Sets up the y vector of the coordinate system to `(0, y, 0)` or to the given vector.
/// - z (number, vector) = 1.0: Sets up the z vector of the coordinate system to `(0, 0, z)` or to the given vector.
/// - debug (bool): Shows the bounding boxes of each element when `true`.
/// -> content
#let canvas(length: 1cm, x: 1.0, y: 1.0, z: 1.0, baseline: none, debug: false, background: none, stroke: none, padding: none, body) = context {
  if body == none {
    return []
  }
  if type(body) != array {
    panic("Incorrect type for body: " + repr(type(body)))
  }

  let ctx = make-ctx(length: length, x: x, y: y, z: z)
  ctx.debug = debug
  ctx.background = background

  let (ctx, bounds, drawables) = process.many(ctx, body)
  if bounds == none {
    return []
  }

  // Filter hidden drawables and order by z-index.
  let bodies
  (drawables, bodies) = _prepare-drawables(drawables)

  // Apply padding
  let padding = util.map-dict(util.as-padding-dict(padding), (_, v) => {
    util.resolve-number(ctx, v)
  })
  let swapped-padding = padding
  swapped-padding.top = padding.bottom
  swapped-padding.bottom = padding.top
  bounds = aabb.padded(bounds, swapped-padding)

  // Final canvas size
  let (width, height, ..) = vector.scale(aabb.size(bounds), length)

  let (offset-x, offset-y, ..) = bounds.low
  offset-y = -offset-y - height / length

  // The top-level function the canvas gets wrapped in
  let container-fn = block.with(breakable: false)

  // Compute the baseline offset
  let baseline-offset = 0cm
  if baseline != none {
    if type(baseline) in (int, float, length) {
      baseline = (0, baseline)
    }

    let sub-ctx = ctx
    sub-ctx.transform = matrix.ident(4)

    let (_, (x, y, _)) = coordinate.resolve(sub-ctx, baseline)
    baseline-offset = length * (-y - offset-y) - height

    container-fn = box.with(baseline: -baseline-offset)
  }

  // Measure content drawables here (this depends on the context), so that
  // the rendering of all drawables can be done by a context-independent
  // (and thus well cacheable) function.
  let sizes = ()
  for body in bodies {
    let (width, height) = std.measure(body)
    sizes.push((width, height))
  }

  (container-fn)(width: width, height: height, stroke: stroke, fill: background,
    align(top, _render-drawables(drawables, bounds, offset-x, offset-y, length, sizes)))
}
