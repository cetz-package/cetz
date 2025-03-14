// This file contains utility functions for path calculation
#import "util.typ"
#import "vector.typ"
#import "bezier.typ"
#import "deps.typ"
#import deps.oxifmt: strfmt

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
        bounds += bezier.cubic-extrema(bounds.last(), c1, c2, e)
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
///    - direction (vector) Normalized direction vector
///    - subpath-index (int) Index of the subpath
///    - segment-index (int) Index of the segment
#let point-at(path, distance, reverse: false) = {
  let travelled = 0

  let lengths = segment-lengths(path)
  let total = lengths.map(l => l.sum()).sum()

  if type(distance) == ratio {
    distance = total * distance / 100%
  }
  if reverse {
    distance = total - distance
  }
  distance = calc.max(0, calc.min(distance, total))

  let point-on-line-strip(origin, pts, distance) = {
    let travelled = 0
    for pt in pts {
      let length = vector.dist(origin, pt)
      if distance >= travelled and distance <= travelled + length {
        return (
          if length > 0 {
            vector.lerp(origin, pt, (distance - travelled) / length)
          } else {
            origin
          },
          if length != 0 {
            vector.norm(vector.sub(pt, origin))
          } else {
            (1, 0, 0)
          }
        )
      }

      travelled += length
      origin = pt
    }
  }

  let point-on-segment(origin, segment, distance) = {
    let (kind, ..args) = segment
    if kind == "l" {
      return point-on-line-strip(origin, args, distance)
    } else if kind == "c" {
      return ((0,0,0), (1,0,0))
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

///
#let shorten-to(path, distance, reverse: false) = {
  let point = point-at(path, distance, reverse: reverse)

  if point != none {
    // Find the subpath to modify
    let (origin, close, segments) = path.at(point.subpath-index)
    segments = if reverse {
      segments.slice(point.segment-index + 1)
    } else {
      segments.slice(0, point.segment-index)
    }

    return if reverse {
      ((origin, close, segments),) + path.slice(point.subpath-index + 1)
    } else {
      path.slice(0, point.subpath-index) + ((origin, close, segments),)
    }
  }
  return path
}

/// Finds the two points that enclose a distance along a line segment.
/// 
/// Returns a {{dictionary}} with the following key values:
/// - start (int): The index of the point that is before the distance.
/// - end (int): The index of the point that is after the distance.
/// - distance (float): The distance along the line segment to the point with the `start` index.
/// - length (float): The distance between the found points.
/// 
/// ---
/// 
/// - pts (array): The array of points of a line segment.
/// - distance (float): The distance along the line segment.
/// -> dictionary
#let _points-between-distance(pts, distance) = {
  let travelled = 0
  let length = 0
  for i in range(1, pts.len()) {
    length = vector.dist(pts.at(i - 1), pts.at(i))
    if travelled <= distance and distance <= travelled + length {
      return (
        start: i - 1,
        end: i,
        distance: distance - travelled,
        length: length
      )
    }
    travelled += length
  }
  return (
    start: pts.len() - 2,
    end: pts.len() - 1,
    distance: length,
    length: length
  )
}

/// Finds the point at a given distance from the start of a line segment. Distances greater than the length of the segment return the end of the line segment. Distances less than zero return the start of the segment.
///
/// - segment (array): The line segment
/// - distance (float): The distance along the line segment to find the point
/// -> vector
#let _point-on-line-segment(origin, segment, distance) = {
  let pts = (origin,) + segment.slice(1)

  let (start, end, distance, length) = _points-between-distance(pts, distance)
  return if length == 0 {
    // length can be zero if start and end are at the same position
    // this can occur for several reasons, user input, group has zero width or height (not both)
    pts.at(end)
  } else {
    vector.lerp(pts.at(start), pts.at(end), distance / length)
  }
}

/// Finds the point at a given distance from the start of a path segment. Distances greater than the length of the segment return the end of the path segment. Distances less than zero return the start of the segment.
///
/// - segment (segment): Path segment
/// - distance (float): The distance along the path segment to find the point
/// - extrapolate (bool): If true, use linear extrapolation for distances outsides the path
/// -> vector
#let _point-on-segment(origin, segment, distance, samples: auto, extrapolate: false) = {
  let (kind, ..pts) = segment
  if distance == 0 {
    return origin
  }

  if kind == "l" {
    return _point-on-line-segment(origin, segment, distance)
  } else if kind == "c" {
    let (c1, c2, e) = pts
    return bezier.cubic-point(
      origin, e, c1, c2,
      bezier.cubic-t-for-distance(
        ..pts,
        distance,
        samples: samples
      )
    )
  }
}

/// Finds the segment that contains a point that is distance `t` from the start of a path.
/// - segments (array): The array of segments that make up the path.
/// - t (float,ratio): The distance to find the segment with. A {{float}} will be in absolute distance along the path. A {{ratio}} will be relative to the length of the path. Will panic if the distance is greater than the length of the path.
/// - rev (bool): When true the path will be reversed, effectively looking for the segment from the end of the path.
/// - samples (int): The number of samples to use when calculating the length of a cubic segment.
/// -> dictionary
/// ---
/// Returns a {{dictionary}} with the folloing key-value pairs:
/// - index (int): The index of the segment in the given array of segments.
/// - segment (segment): The found segment.
/// - travelled (float): The absolute distance travelled along the path to find the segment.
/// - distance (float): The distance left to travel along the path.
/// - length (float): The length of the returned segment.
#let segment-at-t(path, t, rev: false, samples: auto) = {
  let lengths = segment-lengths(path, samples: samples)
  let total = lengths.map(s => s.sum()).sum()

  if type(t) == ratio {
    t = total * t / 100%
  }

  if rev {
    t = total - t
  }

  let travelled = 0

  for ((i, subpath-lengths)) in lengths.enumerate() {
    for ((j, segment-length)) in subpath-lengths.enumerate() {
      if segment-length >= t {
        let (origin, _, segments) = path.at(i)
        if j != 0 {
          origin = segments.at(j - 1).last()
        }

        return (
          subpath-index: i,
          segment-index: if rev { subpath-lengths.len() - j } else { j },
          travelled: travelled,
          distance: t - travelled,
          length: segment-length,
          origin: origin,
          segment: segments.at(j)
        )
      }
      travelled += segment-length
    }
  }

  let last = path.last()
  let (origin, _, segments) = last
  if segments.len() > 1 {
    origin = segments.at(segments.len() - 2).last()
  }

  return (
    subpath-index: path.len() - 1,
    segment-index: last.len() - 1,
    travelled: travelled,
    distance: 0,
    length: lengths.last().last(),
    origin: segments.last().last(),
    segment: segments.last(),
  )
}

/// Extrapolates a point from a segment. It finds the direction the end of the segment is pointing and scales the normalised vector from the end of the segment. Returns {{none}} if the segment has no direction.
/// - segment (segment): The segment to extrapolate from.
/// - distance (float): The distance to extrapolate the point to.
/// - rev (bool): If `true` the segment will be reversed, effectively extrapolating the point from its start.
/// - samples (int): This isn't used.
#let _extrapolated-point-on-segment(origin, segment, distance, rev: false, samples: auto) = {
  let (kind, ..pts) = segment
  let (pt, dir) = if kind == "l" {
    let (a, b) = if rev {
      (origin, pts.first())
    } else {
      (pts.last(), origin)
    }
    (if rev {a} else {b}, vector.sub(b, a))
  } else {
    let (c1, c2, e) = pts
    let dir = bezier.cubic-derivative(origin, e, c1, c2, if rev { 0 } else { 1 })
    if vector.len(dir) == 0 {
      dir = vector.sub(e, origin)
    }
    (if rev {origin} else {e}, dir)
  }

  if vector.len(dir) != 0 {
    return vector.add(pt, vector.scale(vector.norm(dir), distance * if rev { -1 } else { 1 }))
  }
  return none
}

/// Finds the position of a point a distance from the start of a path. If the path is empty {{none}} will be returned.
///
/// - segments (array): List of path segments
/// - t (int,float,ratio): Absolute position on the path if given an float or integer, or relative position if given a ratio from 0% to 100%. When this value is negative, the point will be found from the end of the path instaed of the start.
/// - extrapolate (bool): If true, use linear extrapolation if distance is outsides the path's range
/// -> none,vector
#let point-on-path(path, t, samples: auto, extrapolate: false) = {
  assert(
    type(t) in (int, float, ratio),
    message: "Distance t must be of type int, float or ratio"
  )
  let rev = if type(t) == ratio and t < 0% or type(t) in (int, float) and t < 0 {
    true
  } else {
    false
  }

  if rev {
    t *= -1
  }

  // Extrapolate at path boundaries if enabled
  if extrapolate {
    let total = length(path, samples: samples)
    let absolute-t = if type(t) == ratio { t / 100% * total } else { t }
    if absolute-t > total {
      let (origin, _, segments) = path.last()
      return _extrapolated-point-on-segment(origin, segments.first(), absolute-t - total, rev: rev, samples: samples)
    }
  }

  let segment = segment-at-t(path, t, samples: samples, rev: rev)
  return if segment != none {
    let (distance, segment, origin, length, ..) = segment
    _point-on-segment(origin, segment, if rev { length - distance } else { distance }, samples: samples, extrapolate: extrapolate)
  }
}

/// Finds the position and direction of a point a distance along from the start of a path. Returns an {{array}} of two vectors where the first is the position, and the second is the direction.
///
/// - segments (array): List of path segments
/// - t (int,float,ratio): Absolute position on the path if given an float or integer, or relative position if given a ratio from 0% to 100%. When this value is negative, the point will be found from the end of the path instaed of the start.
/// - extrapolate (bool): If true, use linear extrapolation if distance is outsides the path's range
/// - clamp (bool): Clamps the distance between the start and end of a path.
/// -> array
#let direction(path, t, samples: auto, clamp: false) = {
  let (segment, distance, length, origin, ..) = segment-at-t(path, t, samples: samples)
  let (kind, ..pts) = segment
  pts = (origin,) + pts
  return (
    _point-on-segment(origin, segment, distance, samples: samples),
    if kind == "l" {
      let (start, end, distance, length) = _points-between-distance(pts, distance)
      vector.norm(vector.sub(pts.at(end+1), pts.at(start+1)))
    } else if kind == "c" {
      let (c1, c2, e) = pts

      let t = bezier.cubic-t-for-distance(origin, e, c1, c2, distance, samples: samples)
      let dir = bezier.cubic-derivative(origin, e, c1, c2, t)
      if vector.len(dir) == 0 {
        vector.norm(vector.sub(pts.at(1), pts.at(0)))
      } else {
        dir
      }
    }
  )
}

/// Normalize segments by connecting gaps via straight line segments and merging multiple line segments into a single one.
///
/// - segments (array): The path segments to normalize.
/// -> array
#let normalize(segments) = {
  return segments
}

/// Shortens a segment by a given distance.
/// - segment (segment): The segment to shorten.
/// - distance (float): The distance to move the start of the segment towards the end of the segment. If this value is negative, the end of the segment will be moved towards the start.
/// - snap-to (none, vector): Shortening bezier curves suffers from rounding and precision errors so a position can be given to "snap" a curve's start/end point to.
/// - mode (str): How cubic segments should be shortned. Can be `"LINEAR"` to use `bezier.cubic-shorten-linear` or `"CURVED"` to use `bezier.cubic-shorten`.
/// - samples (int): The number of samples to use when shortening a cubic segment.
/// -> segment
#let shorten-segment(segment, distance, snap-to: none, mode: "CURVED", samples: auto) = {
  let rev = distance < 0
  if distance >= _segment-length(segment) {
    return line-segment(if rev {
      (segment-start(segment), segment-start(segment))
    } else {
      (segment-end(segment), segment-end(segment))
    })
  }

  let (kind, ..s) = segment
  if kind == "line" {
    if rev {
      distance *= -1
      s = s.rev()
    }
    let (start, end, distance, length) = _points-between-distance(s, distance)
    if length != 0 {
      s = (vector.lerp(s.at(start), s.at(end), distance / length),) + s.slice(end)
    }

    if rev {
      s = s.rev()
    }
  } else {
    s = if mode == "LINEAR" {
      bezier.cubic-shorten-linear(..s, distance)
    } else {
      bezier.cubic-shorten(..s, distance, samples: samples)
    }

    // Shortening beziers suffers from rounding or precision errors
    // so we "snap" the curve start/end to the snap-points, if provided.
    if snap-to != none {
      if rev { s.at(1) = snap-to } else { s.at(0) = snap-to }
    }
  }
  return (kind,) + s
}

/// Shortens a path's segments by the given distances. The start of the path is shortened first by moving the point along the path towards the end. The end of the path is then shortened in the same way. When a distance is 0 no other calculations are made.
/// 
/// - segments (segments): The segments of the path to shorten.
/// - start-distance (int, float): The distance to shorten from the start of the path.
/// - end-distance (int, float): The distance to shorten from the end of the path
/// - pos (none, tuple): Tuple of points to "snap" the path ends to
/// -> segments Segments of the path that have been shortened
#let shorten-path(segments, start-distance, end-distance, snap-to: none, mode: "CURVED", samples: auto) = {
  let total = length(segments)
  let (snap-start, snap-end) = if snap-to == none {
    (none, none)
  } else {
    snap-to
  }

  if start-distance > 0 {
    let (segment, distance, index, ..) = segment-at-t(
      segments,
      start-distance,
    )
    segments = segments.slice(index + 1)
    segments.insert(0,
      shorten-segment(
        segment, 
        distance,
        mode: mode,
        samples: samples,
        snap-to: snap-start
      )
    )
  }
  if end-distance > 0 {
    let (segment, distance, index, ..) = segment-at-t(
      segments,
      end-distance,
      rev: true,
    )
    segments = segments.slice(0, index - 1)
    segments.push(
      shorten-segment(
        segment, 
        -distance,
        mode: mode,
        samples: samples,
        snap-to: snap-end
      )
    )
  }
  return segments
}
