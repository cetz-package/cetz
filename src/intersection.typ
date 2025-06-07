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

/// Finds the intersections of a line and path in 2D. The path should be given as a {{drawable}} of type `path`.
///
/// - la (vector): Line start
/// - lb (vector): Line end
/// - path (drawable): The path.
/// -> array<array<float>>
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

  pts = pts.map(pt => pt.map(util.promote-float))
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
