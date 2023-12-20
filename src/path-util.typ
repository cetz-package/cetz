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
    panic("Invalid segment: " + type, s)
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
}

/// Finds the point at a given distance from the start of a path segment. Distances greater than the length of the segment return the end of the path segment. Distances less than zero return the start of the segment.
///
/// - segment (segment): Path segment
/// - distance (float): The distance along the path segment to find the point
///
/// -> vector: The point on the path segment
#let _point-on-segment(segment, distance, length: none, samples: default-samples) = {
  let (kind, ..pts) = segment
  if kind == "line" {
    return _point-on-line-segment(segment, distance)
  } else if kind == "cubic" {
    return bezier.cubic-point(
      ..pts,
      bezier.cubic-t-for-distance(
        ..pts,
        distance,
        samples: samples
      )
    )
  }
}



#let segment-at-t(segments, t, rev: false, samples: default-samples) = {
  let lengths = segments.map(_segment-length.with(samples: samples))
  let total = lengths.sum()

  if type(t) == ratio {
    assert(t >= 0% and t <= 100%)
    t = total * t / 100%
  } else {
    assert(t >= 0 and t <= total, message: strfmt("t is expected to be between 0 and the length of the path ({}), got: {}", total, t))
  }

  if rev {
    segments = segments.rev()
    lengths = lengths.rev()
  }
  let travelled = 0
  for (i, segment-length) in segments.zip(lengths).enumerate() {
    let (segment, length) = segment-length
    if travelled <= t and t <= travelled + length {
      // if rev { panic(t - travelled) }
      return (
        index: if rev { segments.len() - i } else { i },
        segment: segment,
        // Distance travelled
        travelled: travelled,
        // Distance left
        distance: t - travelled,
        // The length of the segment
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
#let point-on-path(segments, t, samples: default-samples) = {
  assert(
    type(t) in (int, float, ratio),
    message: "Distance t must be of type int, float or ratio"
  )
  let rev = if type(t) == ratio and t < 0% or type(t) in ("int", "float") and t < 0 {
    t *= -1
    true
  } else {
    false
  }
  let (distance, segment, length, ..) = segment-at-t(segments, t, samples: samples, rev: rev)
  return if segment != none {
    _point-on-segment(segment, if rev { length - distance } else { distance }, length: length, samples: samples)
  }
}

/// Get position and direction on path
///
/// TODO: Replace this function by having point-on-path return both a point
///       and a direction vector!
///
/// - segments (array): List of path segments
/// - t (float): Position (from 0 to 1)
/// -> tuple: Tuple of the point at t and the scaled direction
#let direction(segments, t, samples: default-samples) = {
  let (segment, distance, length, ..) = segment-at-t(segments, t, samples: samples)
  return (
    _point-on-segment(segment, distance, length: length, samples: samples),
    if segment.first() == "line" {
      let (start, end, distance, length) = _points-between-distance(segment.slice(1), distance)
      vector.norm(vector.sub(segment.at(end+1), segment.at(start+1)))
    } else {
      bezier.cubic-derivative(..segment.slice(1), distance / length, samples: samples)
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
#let shorten-segment(segment, distance, mode: "CURVED", samples: default-samples) = {
  let (type, ..s) = segment
  if type == "line" {
    let rev = distance < 0
    if rev {
      distance *= -1
      s = s.rev()
    }
    let (start, end, distance, length) = _points-between-distance(s, distance)

    s = (vector.lerp(s.at(start), s.at(end), distance / length),) + s.slice(end)
      // panic(s)
    if rev {
      s = s.rev()
    }
  } else {
    s = if mode == "LINEAR" {
      bezier.cubic-shorten-linear(..s, distance)
    } else {
      bezier.cubic-shorten(..s, distance, samples: samples)
    }
  }
  return (type,) + s
}

/// Shortens a path's segments by the given distances. The start of the path is shortened first by moving the point along the line towards the end. The end of the path is then shortened in the same way. When a distance is 0 no other calculations are made.
/// 
/// - segments (segments): The segments of the path to shorten.
/// - start-distance (int, float): The distance to shorten from the start of the path.
/// - end-distance (int, float): The distance to shorten from the end fo the path
/// -> segments Segments of the path that have been shortened
#let shorten-path(segments, start-distance, end-distance, mode: "CURVED", samples: default-samples) = {
  if start-distance > 0 {
    let (segment, distance, index, ..) = segment-at-t(
      segments,
      start-distance
    )
    segments = segments.slice(index + 1)
    segments.insert(0,
      shorten-segment(
        segment, 
        distance,
        mode: mode,
        samples: samples
      )
    )
  }
  if end-distance > 0 {
    let (segment, distance, index, ..) = segment-at-t(
      segments,
      end-distance,
      rev: true
    )
    segments = segments.slice(0, index - 1)
    segments.push(
      shorten-segment(
        segment, 
        -distance,
        mode: mode,
        samples: samples
      )
    )
  }
  return segments
}
