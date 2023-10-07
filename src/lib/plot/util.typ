#import "../../bezier.typ"

/// Clip line-strip in rect
///
/// - points (array): Array of vectors representing a line-strip
/// - low (vector): Lower clip-window coordinate
/// - high (vector): Upper clip-window coordinate
/// -> array List of line-strips representing the paths insides the clip-window
#let clipped-paths(points, low, high, fill: false) = {
  let (min-x, max-x) = (calc.min(low.at(0), high.at(0)),
                        calc.max(low.at(0), high.at(0)))
  let (min-y, max-y) = (calc.min(low.at(1), high.at(1)),
                        calc.max(low.at(1), high.at(1)))

  let in-rect(pt) = {
    return (pt.at(0) >= min-x and pt.at(0) <= max-x and
            pt.at(1) >= min-y and pt.at(1) <= max-y)
  }

  let interpolated-end(a, b) = {
    if in-rect(a) and in-rect(b) {
      return b
    }

    let (x1, y1, ..) = a
    let (x2, y2, ..) = b

    if x2 - x1 == 0 {
      return (x2, calc.min(max-y, calc.max(y2, min-y)))
    }

    if y2 - y1 == 0 {
      return (calc.min(max-x, calc.max(x2, min-x)), y2)
    }

    let m = (y2 - y1) / (x2 - x1)
    let n = y2 - m * x2

    let x = x2
    let y = y2

    y = calc.min(max-y, calc.max(y, min-y))
    x = (y - n) / m

    x = calc.min(max-x, calc.max(x, min-x))
    y = m * x + n

    return (x, y)
  }

  // Append path to paths and return paths
  //
  // If path starts or ends with a vector of another part, merge those
  // paths instead appending path as a new path.
  let append-path(paths, path) = {
    if path.len() <= 1 {
      return paths
    }

    let cmp(a, b) = {
      return a.map(calc.round.with(digits: 8)) == b.map(calc.round.with(digits: 8))
    }

    let added = false
    for i in range(0, paths.len()) {
      let p = paths.at(i)
      if cmp(p.first(), path.last()) {
        paths.at(i) = path + p
        added = true
      } else if cmp(p.first(), path.first()) {
        paths.at(i) = path.rev() + p
        added = true
      } else if cmp(p.last(), path.first()) {
        paths.at(i) = p + path
        added = true
      } else if cmp(p.last(), path.last()) {
        paths.at(i) = p + path.rev()
        added = true
      }
      if added { break }
    }

    if not added {
      paths.push(path)
    }
    return paths
  }

  let clamped-pt(pt) = {
    return (calc.max(min-x, calc.min(pt.at(0), max-x)),
            calc.max(min-y, calc.min(pt.at(1), max-y)))
  }

  let paths = ()

  let path = ()
  let prev = points.at(0)
  let was-inside = in-rect(prev)
  if was-inside {
    path.push(prev)
  } else if fill {
    path.push(clamped-pt(prev))
  }

  for i in range(1, points.len()) {
    let pt = points.at(i)
    let is-inside = in-rect(pt)

    if is-inside {
      if was-inside {
        path.push(pt)
      } else {
        path.push(interpolated-end(pt, prev))
        path.push(pt)
      }
    } else {
      if was-inside {
        path.push(interpolated-end(prev, pt))
      } else {
        let (a, b) = (interpolated-end(pt, prev),
                      interpolated-end(prev, pt))
        if in-rect(a) and in-rect(b) {
          path.push(a)
          path.push(b)
        } else if fill {
          path.push((calc.max(min-x, calc.min(pt.at(0), max-x)),
                     calc.max(min-y, calc.min(pt.at(1), max-y))))
        }
      }

      if path.len() > 0 and not fill {
        paths = append-path(paths, path)
        path = ()
      }
    }
    
    prev = pt
    was-inside = is-inside
  }

  // Append clamped last point if filling
  if fill and not in-rect(prev) {
    path.push(clamped-pt(prev))
  }

  if path.len() > 1 {
    paths = append-path(paths, path)
  }

  return paths
}

/// Compute clipped stroke paths
///
/// - points (array): X/Y data points
/// - low (vector): Lower clip-window coordinate
/// - high (vector): Upper clip-window coordinate
/// -> array List of stroke paths
#let compute-stroke-paths(points, low, high) = {
  clipped-paths(points, low, high, fill: false)
}

/// Compute clipped fill path
///
/// - points (array): X/Y data points
/// - low (vector): Lower clip-window coordinate
/// - high (vector): Upper clip-window coordinate
/// -> array List of fill paths
#let compute-fill-paths(points, low, high) = {
  clipped-paths(points, low, high, fill: true)
}

/// Return points of a sampled catmull-rom through the
/// input points.
///
/// - points (array): Array of input vectors
/// - tension (float): Catmull-Rom tension
/// - samples (int): Number of samples
/// -> array Array of vectors
#let sampled-spline-data(points, tension, samples) = {
  assert(samples >= 1 and samples <= 100,
    message: "Must at least use 1 sample per curve")
  
  let curves = bezier.catmull-to-cubic(points, tension)
  let pts = ()
  for c in curves {
    for t in range(0, samples + 1) {
      let t = t / samples
      pts.push(bezier.cubic-point(..c, t))
    }
  }
  return pts
}

/// Simplify linear data by "detecting" linear sections
/// and skipping points until the slope changes.
/// This can have a huge impact on the number of lines
/// getting rendered.
///
/// - data (array): Data points
/// - epsilon (float): Curvature threshold to treat data as linear
#let linearized-data(data, epsilon) = {
  let pts = ()
  // Current slope, set to none if infinite
  let dx = none
  // Previous point, last skipped point
  let prev = none
  let skipped = none
  // Current direction
  let dir = 0

  let len = data.len()
  for i in range(0, len) {
    let pt = data.at(i)
    if prev != none and i < len - 1 {
      let new-dir = pt.at(0) - prev.at(0)
      if new-dir == 0 {
        // Infinite slope
        if dx != none {
          if skipped != none {pts.push(skipped); skipped = none}
          pts.push(pt)
        } else {
          skipped = pt
        }
        dx = none
      } else {
        // Push the previous and the current point
        // if slope or direction changed
        let new-dx = ((pt.at(1) - prev.at(1)) / new-dir)
        if dx == none or calc.abs(new-dx - dx) > epsilon or (new-dir * dir) < 0 {
          if skipped != none {pts.push(skipped); skipped = none}
          pts.push(pt)

          dx = new-dx
          dir = new-dir
        } else {
          skipped = pt
        }
      }
    } else {
      if skipped != none {pts.push(skipped); skipped = none}
      pts.push(pt)
    }

    prev = pt
  }

  return pts
}
