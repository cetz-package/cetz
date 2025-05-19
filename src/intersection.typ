#import "vector.typ"
#import "util.typ"

/// Checks for a line-line intersection between the given points and returns its position, otherwise {{none}}.
///
/// - a (vector): Line 1 point 1
/// - b (vector): Line 1 point 2
/// - c (vector): Line 2 point 1
/// - d (vector): Line 2 point 2
/// - ray (bool): When `true`, intersections will be found for the whole line instead of inbetween the given points.
/// -> vector,none
#let line-line(a, b, c, d, ray: false) = {
  let lli8(x1, y1, x2, y2, x3, y3, x4, y4) = {
    let nx = (x1*y2 - y1*x2)*(x3 - x4)-(x1 - x2)*(x3*y4 - y3*x4)
    let ny = (x1*y2 - y1*x2)*(y3 - y4)-(y1 - y2)*(x3*y4 - y3*x4)
    let d = (x1 - x2)*(y3 - y4)-(y1 - y2)*(x3 - x4)
    if d == 0 {
      return none
    }
    return (nx / d, ny / d, 0)
  }
  let pt = lli8(a.at(0), a.at(1), b.at(0), b.at(1),
                c.at(0), c.at(1), d.at(0), d.at(1))
  if pt != none {
    let on-line(pt, a, b) = {
      let (x, y, ..) = pt
      let epsilon = util.float-epsilon
      let mx = calc.min(a.at(0), b.at(0)) - epsilon
      let my = calc.min(a.at(1), b.at(1)) - epsilon
      let Mx = calc.max(a.at(0), b.at(0)) + epsilon
      let My = calc.max(a.at(1), b.at(1)) + epsilon
      return mx <= x and Mx >= x and my <= y and My >= y
    }
    if ray or (on-line(pt, a, b) and on-line(pt, c, d)) {
      return pt
    }
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

/// Finds the intersections of a line and linestrip.
/// - la (vector): Line start point.
/// - lb (vector): Line end point.
/// - v (array): An {{array}} of {{vector}}s that define each point on the linestrip.
/// -> array
#let line-linestrip(la, lb, v) = {
  let pts = ()
  for i in range(0, v.len() - 1) {
    let pt = line-line(la, lb, v.at(i), v.at(i + 1))
    if pt != none {
      pts.push(pt)
    }
  }
  return pts
}

/// Finds the intersections of a line and path in 2D. The path should be given as a {{drawable}} of type `path`.
///
/// - la (vector): Line start
/// - lb (vector): Line end
/// - path (drawable): The path.
/// -> array
#let line-path(la, lb, path) = {
  let segment(s) = {
    let k = s.kind
    let v = s.points
    if k == "line" {
      return line-linestrip(la, lb, v)
    } else if k == "cubic" {
      return line-cubic(la, lb, ..v)
    } else {
      return ()
    }
  }

  let pts = ()
  for s in path.at("segments", default: ()) {
    pts += segment(s)
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

  // Convert segment to vertices by sampling curves
  let linearize-segment(s) = {
    let t = s.kind
    if t == "line" {
      return s.points
    } else if t == "cubic" {
      return range(samples + 1).map(
        t => cubic-point(..s.points, t/samples)
      )
    }
  }

  let pts = ()
  for s in a.at("segments", default: ()) {
    let sv = linearize-segment(s)
    for ai in range(0, sv.len() - 1) {
      pts += line-path(sv.at(ai), sv.at(ai + 1), b)
    }
  }
  return pts
}
