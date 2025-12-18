#import "vector.typ"
#import "util.typ"

/// Checks for a line-line intersection between the given points and returns
/// its position, otherwise {{none}}.
///
/// - p1 (vector): Point 1
/// - p2 (vector): Point 2
/// - p3 (vector): Point 3
/// - p4 (vector): Point 4
/// - ray (bool): If true, handle both lines as infinite rays
/// - eps (float): Epsilon
/// -> vector The intersection point between both lines
/// -> none None, if both lines are parallel
#let line-line(p1, p2, p3, p4, ray: false, eps: 1e-6) = {
  let (x1, y1, z1, ..) = if p1.len() >= 3 { p1 } else { (..p1, 0) }
  let (x2, y2, z2, ..) = if p2.len() >= 3 { p2 } else { (..p2, 0) }
  let (x3, y3, z3, ..) = if p3.len() >= 3 { p3 } else { (..p3, 0) }
  let (x4, y4, z4, ..) = if p4.len() >= 3 { p4 } else { (..p4, 0) }

  let d-21-21 = (x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1) + (z2 - z1) * (z2 - z1)
  let d-43-43 = (x4 - x3) * (x4 - x3) + (y4 - y3) * (y4 - y3) + (z4 - z3) * (z4 - z3)
  let d-43-21 = (x4 - x3) * (x2 - x1) + (y4 - y3) * (y2 - y1) + (z4 - z3) * (z2 - z1)
  let d-13-43 = (x1 - x3) * (x4 - x3) + (y1 - y3) * (y4 - y3) + (z1 - z3) * (z4 - z3)
  let d-13-21 = (x1 - x3) * (x2 - x1) + (y1 - y3) * (y2 - y1) + (z1 - z3) * (z2 - z1)

  let d = calc.round((d-21-21 * d-43-43 - d-43-21 * d-43-21), digits: 6)
  if calc.abs(d) < eps {
    return none
  }

  let m-a = (d-13-43 * d-43-21 - d-13-21 * d-43-43) / d
  let m-b = (d-13-43 + m-a * d-43-21) / d-43-43

  let a = (x1 + m-a * (x2 - x1), y1 + m-a * (y2 - y1), z1 + m-a * (z2 - z1))
  let b = (x3 + m-b * (x4 - x3), y3 + m-b * (y4 - y3), z3 + m-b * (z4 - z3))
  let d-ab = vector.dist(a, b)

  return if calc.abs(d-ab) < eps {
    if ray or (m-a >= -eps and m-a <= 1 + eps and m-b >= -eps and m-b <= 1 + eps) {
      a
    } else {
      none
    }
  } else {
    none
  }
}

/// Finds the intersections of a line and cubic bezier.
/// 
/// - s   (vector): Bezier start point
/// - e   (vector): Bezier end point
/// - c1  (vector): Bezier control point 1
/// - c2  (vector): Bezier control point 2
/// - la  (vector): Line start point
/// - lb  (vector): Line end point
/// - ray (bool): When `true`, intersections will be found for the whole line instead of inbetween the given points.
/// -> array
#let line-cubic(la, lb, s, e, c1, c2) = {
  import "/src/bezier.typ": line-cubic-intersections as line-cubic
  return line-cubic(la, lb, s, e, c1, c2)
}

/// Finds the intersections of a line and path in 2D. The path should be given as a {{drawable}} of type `path`.
///
/// - la (vector): Line start
/// - lb (vector): Line end
/// - path (drawable): The path.
/// -> array
#let line-path(la, lb, path) = {
  let pts = ()

  for ((start, closed, segments)) in path.at("segments", default: ()) {
    let origin = start
    for ((kind, ..args)) in segments {
      if kind == "l" {
        let pt = line-line(la, lb, origin, args.last())
        if pt != none {
          pts.push(pt)
        }
      } else if kind == "c" {
        let (c1, c2, e) = args
        pts += line-cubic(la, lb, origin, e, c1, c2)
      }

      origin = args.last()
    }

    if closed {
      let pt = line-line(la, lb, origin, start)
      if pt != none {
        pts.push(pt)
      }
    }
  }

  return pts
}

/// Finds the intersections between two path {{drawable}}s in 2D.
///
/// - a (path): Path a
/// - b (path): Path b
/// - samples (int): Number of samples to use for bezier curves
/// -> array
#let path-path(a, b, samples: 8) = {
  import "bezier.typ": cubic-point

  let pts = ()

  for ((start, closed, segments)) in a.at("segments", default: ()) {
    let origin = start
    for ((kind, ..args)) in segments {
      if kind == "l" {
        pts += line-path(origin, args.last(), b)
      } else if kind == "c" {
        let (c1, c2, e) = args
        let line-strip = range(samples + 1).map(t => {
          cubic-point(origin, e, c1, c2, t / samples)
        })

        for i in range(1, line-strip.len()) {
          pts += line-path(line-strip.at(i - 1), line-strip.at(i), b)
        }
      }

      origin = args.last()
    }

    if closed {
      pts += line-path(origin, start, b)
    }
  }
  return pts
}
