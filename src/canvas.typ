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
  assert(
    type(body) == array,
    message: "Incorrect type for body: " + repr(type(body)),
  )

  // TODO: Remove in later versions
  if type(length) == ratio {
    panic("Canvas relative length support got removed! Wrap your canvas in `layout(ly => canvas(length: <ratio> * ly.width, ...))`")
  }

  assert(type(length) == std.length, message: "Expected `length` to be of type length, got " + repr(length))
  let length = length.to-absolute()
  assert(length / 1cm != 0,
    message: "Canvas length must be != 0!")

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

  let ctx = (
    version: version.version,
    length: length,
    debug: debug,
    background: background,
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

  let (ctx, bounds, drawables) = process.many(ctx, body)
  if bounds == none {
    return []
  }

  // Filter hidden drawables
  drawables = drawable.filter-tagged(drawables, drawable.TAG.hidden)

  // Order draw commands by z-index
  drawables = drawables.sorted(key: (cmd) => {
    return cmd.at("z-index", default: 0)
  })

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

  (container-fn)(width: width, height: height, stroke: stroke, fill: background, align(top, {
    for drawable in drawables {
      // Typst path elements have strange bounding boxes. We need to
      // offset all paths to start at (0, 0) to make gradients work.
      let (segment-x, segment-y, _) = if drawable.type == "path" {
        vector.sub(
          vector.element-product(aabb.aabb(path-util.bounds(drawable.segments)).low, (1, -1, 1)),
          bounds.low)
      } else {
        (0, 0, 0)
      }

      place(top + left, float: false, if drawable.type == "path" {
        let vertices = ()

        let transform-point((x, y, _)) = {
          (( x - offset-x - segment-x) * length,
           (-y - offset-y - segment-y) * length)
        }

        for ((origin, closed, segments)) in drawable.segments {
          vertices.push(curve.move(transform-point(origin)))

          for ((kind, ..args)) in segments {
            if kind == "l" {
              for pt in args {
                vertices.push(curve.line(transform-point(pt)))
              }
            } else if kind == "c" {
              vertices.push(curve.cubic(..args.map(transform-point)))
            } else {
              panic(kind, args)
            }
          }

          if closed {
            vertices.push(curve.close(mode: "straight"))
          }
        }

        if type(drawable.stroke) == dictionary and "thickness" in drawable.stroke and type(drawable.stroke.thickness) != std.length {
          drawable.stroke.thickness *= length
        }
        std.curve(
          stroke: drawable.stroke,
          fill: drawable.fill,
          fill-rule: drawable.at("fill-rule", default: "non-zero"),
          ..vertices,
        )
      } else if drawable.type == "content" {
        let (width, height) = std.measure(drawable.body)
        move(
          dx: ( drawable.pos.at(0) - offset-x) * length - width / 2,
          dy: (-drawable.pos.at(1) - offset-y) * length - height / 2,
          drawable.body,
        )
      }, dx: segment-x * length, dy: segment-y * length)
    }
  }))
}
