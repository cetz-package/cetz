#import "grouping.typ": group, get-ctx, set-ctx, scope
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
// - ..mat (matrix): Transformation matrices
#let scoped-transform(body, ..mat) = {
  scope({
    set-ctx(ctx => {
      ctx.transform = matrix.mul-mat(ctx.transform, ..mat.pos().filter(m => m != none))
      return ctx
    })
    body
  })
}

/// Set-up an orthographic projection environment.
///
/// This is a transformation matrix that rotates elements around
/// the x, the y and the z axis by the parameters given.
///
/// By default an isometric projection (x ≈ 35.264°, y = 45°) is set.
///
/// #example(```
/// ortho({
///   on-xz({
///     rect((-1,-1), (1,1))
///   })
/// })
/// ```)
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

/// Draw elements on the xy-plane with optional z offset.
///
/// All vertices of all elements will be changed in the
/// following way: $vec(x, y, z_"argument")$, where $z_"argument"$
/// is the z-value given as argument.
///
/// #example(```
/// on-xy({
///   rect((-1, -1), (1, 1))
/// })
/// ```)
///
/// - z (number): Z offset for all coordinates
/// - body (element): Elements to draw
#let on-xy(z: 0, body) = get-ctx(ctx => {
  let z = util.resolve-number(ctx, z)
  scoped-transform(body, if z != 0 {
    matrix.transform-translate(0, 0, z)
  }, matrix.ident())
})

/// Draw elements on the xz-plane with optional y offset.
///
/// All vertices of all elements will be changed in the
/// following way: $vec(x, y_"argument", y)$, where $y_"argument"$
/// is the y-value given as argument.
///
/// #example(```
/// on-xz({
///   rect((-1, -1), (1, 1))
/// })
/// ```)
///
/// - y (number): Y offset for all coordinates
/// - body (element): Elements to draw
#let on-xz(y: 0, body) = get-ctx(ctx => {
  let y = util.resolve-number(ctx, y)
  scoped-transform(body, if y != 0 {
    matrix.transform-translate(0, y, 0)
  }, matrix.transform-rotate-x(90deg))
})

/// Draw elements on the yz-plane with optional x offset.
///
/// All vertices of all elements will be changed in the
/// following way: $vec(x_"argument", x, y)$, where $x_"argument"$
/// is the x-value given as argument.
///
/// #example(```
/// on-yz({
///   rect((-1, -1), (1, 1))
/// })
/// ```)
///
/// - x (number): X offset for all coordinates
/// - body (element): Elements to draw
#let on-yz(x: 0, body) = get-ctx(ctx => {
  let x = util.resolve-number(ctx, x)
  scoped-transform(body, if x != 0 {
    matrix.transform-translate(x, 0, 0)
  }, matrix.transform-rotate-y(90deg))
})
