#import "@preview/oxifmt:0.2.0": strfmt

// This file contains utility functions for path calculation
#import "util.typ"
#import "vector.typ"
#import "bezier.typ"


#let default-samples = 25

/// Get first position vector of a path segment
///
/// - s (segment): Path segment
/// -> vector
#let segment-start(s) = {
  return s.at(1)
}

/// Get last position vector of a path segment
///
/// - s (segment): Path segment
/// -> vector
#let segment-end(s) = {
  if s.at(0) == "line" {
    return s.last()
  }
  return s.at(2)
}

/// Calculate bounding points for a list of path segments
///
/// - segments (array): List of path segments
/// -> array: List of vectors
#let bounds(segments) = {
  let bounds = ()

  for s in segments {
    let kind = s.at(0)
    if kind == "line" {
      bounds += s.slice(1)
    } else if kind == "cubic" {
      bounds.push(s.at(1))
      bounds.push(s.at(2))
      bounds += bezier.cubic-extrema(
        s.at(1), s.at(2), s.at(3), s.at(4))
    }
  }

  return bounds
}



/// Calculate length of a single path segment
///
/// - s (array): Path segment
/// -> float: Length of the segment in canvas units
#let _segment-length(s, samples: default-samples) = {
  let (type, ..pts) = s
  if type == "line" {
    let len = 0
    for i in range(1, pts.len()) {
      len += vector.len(vector.sub(pts.at(i - 1), pts.at(i)))
    }
    return len
  } else if type == "cubic" {
    return bezier.cubic-arclen(..pts, samples: samples)
  } else {
    panic("Invalid segment: " + type)
  }
}

/// Get the length of a path
///
/// - segments (array): List of path segments
/// -> float: Total length of the path
#let length(segments) = {
  return segments.map(_segment-length).sum()
}

/// Finds the two points that are between t on a line segment.
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
/// -> vector: The point on the line segment
#let _point-on-line-segment(segment, distance) = {
  let pts = segment.slice(1)

  let (start, end, distance, length) = _points-between-distance(pts, distance)
  return vector.lerp(pts.at(start), pts.at(end), distance / length)
  // if t <= 0 or t <= 0% {
  //   return segment.at(1)
  // } else if t == 100% {
  //   return segment.last()
  // }

  // let length = _segment-length(s)
  // t = if type(t) == ratio {
  //   t * length / 100%
  // }

  // if t >= length {
  //   return s.last()
  // }

  // let traveled = 0
  // for i in range(2, s.len()) {
  //   let part = vector.dist(s.at(i - 1), s.at(i))

  //   if traveled <= target and target <= traveled + part {
  //     let t = (target - traveled) / part
  //     return vector.add(
  //       s.at(i - 1), vector.scale(vector.sub(s.at(i), s.at(i - 1)), t))
  //   }

  //   traveled += part
  // }

  // return s.at(1)
}

/// Finds the point at a given distance from the start of a path segment. Distances greater than the length of the segment return the end of the path segment. Distances less than zero return the start of the segment.
///
/// - segment (segment): Path segment
/// - distance (float): The distance along the path segment to find the point
///
/// -> vector: The point on the path segment
#let _point-on-segment(segment, distance, length: none) = {
  let (kind, ..pts) = segment
  if kind == "line" {
    return _point-on-line-segment(segment, distance)
  } else if kind == "cubic" {
    // if type(t) == ratio {
      
    // }
    // let len = t
    // if type(len) == ratio {
    //   len = bezier.cubic-arclen(..pts) * calc.min(calc.max(0, t / 100%), 1)
    // }
    return bezier.cubic-point(
      ..pts,
      bezier.cubic-t-for-distance(
        ..pts,
        distance
        // if length == none { _segment-length(segment) } else { length } - distance
      )
    )
  }
}



#let segment-at-t(segments, t, rev: false) = {
  let lengths = segments.map(_segment-length)
  let total = lengths.sum()

  // if segments.len() == 0 {
  //   return none
  // } else if t in (0%, 0) {
  //   return (
  //     index: 0,
  //     segment: segments.first(),
  //     distance: 0
  //   )
  // } else if t in (100%, total) {
  //   return (
  //     index: segments.len(),
  //     segment: segments.last(),
  //     distance: total
  //   )
  // }

  if type(t) == ratio {
    assert(t >= 0% and t <= 100%)
    t = total * t / 100%
  } else {
    assert(t >= 0 and t <= total, message: strfmt("t is expected to be between 0 and the length of the path ({}), got: {}", total, t))
  }

  if rev {
    segments = segments.rev()
  }
  let travelled = 0
  for (i, segment-length) in segments.zip(lengths).enumerate() {
    let (segment, length) = segment-length
    if travelled <= t and t <= travelled + length {
      
      return (
        index: i,
        segment: segment,
        travelled: travelled,
        distance: t - travelled,
        length: length
      )
    }
    travelled += length
  }
}

/// Get position on path
///
/// - segments (array): List of path segments
/// - t (int,float,ratio): Absolute position on the path if given an
///   float or integer, or relative position if given a ratio from 0% to 100%
/// -> none,vector: Position on path. If the path is empty (segments == ()), none is returned
#let point-on-path(segments, t) = {
  assert(
    type(t) in (int, float, ratio),
    message: "Distance t must be of type int, float or ratio"
  )
  let (distance, segment, length, ..) = segment-at-t(segments, t)
  return if segment != none {
    _point-on-segment(segment, t - distance, length: length)
  }
  // if type(t) == ratio {
  //   assert(0% <= t and t <= 100%,
  //     message: "Ratio must be between 0% and 100%, got: " + repr(t))
  // }

  // if segments.len() == 0 {
  //   return none
  // } else if segments.len() == 1 {
  //   return _point-on-segment(segments.first(), t)
  // }

  // let target = if type(t) == ratio {
  //   t / 100% * length(segments)
  // } else {
  //   assert(0 <= t and t <= length(segments),
  //     message: "Absolute distance must be in path range, is: " + repr(t))
  //   t
  // }

  // if target == 0 {
  //   return segment-start(segments.first())
  // }

  // Total travel distance
  // let traveled = 0
  // for s in segments {
  //   let part = _segment-length(s)

  //   // This segment contains target
  //   if traveled <= target and target <= traveled + part {
  //     return _point-on-segment(s, target - traveled)
  //   }

  //   traveled += part
  // }

  // return segment-end(segments.last())
}

/// Get position and direction on path
///
/// TODO: Replace this function by having point-on-path return both a point
///       and a direction vector!
///
/// - segments (array): List of path segments
/// - t (float): Position (from 0 to 1)
/// -> tuple: Tuple of the point at t and the scaled direction
#let direction(segments, t) = {
  let (segment, distance, length, ..) = segment-at-t(segments, t)
  return (
    _point-on-segment(segment, distance, length: length),
    if segment.first() == "line" {
      let (start, end, distance, length) = _points-between-distance(segment.slice(1), distance)
      vector.norm(vector.sub(segment.at(end+1), segment.at(start+1)))
    } else {
      bezier.cubic-derivative(..segment.slice(1), distance / length)
    }
  )

  // return (a, vector.scale(vector.norm(vector.sub(b, a)), scale))
}

/// Create a line segment with points
///
/// - points (array): List of points
/// -> array Segment
#let line-segment(points) = {
  ("line",) + points
}

/// Create a cubic bezier segment
///
/// - a (vector): Start
/// - b (vector): End
/// - ctrl-a (vector): Control point a
/// - ctrl-b (vector): Control point b
/// -> array Segment
#let cubic-segment(a, b, ctrl-a, ctrl-b) = {
  ("cubic", a, b, ctrl-a, ctrl-b)
}

/// Shortens a segment by a given distance.
#let shorten-segment(segment, distance) = {
  let (type, ..s) = segment
  if type == "line" {
    let rev = distance < 0
    if rev {
      distance *= -1
      s = s.rev()
    }
    let (start, end, distance, length) = _points-between-distance(s, distance)

    s = (vector.lerp(s.at(start), s.at(end), distance / length),) + s.slice(end)
    
    // let travelled = 0
    // if rev {
    //   s = s.rev()
    // }
    // let prev = s.first()
    // for (i, next) in s.enumerate() {
    //   let part = vector.dist(prev, next)
    //   if travelled <= distance and (travelled + part) >= distance {
    //     segment = (vector.lerp(prev, next, (distance - travelled) / part),) + s.slice(i)
    //     break
    //   }
    //   travelled += part
    //   prev = next
    // }
  } else {
    s = bezier.cubic-shorten(..s, distance)
  }
  return (type,) + s
}

/// Shortens a path's segments by the given distances. The start of the path is shortened first by moving the point along the line towards the end. The end of the path is then shortened in the same way. When a distance is 0 no other calculations are made.
/// 
/// - segments (segments): The segments of the path to shorten.
/// - start-distance (int, float): The distance to shorten from the start of the path.
/// - end-distance (int, float): The distance to shorten from the end fo the path
/// -> segments Segments of the path that have been shortened
#let shorten-path(segments, start-distance, end-distance) = {
  let total = length(segments)
  let is-end = false
  for distance in (start-distance, end-distance) {
    if distance == 0 {
      is-end = true
      continue
    }
    if is-end {
      segments = segments.rev()
    }
    let travelled = 0
    let new = ()
    for s in segments {
      let part = _segment-length(s)
      if travelled <= distance and (travelled + part) >= distance {
        new.push(shorten-segment(s, (distance - travelled) * if is-end { -1 } else { 1 }))
        segments = new
        break
      }
      travelled += part
      new.push(s)
    }
    is-end = true
    total -= distance
  }
  return segments
}