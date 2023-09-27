#import "vector.typ"
#import "util.typ"

/// Check for line-line intersection and return point or none
///
/// - a (vector): Line 1 point 1
/// - b (vector): Line 1 point 2
/// - c (vector): Line 2 point 1
/// - d (vector): Line 2 point 2
/// -> (vector,none)
#let line-line(a, b, c, d) = {
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
    if on-line(pt, a, b) and on-line(pt, c, d) {
      return pt
    }
  }
}

/// Check for path-path intersection in 2D
///
/// - a (path): Path a
/// - b (path): Path b
/// - samples (int): Number of samples to use for bezier curves
/// -> array List of vectors
#let path-path(a, b, samples: 25) = {
  import "bezier.typ"

  // Convert segment to vertices by sampling curves
  let linearize-segment(s) = {
    let t = s.at(0)
    if t == "line" {
      return s.slice(1)
    } else if t == "cubic" {
      return range(samples + 1).map(
        t => bezier.cubic-point(..s.slice(1), t/samples))
    }
  }

  // Check for segment-segment intersection and return list of points
  let segment-segment(a, b) = {
    let pts = ()
    let av = linearize-segment(a)
    let bv = linearize-segment(b)
    if av != none and bv != none {
      for ai in range(0, av.len() - 1) {
        for bi in range(0, bv.len() - 1) {
          let isect = line-line(av.at(ai), av.at(ai + 1),
                                bv.at(bi), bv.at(bi + 1))
          if isect != none {
            pts.push(isect)
          }
        }
      }
    }
    return pts
  }

  let pts = ()
  for sa in a.segments {
    for sb in b.segments {
      pts += segment-segment(sa, sb)
    }
  }
  return pts
}
