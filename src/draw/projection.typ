#import "grouping.typ": group, get-ctx, set-ctx, scope
#import "transformations.typ": set-transform
#import "/src/process.typ"
#import "/src/matrix.typ"
#import "/src/drawable.typ"
#import "/src/util.typ"
#import "/src/polygon.typ"
#import "/src/path-util.typ"
#import "/src/aabb.typ"

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

// Build perspective view matrix from rotation and camera distance.
#let _perspective-view-matrix(view-rotation-matrix, distance) = {
  matrix.mul-mat(
    matrix.ident(4),
    matrix.transform-translate(0, 0, -distance),
    view-rotation-matrix,
  )
}

// Perspective divide for a single point.
#let _perspective-project-point(pt, near, ref-depth) = {
  let x = pt.at(0)
  let y = pt.at(1)
  let z = pt.at(2, default: 0.0)
  let w = calc.max(-z, near)
  // Normalize by a reference depth so scale is anchored at that plane.
  (ref-depth * x / w, ref-depth * y / w, z)
}

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
    return if d.type != "content" and d.segments != () {
      let poly = polygon.from-subpath(d.segments.first())
      poly.first() != poly.last() or polygon.winding-order(poly) == mode
    } else {
      true
    }
  })
}

// Compute aggregate bounds from a list of drawables.
#let _drawables-bounds(drawables) = {
  let bounds = none
  for d in drawable.filter-tagged(drawables, drawable.TAG.no-bounds) {
    let pts = if d.type == "path" {
      path-util.bounds(d.segments)
    } else if d.type == "content" {
      let (x, y, _, w, h,) = d.pos + (d.width, d.height)
      ((x + w / 2, y - h / 2, 0.0), (x - w / 2, y + h / 2, 0.0))
    } else {
      ()
    }
    if pts != () {
      bounds = aabb.aabb(pts, init: bounds)
    }
  }
  return bounds
}

// Resolve reference depth as nearest drawable depth in camera space.
#let _resolve-reference-depth(ctx, body, view-rotation-matrix, distance, near) = {
  let probe-ctx = ctx
  probe-ctx.transform = view-rotation-matrix
  let (ctx: _, bounds: _, drawables: probe-drawables, elements: _) = process.many(
    probe-ctx,
    util.resolve-body(probe-ctx, body))
  let probe-bounds = _drawables-bounds(probe-drawables)
  if probe-bounds == none {
    return near
  }

  // In camera space, depth is w = distance - z_rot. The nearest depth is at z_max.
  let z-max = probe-bounds.high.at(2)
  calc.max(distance - z-max, near)
}

// Resolve distance/near values, including support for `auto`.
#let _resolve-camera-distance-near(ctx, body, view-rotation-matrix, distance) = {
  let distance = if distance == auto { auto } else { util.resolve-number(ctx, distance) }

  let probe-ctx = ctx
  probe-ctx.transform = view-rotation-matrix
  let (ctx: _, bounds: _, drawables: probe-drawables, elements: _) = process.many(
    probe-ctx,
    util.resolve-body(probe-ctx, body))
  let probe-bounds = _drawables-bounds(probe-drawables)

  let z-max = if probe-bounds == none { 0 } else { probe-bounds.high.at(2) }
  let z-min = if probe-bounds == none { 0 } else { probe-bounds.low.at(2) }
  let depth-span = calc.abs(z-max - z-min)
  let probe-near = calc.max(0.001, 0.01 * calc.max(depth-span, 1))

  if distance == auto {
    // Use a larger margin to reduce perspective intensity for auto distance.
    let margin = calc.max(probe-near * 3, depth-span * 2)
    distance = calc.max(z-max + margin, probe-near * 2)
  }

  // Keep the camera in front of the nearest geometry after rotation.
  let min-margin = calc.max(probe-near * 2, depth-span * 0.1)
  let min-distance = z-max + min-margin
  distance = calc.max(distance, min-distance)

  let scene-scale = calc.max(depth-span, 1)
  let min-w = distance - z-max
  let near = if min-w > 0 {
    calc.max(0.001, calc.min(min-w * 0.5, scene-scale * 0.05))
  } else {
    calc.max(0.001, scene-scale * 0.01)
  }

  assert(distance > 0, message: "distance must be > 0.")
  assert(near > 0, message: "near must be > 0.")
  (distance, near)
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
    let perspective-mode = type(projection-matrix) == function
    let previous-perspective-mode = ctx.at("_perspective-projection", default: false)
    if perspective-mode {
      ctx._perspective-projection = true
    }
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
    if perspective-mode {
      ctx._perspective-projection = previous-perspective-mode
    }
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
/// ```example
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
#let ortho(x: 35.264deg, y: 45deg, z: 0deg, sorted: true, cull-face: none, reset-transform: false, body) = scope(ctx => {
  _projection(body, ortho-matrix(x, y, z), ortho-projection-matrix,
    sorted: sorted,
    cull-face: cull-face,
    reset-transform: reset-transform)
})

/// Draw elements on the xy-plane with optional z offset.
///
/// All vertices of all elements will be changed in the following way: $mat(x, y, z_"argument")$, where $z_"argument"$ is the z-value given as argument.
///
/// ```example
/// ortho({
///   on-xy({
///     rect((-1, -1), (1, 1))
///   })
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
/// All vertices of all elements will be changed in the following way: $mat(x, y_"argument", y)$, where $y_"argument"$ is the y-value given as argument.
///
/// ```example
/// ortho({
///   on-xz({
///     rect((-1, -1), (1, 1))
///   })
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

/// Draw elements on the zy-plane with optional x offset.
///
/// All vertices of all elements will be changed in the following way:
/// $mat(x_"argument", y, x)$, where $x_"argument"$ is the x-value given
/// as argument.
///
/// ```example
/// ortho({
///   on-zy({
///     rect((-1, -1), (1, 1))
///   })
/// })
/// ```
///
/// - x (number): X offset for all coordinates
/// - body (element): Elements to draw
#let on-zy(x: 0, body) = get-ctx(ctx => {
  let x = util.resolve-number(ctx, x)
  scoped-transform(body, if x != 0 {
    matrix.transform-translate(x, 0, 0)
  }, matrix.transform-rotate-y(90deg))
})

/// Set-up a perspective projection environment.
///
/// Coordinates are transformed by a view matrix and then projected with
/// perspective division:
/// $x' = (d_"ref" * x) / w$ and $y' = (d_"ref" * y) / w$,
/// where $w = max(-z, "near")$ in view space.
///
/// By default this uses the same isometric camera angles as `ortho`, but with
/// perspective foreshortening.
///
/// ```example
/// perspective({
///   on-xz({
///     rect((-1,-1), (1,1))
///   })
/// })
/// ```
///
/// - x (angle): X-axis rotation angle
/// - y (angle): Y-axis rotation angle
/// - z (angle): Z-axis rotation angle
/// - distance (number,auto): Distance from camera to scene origin. `auto`
///   derives a stable value from scene depth.
/// - sorted (bool): Sort drawables by depth (back to front)
/// - cull-face (none,str): Enable back-face culling if set to `"cw"` for clockwise
///   or `"ccw"` for counter-clockwise. Polygons of the specified order will not get drawn.
/// - reset-transform (bool): Ignore the current transformation matrix
/// - body (element): Elements to draw
#let perspective(
  x: 35.264deg,
  y: 45deg,
  z: 0deg,
  distance: auto,
  sorted: true,
  cull-face: none,
  reset-transform: false,
  body,
) = scope(ctx => {
  let view-rotation-matrix = ortho-matrix(x, y, z)

  let (distance, near) = _resolve-camera-distance-near(ctx, body,
    view-rotation-matrix, distance)
  let view-matrix = _perspective-view-matrix(view-rotation-matrix, distance)

  let ref-depth = _resolve-reference-depth(ctx, body, view-rotation-matrix, distance, near)
  let projection = pt => _perspective-project-point(pt, near, ref-depth)

  _projection(body, view-matrix, projection,
    sorted: sorted,
    cull-face: cull-face,
    reset-transform: reset-transform)
})
