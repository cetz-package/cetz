#import "grouping.typ": group, get-ctx, set-ctx, scope
#import "transformations.typ": set-transform
#import "/src/process.typ"
#import "/src/matrix.typ"
#import "/src/drawable.typ"
#import "/src/util.typ"
#import "/src/polygon.typ"

// Get an orthographic view matrix for 3 angles
#let ortho-matrix(x, y, z) = matrix.mul-mat(
  matrix.ident(4),
  matrix.transform-rotate-x(x),
  matrix.transform-rotate-y(y),
  matrix.transform-rotate-z(z),
)

#let ortho-projection-matrix = (
  (1, 0, 0, 0),
  (0, 1, 0, 0),
  (0, 0, 0, 0),
  (0, 0, 0, 1),
)

#let _sort-by-distance(drawables) = {
  return drawables.sorted(key: d => {
    let z = none
    for ((origin, closed, segments)) in d.segments {
      z = if z == none {
        calc.max(origin.at(2))
      } else {
        calc.max(z, origin.at(2))
      }
      for ((kind, ..pts)) in segments {
        pts = pts.map(p => p.at(2))
        z = if z == none {
          calc.max(..pts)
        } else {
          calc.max(z, ..pts)
        }
      }
    }
    return z
  })
}

// Filter out all clock-wise polygons, or if `invert` is true,
// all counter clock-wise ones.
#let _filter-cw-faces(drawables, mode: "cw") = {
  return drawables.filter(d => {
    if d.segments != () {
      let poly = polygon.from-subpath(d.segments.first())
      poly.first() != poly.last() or polygon.winding-order(poly) == mode
    } else {
      d
    }
  })
}

// Sets up a view matrix to transform all `body` elements. The current context
// transform is not modified.
//
// - body (element): Elements
// - view-matrix (matrix): View matrix
// - projection-matrix (matrix): Projection matrix
// - reset-transform (bool): Ignore the current transformation matrix
// - sorted (bool): Sort drawables by maximum distance (front to back)
// - cull-face (none,str): Enable back-face culling if set to `"cw"` for clockwise
//   or `"ccw"` for counter-clockwise. Polygons of the specified order will not get drawn.
#let _projection(body, view-matrix, projection-matrix, reset-transform: true, sorted: true, cull-face: "cw") = {
  (ctx => {
    let transform = ctx.transform
    ctx.transform = view-matrix

    let (ctx, drawables, bounds) = process.many(ctx, util.resolve-body(ctx, body))

    if cull-face != none {
      assert(cull-face in ("cw", "ccw"),
        message: "cull-face must be none, cw or ccw.")
      drawables = _filter-cw-faces(drawables, mode: cull-face)
    }
    if sorted {
      drawables = _sort-by-distance(drawables)
    }

    if projection-matrix != none {
      drawables = drawable.apply-transform(projection-matrix, drawables)
    }

    ctx.transform = transform
    if not reset-transform {
      drawables = drawable.apply-transform(ctx.transform, drawables)
    }

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
/// This is a transformation matrix that rotates elements around the x, the y and the z axis by the parameters given.
///
/// By default an isometric projection (x ≈ 35.264°, y = 45°) is set.
///
/// ```typc example
/// ortho({
///   on-xz({
///     rect((-1,-1), (1,1))
///   })
/// })
/// ```
///
/// - x (angle): X-axis rotation angle
/// - y (angle): Y-axis rotation angle
/// - z (angle): Z-axis rotation angle
/// - sorted (bool): Sort drawables by maximum distance (front to back)
/// - cull-face (none,str): Enable back-face culling if set to `"cw"` for clockwise
///   or `"ccw"` for counter-clockwise. Polygons of the specified order will not get drawn.
/// - reset-transform (bool): Ignore the current transformation matrix
/// - body (element): Elements to draw
#let ortho(x: 35.264deg, y: 45deg, z: 0deg, sorted: true, cull-face: none, reset-transform: false, body, name: none) = group(name: name, ctx => {
  _projection(body, ortho-matrix(x, y, z), ortho-projection-matrix,
    sorted: sorted,
    cull-face: cull-face,
    reset-transform: reset-transform)
})

/// Draw elements on the xy-plane with optional z offset.
///
/// All vertices of all elements will be changed in the following way: $\begin{pmatrix} x \\ y \\ z_\text{argument}\end{pmatrix}$, where $z_\text{argument}$ is the z-value given as argument.
///
/// ```typc example
/// on-xy({
///   rect((-1, -1), (1, 1))
/// })
/// ```
///
/// - z (number): Z offset for all coordinates
/// - body (element): Elements to draw
#let on-xy(z: 0, body) = get-ctx(ctx => {
  let z = util.resolve-number(ctx, z)
  scoped-transform(body, if z != 0 {
    matrix.transform-translate(0, 0, z)
  }, matrix.ident(4))
})

/// Draw elements on the xz-plane with optional y offset.
///
/// All vertices of all elements will be changed in the following way: $\begin{pmatrix} x \\ y_\text{argument} \\ y \end{pmatrix}$, where $y_\text{argument}$ is the y-value given as argument.
///
/// ```typc example
/// on-xz({
///   rect((-1, -1), (1, 1))
/// })
/// ```
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
/// All vertices of all elements will be changed in the following way: $\begin{pmatrix} x_\text{argument} \\ x \\ y \end{pmatrix}$, where $x_\text{argument}$ is the x-value given as argument.
///
/// ```typc example
/// on-yz({
///   rect((-1, -1), (1, 1))
/// })
/// ```
///
/// - x (number): X offset for all coordinates
/// - body (element): Elements to draw
#let on-yz(x: 0, body) = get-ctx(ctx => {
  let x = util.resolve-number(ctx, x)
  scoped-transform(body, if x != 0 {
    matrix.transform-translate(x, 0, 0)
  }, matrix.transform-rotate-y(90deg))
})
