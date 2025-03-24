// This file contains utility functions for path calculation
#import "util.typ"
#import "vector.typ"
#import "bezier.typ"
#import "deps.typ"
#import deps.oxifmt: strfmt

#let default-samples = 25

/// Returns the first position vector of a path segment.
///
/// - s (segment): Path segment
/// -> vector
#let segment-start(s) = {
  return s.points.first()
}

/// Returns the last position vector of a path segment
///
/// - s (segment): Path segment
/// -> vector
#let segment-end(s) = {
  if s.kind == "line" {
    return s.points.last()
  }
  return s.points.first()
}

/// Calculates the bounding points for a list of path segments
///
/// - segments (array): List of path segments
/// -> array
#let bounds(segments) = {
  let bounds = ()

  for s in segments {
    if s.kind == "line" {
      bounds += s.points
    } else if s.kind == "cubic" {
      bounds.push(s.points.at(0))
      bounds.push(s.points.at(1))
      bounds += bezier.cubic-extrema(..s.points)
    }
  }
  return bounds
}

/// Calculates the length of a single path segment
///
/// - s (array): Path segment
/// -> float
#let _segment-length(s, samples: default-samples) = {
  let pts = s.points
  if s.kind == "line" {
    let len = 0
    for i in range(1, pts.len()) {
      len += vector.len(vector.sub(pts.at(i - 1), pts.at(i)))
    }
    return len
  } else if s.kind == "cubic" {
    return bezier.cubic-arclen(..pts, samples: samples)
  } else {
    panic("Invalid segment: " + s.kind, s)
  }
}

/// Calculates the length of a path
///
/// - segments (array): List of path segments
/// -> float
#let length(segments) = {
  return segments.map(_segment-length).sum()
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
#let _point-on-line-segment(segment, distance) = {
  let pts = segment.points

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
#let _point-on-segment(segment, distance, samples: default-samples, extrapolate: false) = {
  let kind = segment.kind
  let pts = segment.points
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

/// Finds the segment that contains a point that is distance `t` from the start of a path.
/// - segments (array): The array of segments that make up the path.
/// - t (float,ratio): The distance to find the segment with. A {{float}} will be in absolute distance along the path. A {{ratio}} will be relative to the length of the path. Will panic if the distance is greater than the length of the path.
/// - rev (bool): When true the path will be reversed, effectively looking for the segment from the end of the path.
/// - samples (int): The number of samples to use when calculating the length of a cubic segment.
/// - clamp (bool): Clamps the distance to the length of the path, so the function won't panic.
/// -> dictionary
/// ---
/// Returns a {{dictionary}} with the folloing key-value pairs:
/// - index (int): The index of the segment in the given array of segments.
/// - segment (segment): The found segment.
/// - travelled (float): The absolute distance travelled along the path to find the segment.
/// - distance (float): The distance left to travel along the path.
/// - length (float): The length of the returned segment.
#let segment-at-t(segments, t, rev: false, samples: default-samples, clamp: false) = {
  let lengths = segments.map(_segment-length.with(samples: samples))
  let total = lengths.sum()

  if type(t) == ratio {
    t = total * t / 100%
  }
  if not clamp {
    assert(t >= 0 and t <= total,
      message: strfmt("t is expected to be between 0 and the length of the path ({}), got: {}", total, t))
  }

  if rev {
    segments = segments.rev()
    lengths = lengths.rev()
  }
  let travelled = 0
  for (i, segment-length) in segments.zip(lengths).enumerate() {
    let (segment, length) = segment-length
    if travelled <= t and t <= travelled + length {
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
  return (index: if rev { 0 } else { segments.len() - 1 },
    segment: segments.last(),
    travelled: total,
    distance: t,
    length: lengths.last())
}

/// Extrapolates a point from a segment. It finds the direction the end of the segment is pointing and scales the normalised vector from the end of the segment. Returns {{none}} if the segment has no direction.
/// - segment (segment): The segment to extrapolate from.
/// - distance (float): The distance to extrapolate the point to.
/// - rev (bool): If `true` the segment will be reversed, effectively extrapolating the point from its start.
/// - samples (int): This isn't used.
#let _extrapolated-point-on-segment(segment, distance, rev: false, samples: 100) = {
  let (kind, ..pts) = segment
  let (pt, dir) = if kind == "line" {
    let (a, b) = if rev {
      (pts.at(0), pts.at(1))
    } else {
      (pts.at(-2), pts.at(-1))
    }
    (if rev {a} else {b}, vector.sub(b, a))
  } else {
    let dir = bezier.cubic-derivative(..pts, if rev { 0 } else { 1 })
    if vector.len(dir) == 0 {
      dir = vector.sub(pts.at(1), pts.at(0))
    }
    (if rev {pts.at(0)} else {pts.at(1)}, dir)
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
#let point-on-path(segments, t, samples: default-samples, extrapolate: false) = {
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
    let total = length(segments)
    let absolute-t = if type(t) == ratio { t / 100% * total } else { t }
    if absolute-t > total {
      return _extrapolated-point-on-segment(segments.first(), absolute-t - total, rev: rev, samples: samples)
    }
  }

  let segment = segment-at-t(segments, t, samples: samples, rev: rev)
  return if segment != none {
    let (distance, segment, length, ..) = segment
    _point-on-segment(segment, if rev { length - distance } else { distance }, samples: samples, extrapolate: extrapolate)
  }
}

/// Finds the position and direction of a point a distance along from the start of a path. Returns an {{array}} of two vectors where the first is the position, and the second is the direction.
///
/// - segments (array): List of path segments
/// - t (int,float,ratio): Absolute position on the path if given an float or integer, or relative position if given a ratio from 0% to 100%. When this value is negative, the point will be found from the end of the path instaed of the start.
/// - extrapolate (bool): If true, use linear extrapolation if distance is outsides the path's range
/// - clamp (bool): Clamps the distance between the start and end of a path.
/// -> array
#let direction(segments, t, samples: default-samples, clamp: false) = {
  let (segment, distance, length, ..) = segment-at-t(segments, t, samples: samples, clamp: clamp)
  let (kind, ..pts) = segment
  return (
    _point-on-segment(segment, distance, samples: samples),
    if kind == "line" {
      let (start, end, distance, length) = _points-between-distance(pts, distance)
      vector.norm(vector.sub(segment.at(end+1), segment.at(start+1)))
    } else {
      let t = bezier.cubic-t-for-distance(..pts, distance, samples: samples)
      let dir = bezier.cubic-derivative(..pts, t)
      if vector.len(dir) == 0 {
        vector.norm(vector.sub(pts.at(1), pts.at(0)))
      } else {
        dir
      }
    }
  )
}

/// Creates a line segment with points
///
/// - points (array): List of points
/// -> segment
#let line-segment(points) = {
  (kind: "line", points: points)
}

/// Creates a cubic bezier segment
///
/// - a (vector): Start
/// - b (vector): End
/// - ctrl-a (vector): Control point a
/// - ctrl-b (vector): Control point b
/// -> segment
#let cubic-segment(a, b, ctrl-a, ctrl-b) = {
  (kind: "cubic", points: (a, b, ctrl-a, ctrl-b))
}

/// Normalize segments by connecting gaps via straight line segments and merging multiple line segments into a single one.
///
/// - segments (array): The path segments to normalize.
/// -> array
#let normalize(segments) = {
  let new = ()
  for s in segments {
    assert(type(s) == dictionary,
      message: "Expected dictionary, got: " + repr(s))
    if new == () {
      new.push(s)
    } else {
      let head = new.last()
      let pts = s.points

      if s.kind == "line" and head.kind == s.kind {
        // Merge consecutive line segments
        if new.last().len() > 0 and new.last().points.last() == pts.first() {
          new.last().points += pts.slice(1)
        } else {
          new.last().points += pts
        }
      } else if segment-start(s) != segment-end(head) {
        // Push a new line or line point if the current segment
        // does not start where the previous segment ended
        if head.kind == "line" {
          new.last().push(pts.first())
        } else {
          new.push(line-segment((segment-end(head), segment-start(s))))
        }
        // Push the segment
        new.push(s)
      } else {
        new.push(s)
      }
    }
  }
  return new
}

/// Shortens a segment by a given distance.
/// - segment (segment): The segment to shorten.
/// - distance (float): The distance to move the start of the segment towards the end of the segment. If this value is negative, the end of the segment will be moved towards the start.
/// - snap-to (none, vector): Shortening bezier curves suffers from rounding and precision errors so a position can be given to "snap" a curve's start/end point to.
/// - mode (str): How cubic segments should be shortned. Can be `"LINEAR"` to use `bezier.cubic-shorten-linear` or `"CURVED"` to use `bezier.cubic-shorten`.
/// - samples (int): The number of samples to use when shortening a cubic segment.
/// -> segment
#let shorten-segment(segment, distance, snap-to: none, mode: "CURVED", samples: default-samples) = {
  let rev = distance < 0
  if distance >= _segment-length(segment) {
    return line-segment(if rev {
      (segment-start(segment), segment-start(segment))
    } else {
      (segment-end(segment), segment-end(segment))
    })
  }

  let kind = segment.kind
  let pts = segment.points
  if kind == "line" {
    if rev {
      distance *= -1
      pts = pts.rev()
    }
    let (start, end, distance, length) = _points-between-distance(pts, distance)
    if length != 0 {
      pts = (vector.lerp(pts.at(start), pts.at(end), distance / length),) + pts.slice(end)
    }

    if rev {
      pts = pts.rev()
    }
  } else {
    pts = if mode == "LINEAR" {
      bezier.cubic-shorten-linear(..pts, distance)
    } else {
      bezier.cubic-shorten(..pts, distance, samples: samples)
    }

    // Shortening beziers suffers from rounding or precision errors
    // so we "snap" the curve start/end to the snap-points, if provided.
    if snap-to != none {
      if rev { pts.at(1) = snap-to } else { pts.at(0) = snap-to }
    }
  }
  return (kind: kind, points: pts)
}

/// Shortens a path's segments by the given distances. The start of the path is shortened first by moving the point along the path towards the end. The end of the path is then shortened in the same way. When a distance is 0 no other calculations are made.
/// 
/// - segments (segments): The segments of the path to shorten.
/// - start-distance (int, float): The distance to shorten from the start of the path.
/// - end-distance (int, float): The distance to shorten from the end of the path
/// - pos (none, tuple): Tuple of points to "snap" the path ends to
/// -> segments Segments of the path that have been shortened
#let shorten-path(segments, start-distance, end-distance, snap-to: none, mode: "CURVED", samples: default-samples) = {
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
      clamp: true,
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
      clamp: true,
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
