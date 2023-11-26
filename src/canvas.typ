// Aliases for typst types/functions
// because we override them.
#let typst-length = length

#import "matrix.typ"
#import "vector.typ"
#import "util.typ"
#import "path-util.typ"
#import "aabb.typ"
#import "styles.typ"
#import "process.typ"

/// Set up a Canvas for drawing
///
/// - length (length,ratio): Used to specify what 1 coordinate unit is. If given a ration, that ratio is
///   relative to the containing elements width!
/// - body (none,array,element): A code block in which functions from `draw.typ` have been called.
/// - background (none,color): A color to be used for the background of the canvas.
/// - debug (bool): Shows the bounding boxes of each element when `true`.
/// -> content
#let canvas(length: 1cm, debug: false, background: none, body) = layout(ly => style(st => {
  if body == none {
    return []
  }
  assert(
    type(body) == array,
    message: "Incorrect type for body: " + repr(type(body)),
  )

  assert(type(length) in (typst-length, ratio), message: "Expected `length` to be of type length or ratio, got " + repr(length))
  let length = if type(length) == ratio {
    length * ly.width
  } else {
    measure(line(length: length), st).width
  }


  let ctx = (
    typst-style: st,
    length: length,
    debug: debug,
    // Previous element position & bbox
    prev: (pt: (0, 0, 0)),
    em-size: measure(box(width: 1em, height: 1em), st),
    style: (:),
    // Current transform
    transform: matrix.mul-mat(
      matrix.transform-shear-z(.5),
      matrix.transform-scale((x: 1, y: -1, z: 1)),
    ),
    // Nodes, stores anchors and paths
    nodes: (:),
    // group stack
    groups: (),
  )

  let (ctx, bounds, drawables) = process.many(ctx, body)


  if bounds == none {
    return []
  }

  // Order draw commands by z-index
  drawables = drawables.sorted(key: (cmd) => {
    return cmd.at("z-index", default: 0)
  })

  // Final canvas size
  let (width, height, ..) = vector.scale(aabb.size(bounds), length)

  let relative = (orig, c) => {
    return vector.sub(c, orig)
  }

  // repr(drawables)

  box(width: width, height: height, fill: background, align(top, {
    for drawable in drawables {
      place(if drawable.type == "path" {
        let vertices = ()
        for s in drawable.segments {
          let type = s.at(0)
          let coordinates = s.slice(1).map(c => {
            return (
              (c.at(0) - bounds.low.at(0)) * length,
              (c.at(1) - bounds.low.at(1)) * length,
              // x * length,
              // y+ bounds.t * length
            )
          })
          assert(
            type in ("line", "cubic"),
            message: "Path segments must be of type line, cubic",
          )

          if type == "cubic" {
            let a = coordinates.at(0)
            let b = coordinates.at(1)
            let ctrla = relative(a, coordinates.at(2))
            let ctrlb = relative(b, coordinates.at(3))

            vertices.push((a, (0pt, 0pt), ctrla))
            vertices.push((b, ctrlb, (0pt, 0pt)))
          } else {
            vertices += coordinates
          }
        }
        path(
          stroke: drawable.stroke,
          fill: drawable.fill,
          closed: drawable.at("close", default: false),
          ..vertices,
        )
      } else if drawable.type == "content" {
        let (width, height) = util.typst-measure(drawable.body, ctx.typst-style)
        move(
          dx: (drawable.pos.at(0) - bounds.low.at(0)) * length - width / 2,
          dy: (drawable.pos.at(1) - bounds.low.at(1)) * length - height / 2,
          drawable.body,
        )
      })
    }
  }))
}))
