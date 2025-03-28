// This file contains utility functions for path calculation
#import "util.typ"
#import "vector.typ"
#import "bezier.typ"
#import "deps.typ"
#import deps.oxifmt: strfmt

#let cetz-core = plugin("../cetz-core/cetz_core.wasm")

// A path is an array of subpaths.
// A subpath is a triplet of the form:
//   (origin : vector, closed : bool, segments : array<segment>)
// A segment is an array of the form:
//   (command : string, ..arguments : vector)

/// Create a new subpath. A path is an array of subpaths.
///
/// - origin (vector): Origin
/// - segments (array): Segments
/// - closed (bool): Closed
/// -> subpath
#let make-subpath(origin, segments, closed: false) = {
  (origin, closed, segments)
}

#let number-of-samples(n) = {
  let default = 25
  return if n == auto {
    default
  } else {
    n
  }
}

/// Get the start position of the first path
/// -> vector
#let first-subpath-start(path) = {
  if path.len() > 0 {
    let (origin, ..) = path.first()
    return origin
  }
  return none
}

/// Get the start point of a subpath
/// -> vector
#let subpath-start(subpath) = {
  let (origin, _, _) = subpath
  return origin
}

/// Get the end point of a subpath
/// -> vector
#let subpath-end(subpath, ignore-close-flag: false) = {
  let (origin, closed, segments) = subpath
  return if closed and not ignore-close-flag {
    origin
  } else {
    let (_, ..args) = segments.last()
    args.last()
  }
}

/// Get the direction at the start of the first path
/// -> vector
#let first-subpath-direction(path) = {
  if path.len() > 0 {
    let (origin, _, segments) = path.first()
    let (kind, ..args) = segments.first()
    if kind == "l" {
      return vector.dir(origin, args.last())
    } else if kind == "c" {
      let (c1, c2, e) = args
      return bezier.cubic-derivative(origin, e, c1, c2, 0)
    }
  }
  return none
}

/// Get the direction at the end of the last path
/// -> vector
#let last-subpath-direction(path) = {
  if path.len() > 0 {
    let (origin, _, segments) = path.last()
    if segments.len() > 1 {
      origin = segments.at(-2).last()
    }

    let (kind, ..args) = segments.last()
    if kind == "l" {
      return vector.dir(origin, args.last())
    } else if kind == "c" {
      let (c1, c2, e) = args
      return bezier.cubic-derivative(e, origin, c2, c1, 0)
    }
  }
  return none
}

/// Get the end position of the last path
/// -> vector
#let last-subpath-end(path) = {
  if path.len() > 0 {
    let (origin, close, segments) = path.last()
    if close {
      return origin
    }
    return segments.last().last()
  }
  return none
}

/// Calculates the bounding points for a list of path segments
///
/// - path (array): Path
/// -> array
#let bounds(path) = {
  let bounds = ()

  for ((origin, closed, segments)) in path {
    bounds.push(origin)

    for ((kind, ..args)) in segments {
      if kind == "l" {
        bounds += args
      } else if kind == "c" {
        let (c1, c2, e) = args
        bounds += bezier.cubic-extrema(bounds.last(), e, c1, c2)
        bounds.push(e)
      }
    }
  }

  return bounds
}

/// Returns an array of arrays with the lengths of all path segments.
/// One sub-array for each subpath and its segments.
///
/// - path (path): Input path
/// - samples (auto, int): Number of samples to use for curves
/// -> array Array of arrays of floats containing the segment lengths
#let segment-lengths(path, samples: auto) = {
  let cur = none
  let start = none

  let lengths = ()
  for ((origin, _, segments)) in path {
    start = origin
    cur = origin

    let sub-lengths = ()
    for ((kind, ..args)) in segments {
      let length = 0
      if kind == "l" {
        for pt in args {
          length += vector.dist(cur, pt)
          cur = pt
        }
      } else if kind == "c" {
        let (c1, c2, e) = args
        length += bezier.cubic-arclen(
          cur, e, c1, c2, samples: number-of-samples(samples))
        cur = e
      }

      sub-lengths.push(length)
    }

    lengths.push(sub-lengths)
  }
  return lengths
}

/// Returns the sum of all segment lengths of a path.
///
/// - segments (path): Path segments
/// - samples (auto, int): Number of samples to take for curves
/// -> float Length
#let length(segments, samples: auto) = {
  return segment-lengths(segments, samples: samples).map(s => s.sum()).sum()
}

/// Get information about a point at a given distance on a path.
///
/// - path (path): The path
/// - distance (ratio, number): Distance along the path
/// - reverse (bool): Travel from end to start
///
/// -> dictionary Dictionary with the following keys:
///    - point (vector) The point on the path
///    - previous-point (vector) Point previous to point
///    - direction (vector) Normalized direction vector
///    - subpath-index (int) Index of the subpath
///    - segment-index (int) Index of the segment
#let point-at(path, distance, reverse: false, extrapolate: false) = {
  let travelled = 0
  // TODO: Implement extrapolation

  let lengths = segment-lengths(path)
  let total = lengths.map(l => l.sum(default: 0)).sum(default: 0)

  if type(distance) == ratio {
    distance = total * distance / 100%
  }
  if reverse {
    distance = total - distance
  }
  if not extrapolate {
    distance = calc.max(0, calc.min(distance, total))
  }

  let point-on-segment(origin, segment, distance) = {
    let (kind, ..args) = segment
    if kind == "l" {
      let pt = args.last()
      return (
        vector.lerp(origin, pt, calc.min(1, distance / vector.dist(origin, pt))),
        vector.norm(vector.sub(origin, pt)))
    } else if kind == "c" {
      let (c1, c2, e) = args
      let arclen = bezier.cubic-arclen(origin, e, c1, c2)
      let t = distance / arclen
      if not extrapolate {
        t = calc.min(1, calc.max(t, 0))
      }
      return (
        bezier.cubic-point(origin, e, c1, c2, t),
        bezier.cubic-derivative(origin, e, c1, c2, t))
    }
  }

  for ((subpath-index, subpath-lengths)) in lengths.enumerate() {
    for ((segment-index, length)) in subpath-lengths.enumerate() {
      if distance >= travelled and distance <= travelled + length {
        let (origin, _, segments) = path.at(subpath-index)
        let segment = segments.at(segment-index)
        if segment-index > 0 {
          origin = segments.at(segment-index - 1).last()
        }

        let (point, direction) = point-on-segment(
          origin, segment, distance - travelled)
        if reverse {
          direction = vector.scale(direction, -1)
        }

        return (
          previous-point: origin,
          point: point,
          direction: direction,
          subpath-index: subpath-index,
          segment-index: segment-index,
        )
      }

      travelled += length
    }
  }
}

/// Shorten a single line segment with a single point
/// by a given distance.
///
/// - origin (vector): Path origin
/// - previous (vector): Last point befor this segment
/// - args (array): List of points
/// - distance (float): Distance
/// - reverse (bool): If true, start from the end
/// -> (origin, points)
#let _shorten-line(origin, previous, args, distance, reverse: false) = {
  let pt = args.last()
  let length = vector.dist(previous, pt)
  if length > 0 {
    let t = if reverse {
      1 - distance / length
    } else {
      distance / length
    }

    let new-pt = vector.lerp(previous, pt, t)
    return if reverse {
      (origin, (new-pt,))
    } else {
      (new-pt, (pt,))
    }
  }

  return (origin, args)
}

/// Shorten a single cubic segment with a single point
/// by a given distance.
///
/// - origin (vector): Path origin
/// - previous (vector): Last point befor this segment
/// - args (array): List of points
/// - distance (float): Distance
/// - reverse (bool): If true, start from the end
/// -> (origin, points)
#let _shorten-cubic(origin, previous, args, distance, reverse: false, mode: "CURVED") = {
  let shorten-func = if mode == "CURVED" {
    bezier.cubic-shorten
  } else {
    bezier.cubic-shorten-linear
  }

  let (c1, c2, e) = args
  if reverse {
    let (s, e, c1, c2) = shorten-func(
      previous, e, c1, c2, calc.min(0, -distance))
    return (previous, (c1, c2, e))
  } else {
    let (s, e, c1, c2) = shorten-func(
      previous, e, c1, c2, calc.max(0, distance))
    return (s, (c1, c2, e))
  }
}

///
#let shorten-to(path, distance, reverse: false,
                mode: "CURVED", samples: auto, snap-to: none) = {
  if type(distance) == array {
    let (start, end) = distance
    // FIXME: This is not correct. Both shortening have to be applied on
    // the original path, otherwise percentage-values are wrong for the
    // second call.
    path = shorten-to(path, start, reverse: reverse, mode: mode, samples: samples, snap-to: snap-to)
    path = shorten-to(path, end, reverse: not reverse, mode: mode, samples: samples, snap-to: snap-to)
    return path
  }

  let point = point-at(path, distance, reverse: reverse)
  if point != none {
    // Find the subpath to modify
    let (origin, close, segments) = path.at(point.subpath-index)
    let (kind, ..args) = segments.at(point.segment-index)

    let new-origin
    if kind == "l" {
      (new-origin, args) = _shorten-line(
        origin, point.previous-point, args, distance,
        reverse: reverse)
    } else if kind == "c" {
      (new-origin, args) = _shorten-cubic(
        origin, point.previous-point, args, distance,
        reverse: reverse, mode: mode)
    }

    if (point.segment-index == 0) {
      origin = new-origin
    }

    if reverse {
      segments = segments.slice(0, point.segment-index) + ((kind, ..args,),)
    } else {
      segments = ((kind, ..args,),) + segments.slice(point.segment-index + 1)
    }
    return if reverse {
      ((origin, close, segments),) + path.slice(point.subpath-index + 1)
    } else {
      path.slice(0, point.subpath-index) + ((origin, close, segments),)
    }
  }
  return path
}

/// Normalize a path
/// - path (path): Input path
/// -> path
#let normalize(path) = {
  let args = (path: (path,))
  let encoded = cbor.encode(args)
  let result = cbor(cetz-core.path_normalize_func(encoded))
  if type(result) == str {
    panic("normalize: " + result)
  }

  return result.first()
}
