#import "matrix.typ"
#import "vector.typ"
#import "util.typ"
#import "path-util.typ"
#import "aabb.typ"
#import "styles.typ"
#import "process.typ"
#import "version.typ"

/// Sets up a canvas for drawing on.
///
/// - length (length, ratio): Used to specify what 1 coordinate unit is. If given a ratio, that ratio is relative to the containing elements width!
/// - body (none, array, element): A code block in which functions from the `draw` module have been called.
/// - background (none, color): A color to be used for the background of the canvas.
/// - padding (none, number, array, dictionary) = none: How much padding to add to the canvas. `none` applies no padding. A number applies padding to all sides equally. A dictionary applies padding following Typst's `pad` function: https://typst.app/docs/reference/layout/pad/. An array follows CSS like padding: `(y, x)`, `(top, x, bottom)` or `(top, right, bottom, left)`.
/// - debug (bool): Shows the bounding boxes of each element when `true`.
/// -> content
#let canvas(length: 1cm, debug: false, background: none, padding: none, body) = context { layout(ly => {
  if body == none {
    return []
  }
  assert(
    type(body) == array,
    message: "Incorrect type for body: " + repr(type(body)),
  )

  assert(type(length) in (std.length, ratio), message: "Expected `length` to be of type length or ratio, got " + repr(length))
  let length = if type(length) == ratio {
    length * ly.width
  } else {
    length.to-absolute()
  }
  assert(length / 1cm != 0,
    message: "Canvas length must be != 0!")

  let ctx = (
    version: version.version,
    length: length,
    debug: debug,
    background: background,
    // Previous element position & bbox
    prev: (pt: (0., 0., 0.)),
    style: styles.default,
    // Current transformation matrix, a rhs coordinate system
    // where z is sheared by a half x and y.
    //   +x = right, +y = up, +z = 1/2 (left + down)
    transform:
      ((1., 0.,-.5, 0.),
       (0.,-1.,+.5, 0.),
       (0., 0., 0., 0.), // FIXME: This should not be zero for Z! Changing it destroys mark & decorations in 3D space.
       (0., 0., 0., 1.)),
    // Nodes, stores anchors and paths
    nodes: (:),
    // Group stack
    groups: (),
    // User defined marks
    marks: (
      mnemonics: (:),
      marks: (:),
    ),
    // Shared state that is not scoped by group/scope elements.
    // CeTZ itself does not use this dictionary for data.
    shared-state: (:),
  )

  let (ctx, bounds, drawables) = process.many(ctx, body)
  if bounds == none {
    return []
  }

  // Filter hidden drawables
  drawables = drawables.filter(d => not d.hidden)

  // Order draw commands by z-index
  drawables = drawables.sorted(key: (cmd) => {
    return cmd.at("z-index", default: 0)
  })

  // Apply padding
  let padding = util.as-padding-dict(padding)
  bounds = aabb.padded(bounds, padding)

  let (offset-x, offset-y, ..) = bounds.low

  // Final canvas size
  let (width, height, ..) = vector.scale(aabb.size(bounds), length)

  let relative = (orig, c) => {
    return vector.sub(c, orig)
  }

  box(width: width, height: height, fill: background, align(top, {
    for drawable in drawables {
      // Typst path elements have strange bounding boxes. We need to
      // offset all paths to start at (0, 0) to make gradients work.
      let (segment-x, segment-y, _) = if drawable.type == "path" {
        vector.sub(
          aabb.aabb(path-util.bounds(drawable.segments)).low,
          bounds.low)
      } else {
        (0, 0, 0)
      }

      place(top + left, float: false, if drawable.type == "path" {
        let vertices = ()

        let transform-point((x, y, _)) = {
          ((x - offset-x - segment-x) * length,
           (y - offset-y - segment-y) * length)
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
          dx: (drawable.pos.at(0) - offset-x) * length - width / 2,
          dy: (drawable.pos.at(1) - offset-y) * length - height / 2,
          drawable.body,
        )
      }, dx: segment-x * length, dy: segment-y * length)
    }
  }))
})}
