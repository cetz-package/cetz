#import "/src/coordinate.typ"
#import "/src/drawable.typ"
#import "/src/styles.typ"
#import "/src/path-util.typ"
#import "/src/util.typ"
#import "/src/vector.typ"
#import "/src/matrix.typ"
#import "/src/process.typ"
#import "/src/polygon.typ"

/// Draw a prism by extending a single element
/// into a direction.
///
/// Curved shapes get sampled into linear ones.
///
/// = parameters
///
/// = Styling
/// *Root:* `prism`
/// == Keys
///   #show-parameter-block("front-stroke", ("stroke", "none"), [Front-face stroke], default: auto)
///   #show-parameter-block("front-fill",   ("fill", "none"),   [Front-face fill], default: auto)
///   #show-parameter-block("back-stroke",  ("stroke", "none"), [Back-face stroke], default: auto)
///   #show-parameter-block("back-fill",    ("fill", "none"),   [Back-face fill], default: auto)
///   #show-parameter-block("side-stroke",  ("stroke", "none"), [Side stroke], default: auto)
///   #show-parameter-block("side-fill",    ("fill", "none"),   [Side fill], default: auto)
///
/// ```example
/// ortho({
///   // Draw a cube with and edge length of 2
///   prism({
///     rect((-1, -1), (rel: (2, 2)))
///   }, 2)
/// })
/// ```
///
/// - front-face (elements): A single element to use as front-face
/// - dir (number,vector): Z-distance or direction vector to extend
///   the front-face along
/// - samples (int): Number of samples to use for sampling curves
#let prism(front-face, dir, samples: 10, ..style) = {
  assert.eq(style.pos(), (),
    message: "Prism takes no positional arguments")

  let style = style.named()
  (ctx => {
    let transform = ctx.transform
    ctx.transform = matrix.ident()
    let (ctx, drawables, bounds) = process.many(ctx, util.resolve-body(ctx, front-face))
    ctx.transform = transform

    assert.eq(drawables.len(), 1,
      message: "Prism shape must be a single drawable.")

    let points = polygon.from-segments(drawables.first().segments, samples: samples)

    let style = styles.resolve(ctx.style, merge: style, root: "prism")

    // Normal to extend the front face along
    let n = if type(dir) == array {
      dir.map(util.resolve-number.with(ctx))
    } else {
      (0, 0, util.resolve-number(ctx, dir))
    }

    let stroke = (:)
    let fill = (:)
    for face in ("front", "back", "side") {
      stroke.insert(face, style.at("stroke-" + face, default: style.stroke))
      fill.insert(face, style.at("fill-" + face, default: style.fill))
    }

    let drawables = ()
    let back-points = util.apply-transform(matrix.transform-translate(..n), ..points)

    // Back
    let back = drawable.path(path-util.line-segment(back-points.rev()),
      close: true, stroke: stroke.back, fill: fill.back)
    drawables.push(back)

    // Sides
    for i in range(0, points.len()) {
      let k = calc.rem(i + 1, points.len())

      let quad = (points.at(i), back-points.at(i), back-points.at(k), points.at(k))
      let side = drawable.path(path-util.line-segment(quad),
        close: true, stroke: stroke.side, fill: fill.side)
      drawables.push(side)
    }

    // Front
    let front = drawable.path(path-util.line-segment(points),
      close: true, stroke: stroke.front, fill: fill.front)
    drawables.push(front)

    return (
      ctx: ctx,
      drawables: drawable.apply-transform(ctx.transform, drawables),
    )
  },)
}
