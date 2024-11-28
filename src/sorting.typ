#import "/src/vector.typ"
#import "/src/util.typ"

/// Sort list of points by distance to a
/// reference point.
///
/// - points (array): List of points to sort
/// - reference (vec): Reference point
/// -> List of points
#let points-by-distance(ctx, points, reference: (0, 0, 0)) = {
  let reference = util.apply-transform(ctx.transform, reference)
  return points.sorted(key: pt => {
    vector.dist(pt, reference)
  })
}

/// Sort list of 2D points by angle to a
/// reference 2D point in CCW order.
/// Z component is ignored.
///
/// - points (array): List of points to sort
/// - reference (vec): Reference point
/// -> List of points
#let points-by-angle(ctx, points, reference: (0, 0, 0)) = {
  let (rx, ry, ..) = util.apply-transform(ctx.transform, reference)
  return points.sorted(key: ((px, py, ..)) => {
    360deg - calc.atan2(rx - px, ry - py)
  })
}
