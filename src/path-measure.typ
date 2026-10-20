#import "vector.typ"
#import "bezier.typ"
#import "path-util.typ"

// Return the first end past distance. Fall back to the last end.
// At a join, pick the outgoing segment.
#let _index(ends, distance, reverse: false) = {
  let (lo, hi) = (0, ends.len() - 1)
  while lo < hi {
    let mid = calc.quo(lo + hi, 2)
    if ends.at(mid) < distance or (not reverse and ends.at(mid) == distance) {
      lo = mid + 1
    } else {
      hi = mid
    }
  }
  lo
}

// Subdivide until chord and control polygon agree within the error budget.
// Each interval gets a proportional share of the total budget.
// Stop when midpoints stall in floating point.
#let _flatten(curve, precision) = {
  let (s, e, c1, c2) = curve
  let scale = vector.dist(s, c1) + vector.dist(c1, c2) + vector.dist(c2, e)
  if scale == 0 { return ((s,), (0,), ()) }

  let points = (s,)
  let ts = (0,)
  let steps = ()
  let stack = ((curve, 0, 1),)
  while stack != () {
    let (part, t0, t1) = stack.pop()
    let (a, b, p1, p2) = part
    let chord = vector.dist(a, b)
    let polygon = vector.dist(a, p1) + vector.dist(p1, p2) + vector.dist(p2, b)
    let length-budget = scale * precision * (t1 - t0)
    let tm = (t0 + t1) / 2
    if polygon - chord <= length-budget or tm == t0 or tm == t1 {
      points.push(b)
      ts.push(t1)
      // Mean of the bounds. This halves the worst-case error.
      steps.push((chord + polygon) / 2)
    } else {
      let (left, right) = bezier.split(..part, .5)
      stack.push((right, tm, t1))
      stack.push((left, t0, tm))
    }
  }
  (points, ts, steps)
}

// A doubled control point has zero derivative. Fall back to the first
// nonzero control edge, then to the chord.
#let _direction(piece, t, chord) = {
  if piece.curve == none { return vector.norm(chord) }
  let (s, e, c1, c2) = piece.curve
  let direction = bezier.cubic-derivative(..piece.curve, t)
  if vector.len(direction) == 0 {
    let edges = if t == 0 {
      (vector.sub(c1, s), vector.sub(c2, s), vector.sub(e, s))
    } else if t == 1 {
      (vector.sub(e, c2), vector.sub(e, c1), vector.sub(e, s))
    } else { () }
    direction = edges.find(v => vector.len(v) > 0)
    if direction == none { direction = chord }
  }
  vector.norm(direction)
}

// One measure per subpath. Distances never cross an undrawn gap.
#let build(path, corner-threshold: 30deg, precision: 1e-6) = {
  assert(type(corner-threshold) == angle and corner-threshold >= 0deg and corner-threshold <= 180deg,
    message: "path-measure: corner-threshold must be between 0deg and 180deg")
  assert(type(precision) in (int, float) and precision > 0 and precision < 1,
    message: "path-measure: precision must be between zero and one")

  path.map(((origin, closed, segments)) => {
    let origin = vector.as-vec(origin, init: (0, 0, 0))
    assert(origin.all(v => type(v) in (int, float) and calc.abs(v) < calc.inf),
      message: "path-measure: coordinates must be finite numbers")
    let (plane-z, xy-planar) = (origin.at(2), true)
    // Expand strips first. A strip ending at its origin is not zero-length.
    let expanded = ()
    for (kind, ..args) in segments {
      args = args.map(p => vector.as-vec(p, init: (0, 0, 0)))
      assert(args.flatten().all(v => type(v) in (int, float) and calc.abs(v) < calc.inf),
        message: "path-measure: coordinates must be finite numbers")
      if args.any(p => p.at(2) != plane-z) { xy-planar = false }
      if kind == "l" {
        expanded += args.map(p => ("l", p))
      } else {
        assert(kind == "c" and args.len() == 3,
          message: "path-measure: expected a line or cubic segment")
        expanded.push((kind, ..args))
      }
    }
    let (_, _, segments) = path-util.normalize(((origin, closed, expanded),)).first()
    let (pieces, ends, corners) = ((), (), ())
    let total = 0
    let current = origin
    for (kind, ..args) in segments {
      let curve = if kind == "c" { (current, args.at(2), args.at(0), args.at(1)) }
      let (points, ts, steps) = if curve == none {
        let endpoint = args.first()
        ((current, endpoint), (0, 1), (vector.dist(current, endpoint),))
      } else { _flatten(curve, precision) }
      current = args.last()
      let lengths = ()
      let distance = 0
      let kept-points = (points.first(),)
      let kept-ts = (0,)
      for (i, step) in steps.enumerate() {
        let next-distance = distance + step
        if next-distance == distance { continue }
        distance = next-distance
        lengths.push(distance)
        kept-points.push(points.at(i + 1))
        kept-ts.push(ts.at(i + 1))
      }
      let end = total + distance
      if end == total { continue }
      pieces.push((curve: curve, points: kept-points, ts: kept-ts,
        lengths: lengths, start: total, precision: precision))
      total = end
      ends.push(total)
    }

    // Corners are source joins only, not subdivision points.
    for i in range(pieces.len()) {
      if i == 0 and (not closed or pieces.len() == 0) { continue }
      let previous = pieces.at(if i == 0 { -1 } else { i - 1 })
      let next = pieces.at(i)
      let a = _direction(previous, 1, vector.sub(previous.points.last(), previous.points.at(-2)))
      let b = _direction(next, 0, vector.sub(next.points.at(1), next.points.first()))
      let turn = calc.acos(calc.clamp(vector.dot(a, b), -1, 1))
      let cross = a.first() * b.at(1) - a.at(1) * b.first()
      let side = if cross > 0 { 1 } else if cross < 0 { -1 } else { 0 }
      if turn > corner-threshold { corners.push((s: next.start, angle: turn, side: side)) }
    }
    (total: total, pieces: pieces, ends: ends, corners: corners,
      closed: closed, xy-planar: xy-planar)
  })
}

// Sample point and unit tangent in one subpath. Clamp distances.
// Reverse flips the tangent. Zero-length paths return none.
#let point-at(measure, distance, reverse: false) = {
  if measure.total == 0 { return none }
  if type(distance) == ratio { distance = measure.total * distance / 100% }
  assert(type(distance) in (int, float) and calc.abs(distance) < calc.inf,
    message: "path-measure: distance must be a finite number or ratio")
  if reverse { distance = measure.total - distance }
  distance = calc.clamp(distance, 0, measure.total)
  let piece = measure.pieces.at(_index(measure.ends, distance, reverse: reverse))
  let local = distance - piece.start
  let i = _index(piece.lengths, local, reverse: reverse)
  let start = if i == 0 { 0 } else { piece.lengths.at(i - 1) }
  let fraction = (local - start) / (piece.lengths.at(i) - start)
  let a = piece.points.at(i)
  let b = piece.points.at(i + 1)
  let (t0, t1) = (piece.ts.at(i), piece.ts.at(i + 1))
  let t = (1 - fraction) * t0 + fraction * t1
  if piece.curve != none {
    // Newton steps on the chord projection, guarded by bisection.
    let chord = vector.sub(b, a)
    let squared = vector.dot(chord, chord)
    if squared > 0 {
      let (lo, hi) = (t0, t1)
      for _ in range(8) {
        let projected = vector.dot(
          vector.sub(bezier.cubic-point(..piece.curve, t), a), chord) / squared
        let error = projected - fraction
        if calc.abs(error) <= piece.precision { break }
        if error < 0 { lo = t } else { hi = t }
        let slope = vector.dot(
          bezier.cubic-derivative(..piece.curve, t), chord) / squared
        let next = if slope > 0 { t - error / slope } else { (lo + hi) / 2 }
        if next <= lo or next >= hi { next = (lo + hi) / 2 }
        if next == t { break }
        t = next
      }
    }
  }
  let point = if piece.curve == none { vector.lerp(a, b, fraction) }
    else { bezier.cubic-point(..piece.curve, t) }
  let direction = _direction(piece, t, vector.sub(b, a))
  (point: point, direction: if reverse { vector.neg(direction) } else { direction })
}
