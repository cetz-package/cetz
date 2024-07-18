#import "grouping.typ": group, get-ctx, set-ctx, scope
#import "transformations.typ": set-transform
#import "/src/process.typ"
#import "/src/matrix.typ"
#import "/src/drawable.typ"
#import "/src/util.typ"

// Get an orthographic view matrix for 3 angles
#let ortho-matrix(x, y, z) = matrix.mul-mat(
  matrix.ident(),
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
    for ((kind, ..pts)) in d.segments {
      pts = pts.map(p => p.at(2))
      z = if z == none {
        calc.max(..pts)
      } else {
        calc.max(z, ..pts)
      }
    }
    return z
  })
}

#let _calc-polygon-area(points) = {
  let a = 0 // Signed area: 1/2 sum_i=0^n-1 x_i*y_i+1 - x_i+1*y_i
  let n = points.len()
  let (cx, cy) = (0, 0)
  for i in range(0, n) {
    let (x0, y0, z0) = points.at(i)
    let (x1, y1, _) = points.at(calc.rem(i + 1, n))
    cx += (x0 + x1) * (x0 * y1 - x1 * y0)
    cy += (y0 + y1) * (x0 * y1 - x1 * y0)
    a += x0 * y1 - x1 * y0
  }
  return .5 * a
}

// Computet the face order by computing the face
// area. Curves get sampled to a polygon.
// This won't work correctly for non coplanar
#let _compute-face-order(d, samples: 10) = {
  import "/src/bezier.typ": cubic-point
  let points = ()
  for ((kind, ..pts)) in d.segments {
    if kind == "cubic" {
      pts = range(0, samples).map(t => {
        cubic-point(..pts, t / (samples - 1))
      })
    }
    points += pts
  }
  return _calc-polygon-area(points) <= 0
}

#let _filter-cw-faces(drawables, invert: false) = {
  return drawables.filter(d => {
    let a = _compute-face-order(d)
    let b = invert
    return (a and not b) or (not a and b)
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
// - cull-face (none,string): Enable back-face culling if set to `"cw"` for clockwise
//   or `"ccw"` for counter-clockwise. Polygons of the specified order will not get drawn.
#let _projection(body, view-matrix, projection-matrix, reset-transform: true, sorted: true, cull-face: "cw") = {
  (ctx => {
    let transform = ctx.transform
    ctx.transform = view-matrix

    let (ctx, drawables, bounds) = process.many(ctx, util.resolve-body(ctx, body))

    if cull-face != none {
      assert(cull-face in ("cw", "ccw"),
        message: "cull-face must be none, cw or ccw.")
      drawables = _filter-cw-faces(drawables, invert: cull-face == "ccw")
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
/// - cull-face (none,string): Enable back-face culling if set to `"cw"` for clockwise
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
  }, matrix.ident())
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
