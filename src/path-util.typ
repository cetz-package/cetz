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

/// Find point at position on polyline segment.
/// If the distance t is < 0% or > 100% of the paths length
/// the start/end point of the path is returned.
///
/// - s (array): Polyline path segment
/// - t (float,ratio): Absolute (float) or relative (ratio) position
/// -> vector: Position on the polyline
#let _point-on-polyline(s, t) = {
  if t == 0 or t == 0% {
    return s.at(1)
  } else if t == 100% {
    return s.last()
  }

  let len = _segment-length(s)
  let target = if type(t) == ratio {
    t * len / 100%
  } else {
    t
  }

  if target <= 0 {
    return s.at(1)
  } else if target >= len {
    return s.last()
  }

  let traveled = 0
  for i in range(2, s.len()) {
    let part = vector.dist(s.at(i - 1), s.at(i))

    if traveled <= target and target <= traveled + part {
      let t = (target - traveled) / part
      return vector.add(
        s.at(i - 1), vector.scale(vector.sub(s.at(i), s.at(i - 1)), t))
    }

    traveled += part
  }

  return s.at(1)
}

/// Get position on path segment
///
/// - s (segment): Path segment
/// - t (float,ratio): Absolute (float) or relative (ratio) position
///
/// -> vector: Position on segment as vector clamped to
///   the segments begin/end position.
#let _point-on-segment(s, t) = {
  let (kind, ..pts) = s
  if kind == "line" {
    return _point-on-polyline(s, t)
  } else if kind == "cubic" {
    let len = t
    if type(len) == ratio {
      len = bezier.cubic-arclen(..pts) * calc.min(calc.max(0, t / 100%), 1)
    }
    return bezier.cubic-point(..pts, bezier.cubic-t-for-distance(..pts, len))
  }
}

/// Get the length of a path
///
/// - segments (array): List of path segments
/// -> float: Total length of the path
#let length(segments) = {
  return segments.map(_segment-length).sum()
}

/// Get position on path
///
/// - segments (array): List of path segments
/// - t (int,float,ratio): Absolute position on the path if given an
///   float or integer, or relative position if given a ratio from 0% to 100%
/// -> none,vector: Position on path. If the path is empty (segments == ()), none is returned
#let point-on-path(segments, t) = {
  assert(type(t) in (int, float, ratio),
    message: "Distance t must be of type int, float or ratio")
  if type(t) == ratio {
    assert(0% <= t and t <= 100%,
      message: "Ratio must be between 0% and 100%, got: " + repr(t))
  }

  if segments.len() == 0 {
    return none
  } else if segments.len() == 1 {
    return _point-on-segment(segments.first(), t)
  }

  let target = if type(t) == ratio {
    t / 100% * length(segments)
  } else {
    assert(0 <= t and t <= length(segments),
      message: "Absolute distance must be in path range, is: " + repr(t))
    t
  }

  if target == 0 {
    return segment-start(segments.first())
  }

  // Total travel distance
  let traveled = 0
  for s in segments {
    let part = _segment-length(s)

    // This segment contains target
    if traveled <= target and target <= traveled + part {
      return _point-on-segment(s, target - traveled)
    }

    traveled += part
  }

  return segment-end(segments.last())
}

/// Get position and direction on path
///
/// TODO: Replace this function by having point-on-path return both a point
///       and a direction vector!
///
/// - segments (array): List of path segments
/// - t (float): Position (from 0 to 1)
/// - scale (float): Scaling factor
/// -> tuple: Tuple of the point at t and the scaled direction
#let direction(segments, t, scale: 1) = {
  let scale = scale
  let (pt, dir) = (t, t + .001)

  // if at end, use something < 1
  if t >= 1 {
    dir = t - .001
  } else {
    scale *= -1
  }

  let (a, b) = (
    point-on-path(segments, pt * 100%),
    point-on-path(segments, dir * 100%)
  )
  return (a, vector.scale(vector.norm(vector.sub(b, a)), scale))
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
