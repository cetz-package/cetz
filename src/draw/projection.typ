#import "grouping.typ": group, get-ctx
#import "transformations.typ": set-transform
#import "/src/process.typ"
#import "/src/matrix.typ"
#import "/src/drawable.typ"
#import "/src/util.typ"

#let ortho-projection-matrix = ((1, 0, 0, 0),
                                (0, 1, 0, 0),
                                (0, 0, 0, 0),
                                (0, 0, 0, 1))

// Get an orthographic view matrix for 3 angles
#let ortho-matrix(x, y, z) = matrix.mul-mat(
  matrix.ident(),
  matrix.transform-rotate-x(x),
  matrix.transform-rotate-y(y),
  matrix.transform-rotate-z(z),
)

// Pushes a view- and projection-matrix to transform
// all `body` elements. The current context transform is
// not modified.
//
// - body (element): Elements
// - view-matrix (matrix): View matrix
// - projection-matrix (matrix): Projection matrix
// - reset-transform (bool): If true, override (and thus ignore)
//   the current transformation with the new matrices instead
//   of multiplying them.
#let _projection(body, view-matrix, projection-matrix, reset-transform: false) = {
  (ctx => {
    let transform = ctx.transform
    ctx.transform = matrix.mul-mat(projection-matrix, view-matrix)
    if not reset-transform {
      ctx.transform = matrix.mul-mat(transform, ctx.transform)
    }
    let (ctx, drawables, bounds) = process.many(ctx, util.resolve-body(ctx, body))
    ctx.transform = transform

    return (
      ctx: ctx,
      bounds: bounds,
      drawables: drawables,
    )
  },)
}

// Apply function `fn` to all vertices of all
// elements in `body`.
//
// - body (element): Elements
// - fn (function): Callback of the form `vector => vector` that gets
//   applied to all vertices
#let apply-transform-function(body, fn) = {
  (ctx => {
    let transform = ctx.transform
    ctx.transform = matrix.ident()
    let (ctx, drawables, bounds) = process.many(ctx, util.resolve-body(ctx, body))
    ctx.transform = transform

    drawables = drawables.map(d => {
      d.segments = d.segments.map(s => {
        let (kind, ..pts) = s
        return (kind, ..pts.map(pt => {
          fn(pt)
        }))
      })
      if d.type == "content" {
        d.pos = fn(d.pos)
      }
      return d
    })

    return (
      ctx: ctx,
      drawables: drawable.apply-transform(ctx.transform, drawables),
    )
  },)
}

/// Set-up an orthographic projection matrix.
///
/// By default an isometric projection is set.
///
/// - x (angle): X-axis rotation angle
/// - y (angle): Y-axis rotation angle
/// - z (angle): Z-axis rotation angle
/// - reset-transform (bool): Ignore the current transformation matrix
/// - body (element): Elements to draw
#let ortho(x: 35.264deg, y: 45deg, z: 0deg, reset-transform: false, body, name: none) = group(name: name, ctx => {
  _projection(body, ortho-matrix(x, y, z),
    ortho-projection-matrix, reset-transform: reset-transform)
})

/// Draw elements on the xy-plane with optional z value.
///
/// - z (number): Z coordinate for all coordinates
/// - body (element): Elements to draw
#let on-xy(z: 0, body) = get-ctx(ctx => {
  let z = util.resolve-number(ctx, z)
  apply-transform-function(body, pt => {
    (pt.at(0), pt.at(1), z)
  })
})

/// Draw elements on the xz-plane with optional y value.
///
/// - y (number): Y coordinate for all coordinates
/// - body (element): Elements to draw
#let on-xz(y: 0, body) = get-ctx(ctx => {
  let y = util.resolve-number(ctx, y)
  apply-transform-function(body, pt => {
    (pt.at(0), y, pt.at(1))
  })
})

/// Draw elements on the yz-plane with optional y value.
///
/// - x (number): X coordinate for all coordinates
/// - body (element): Elements to draw
#let on-yz(x: 0, body) = get-ctx(ctx => {
  let x = util.resolve-number(ctx, x)
  apply-transform-function(body, pt => {
    (x, pt.at(0), pt.at(1))
  })
})
