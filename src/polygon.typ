#import "/src/vector.typ"

/// Returns a list of polygon points from
/// a list of segments.
///
/// Cubic segments get linearized by sampling.
///
/// - segment (array): List of segments
/// - samples (int): Number of samples
/// -> array
#let from-subpath(subpath, samples: 10) = {
  import "/src/bezier.typ": cubic-point
  let (origin, _, segments) = subpath

  let poly = (origin,)
  for ((kind, ..args)) in segments {
    if kind == "c" {
      let (c1, c2, e) = args
      poly += range(0, samples).map(t => {
        cubic-point(poly.last(), e, c1, c2, t / (samples - 1))
      })
    } else {
      poly += args
    }
  }
  return poly
}

/// Computes the signed area of a 2D polygon.
///
/// The formula used is the following:
/// $ 1/2 \sum_{i}=0^{n-1} x_i*y_i+1 - x_i+1*y_i $
///
/// - points (array): List of Vectors of dimension >= 2
/// -> float
#let signed-area(points) = {
  let a = 0
  let n = points.len()
  let (cx, cy) = (0, 0)
  for i in range(0, n) {
    let (x0, y0, ..) = points.at(i)
    let (x1, y1, ..) = points.at(calc.rem(i + 1, n))
    cx += (x0 + x1) * (x0 * y1 - x1 * y0)
    cy += (y0 + y1) * (x0 * y1 - x1 * y0)
    a += x0 * y1 - x1 * y0
  }
  return .5 * a
}

/// Returns the winding order of a 2D polygon
/// by using it's signed area.
///
/// Returns either "ccw" (counter clock-wise) or "cw" (clock-wise) or none.
///
/// - point (array): List of polygon points
/// -> str,none
#let winding-order(points) = {
  let area = signed-area(points)
  if area > 0 {
    "cw"
  } else if area < 0 {
    "ccw"
  } else {
    none
  }
}

// Calculate triangle centroid
#let triangle-centroid(points) = {
  assert.eq(points.len(), 3)

  let (mx, my, mz) = (0, 0, 0)
  for p in points {
    let (x, y, z) = p
    mx += x
    my += y
    mz += z
  }
  return (mx / 3, my / 3, mz / 3)
}

// Calculate the centroid of a line, triangle or simple polygon
// Formulas:
//   https://en.wikipedia.org/wiki/Centroid
#let simple-centroid(points) = {
  return if points.len() <= 1 {
    none
  } else if points.len() == 2 {
    vector.lerp(..points, .5)
  } else if points.len() == 3 {
    triangle-centroid(points)
  } else if points.len() >= 3 {
    // Skip polygons with multiple z values
    let z = points.first().at(2, default: 0)
    if points.any(p => p.at(2) != z) {
      return none
    }

    let a = 0
    let n = points.len()
    let (cx, cy) = (0, 0)
    for i in range(0, n) {
      let (x0, y0, ..) = points.at(i)
      let (x1, y1, ..) = points.at(calc.rem(i + 1, n))
      cx += (x0 + x1) * (x0 * y1 - x1 * y0)
      cy += (y0 + y1) * (x0 * y1 - x1 * y0)
      a += x0 * y1 - x1 * y0
    }
    return (cx/(3*a), cy/(3*a), z)
  }
}
