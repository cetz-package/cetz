/// Returns a list of polygon points from
/// a list of segments.
///
/// Cubic segments get linearized by sampling.
///
/// - segment (array): List of segments
/// - samples (int): Number of samples
/// -> array
#let from-segments(segments, samples: 10) = {
  import "/src/bezier.typ": cubic-point
  let poly = ()
  for ((kind, ..pts)) in segments {
    if kind == "cubic" {
      poly += range(0, samples).map(t => {
        cubic-point(..pts, t / (samples - 1))
      })
    } else {
      poly += pts
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
