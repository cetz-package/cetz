// This file contains utility functions for path calculation

#import "util.typ"
#import "vector.typ"

#let default-samples = 25
#let ctx-samples(ctx) = {
  if "samples" in ctx { ctx.samples } else { default-samples }
}

/// Get first position vector of a path segment
///
/// - s (segment): Path segment
/// -> vector
#let segment-begin(s) = {
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
  let samples = default-samples
  let bounds = ()

  for s in segments {
    let type = s.at(0)
    if type == "line" {
      bounds += s.slice(1)
    } else if type == "quad" {
      let (a, b, c) = s.slice(1)
      bounds.push(a)
      bounds.push(b)
      bounds += range(1, samples).map(x =>
        util.bezier-quadratic-pt(a, b, c, x / samples))
    } else if type == "cube" {
      let (a, b, c, d) = s.slice(1)
      bounds.push(a)
      bounds.push(b)
      bounds += range(1, samples).map(x =>
        util.bezier-cubic-pt(a, b, c, d, x / samples))
    }
  }

  return bounds
}

/// Calculate length of a single path segment
///
/// - s (array): Path segment
/// -> float: Length of the segment in canvas units
#let segment-length(s) = {
  let samples = default-samples
  let type = s.at(0)
  let pts = ()
  if type == "line" {
    pts = s.slice(1)
  } else if type == "quad" {
    let (a, b, c) = s.slice(1)
    pts.push(a)
    pts = range(1, samples).map(t =>
      util.bezier-quadratic-pt(a, b, c, t / samples))
    pts.push(b)
  } else if type == "cube" {
    let (a, b, c, d) = s.slice(1)
    pts.push(a)
    pts = range(1, samples).map(t =>
      util.bezier-cubic-pt(a, b, c, d, t / samples))
    pts.push(b)
  } else {
    panic("Not implemented")
  }

  let l = 0

  let pt = pts.at(0)
  for i in range(1, pts.len()) {
    l += vector.len(vector.sub(pts.at(i), pt))
    pt = pts.at(i)
  }

  return l
}

/// Find point at position on polyline segment
///
/// - s (array): Polyline path segment
/// - t (float): Position (0 to 1)
/// -> vector: Position on the polyline
#let point-on-polyline(s, t) = {
  if t == 0 {
    return s.at(1)
  } else if t == 1 {
    return s.last()
  }

  let l = segment-length(s)
  if l == 0 {
    return s.at(1)
  }

  let dist = (a, b) => {
    vector.len(vector.sub(b, a))
  }

  let traveled-length = 0
  for i in range(2, s.len()) {
    let part-length = dist(s.at(i - 1), s.at(i))

    if traveled-length / l <= t and (traveled-length + part-length) / l >= t {
      let f = (t - traveled-length / l) / (part-length / l)

      return vector.add(
        s.at(i - 1),
        vector.scale(vector.sub(s.at(i), s.at(i - 1)), f))
    }

    traveled-length += part-length
  }

  return s.at(1)
}

/// Get position on path segment
///
/// - s (segment): Path segment
/// - t (float): Position (from 0 to 1)
/// -> vector: Position on segment
#let point-on-segment(s, t) = {
  let type = s.at(0)
  if type == "line" {
    return point-on-polyline(s, t)
  } else if type == "quad" {
    let (a, b, c) = s.slice(1)
    return util.bezier-quadratic-pt(a, b, c, t)
  } else if type == "cube" {
    let (a, b, c, d) = s.slice(1)
    return util.bezier-cubic-pt(a, b, c, d, t)
  }
}

/// Get the length of a path
///
/// - segments (array): List of path segments
/// -> float: Total length of the path
#let length(segments) = {
  return segments.map(segment-length).sum()
}

/// Get position on path
///
/// - segments (array): List of path segments
/// - t (float): Poisition (from 0 to 1)
/// -> vector: Position on path
#let point-on-path(segments, t) = {
  if segments.len() == 1 {
    return point-on-segment(segments.first(), t)
  }

  let l = length(segments)

  let traveled-length = 0
  for s in segments {
    let part-length = segment-length(s)

    if traveled-length / l <= t and (traveled-length + part-length) / l >= t {
      let f = (t - traveled-length / l) / (part-length / l)

      return point-on-segment(s, f)
    }

    traveled-length += part-length
  }
}

/// Get position and direction on path
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
    point-on-path(segments, pt),
    point-on-path(segments, dir)
  )
  return (a, vector.scale(vector.norm(vector.sub(b, a)), scale))
}
