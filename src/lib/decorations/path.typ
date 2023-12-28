// Library for drawing springs
#import "/src/draw.typ"
#import "/src/styles.typ"
#import "/src/coordinate.typ"
#import "/src/vector.typ"
#import "/src/process.typ"
#import "/src/path-util.typ"
#import "/src/util.typ"

#let default-style = (
  /// Number of windings
  N: 10,
  length: none,

  /// width of the spring in the direction of the springs normal
  width: 1,
  /// Decoration start
  start: 0%,
  /// Decoration stop
  stop: 100%,
  /// Decoration alignment on the target path
  align: "START",
  /// Draw remaining space as line ("LINE") or none
  rest: "LINE",

  stroke: auto,
  fill: none,
)

#let zigzag-default-style = (
  ..default-style,
  /// Midpoint factor
  ///   0%: Sawtooth (up-down)
  ///  50%: Triangle
  /// 100%: Sawtooth (down-up)
  factor: 50%,
)

#let wave-default-style = (
  ..default-style,
  /// Wave (catmull-rom) tension
  tension: .5,
)

#let coil-default-style = (
  ..default-style,
  /// Coil "overshoot" factor
  factor: 1.5,
)

#let resolve-style(ctx, segments, style) = {
  assert(not (style.N == none and style.length == none),
    message: "Only one of N or length must be set, while the other must be auto")
  assert(style.N != none or style.length != none,
    message: "Either N or length must be not equal to none")

  // Calculate absolute start/stop distances
  let len = path-util.length(segments)
  if type(style.start) == ratio {
    style.start = len * style.start / 100%
  }
  if type(style.stop) == ratio {
    style.stop = len * style.stop / 100%
  }

  if style.length != none {
    // Calculate number of divisions
    let n = calc.min(style.stop - style.start, len) / style.length
    style.N = calc.floor(n)

    // Divides the rest between start, stop or both
    let r = n - calc.floor(n)
    if style.align == "MID" {
      style.start += r / 2
      style.stop += r / 2
    } else if style.align == "STOP" {
      style.start = r
    } else if style.align == "START" {
      style.stop = len - r
    }
  }

  return style
}

#let get-segments(ctx, target) = {
  if type(target) == array {
    assert.eq(target.len(), 1,
      message: "Expected a single element, got " + str(target.len()))
    target = target.first()
  }

  let (ctx, drawables, ..) = process.element(ctx, target)
  if drawables == none or drawables == () {
    return ()
  }

  return drawables.first().segments
}

/// Detect if path segments are closed
#let resolve-auto-close(segments, start, stop) = {
  return vector.dist(path-util.point-on-path(segments, start),
                     path-util.point-on-path(segments, stop)) < 1e-8
}

#let _path-effect(ctx, segments, fn, close: false, style) = {
  let n = style.N
  assert(n > 0,
    message: "Number of segments must be greater than 0")

  let (start, stop) = (style.start, style.stop)
  let inc = (stop - start) / n
  let pts = ()
  for i in range(0, n) {
    let p0 = path-util.point-on-path(segments, start + inc * i)
    let p1 = path-util.point-on-path(segments, start + inc * (i + 1))
    if p0 == p1 { continue }

    (p0, p1) = util.revert-transform(ctx.transform, p0, p1)
    let dir = vector.sub(p1, p0)
    let up = vector.scale(vector.norm((-dir.at(1), dir.at(0), dir.at(2))), style.width / 2)
    let down = vector.scale(up, -1)

    pts += fn(i, p0, p1)
  }
  return pts
}

/// Draw a zig-zag spring between two points
///
/// The number of windings can be controlled via the `N` style key,
/// and the width via `width`.
///
/// - target (drawable): Target path
/// - ..style: (style): Style
#let zigzag(target, name: none, close: auto, ..style) = draw.get-ctx(ctx => {
  let style = styles.resolve(ctx, merge: style.named(),
    base: zigzag-default-style, root: "zigzag")

  let segments = get-segments(ctx, target)
  let style = resolve-style(ctx, segments, style)
  let close = if close == auto {
    resolve-auto-close(segments, style.start, style.stop)
  } else {
    close
  }

  let N = style.N

  let fn(i, a, b) = {
    let ab = vector.sub(b, a)
    let norm = vector.norm((-ab.at(1), ab.at(0), ab.at(2)))

    let f = .25 - (50% - style.factor) / 50% * .25
    let q-dir = vector.scale(ab, f)
    let up = vector.scale(norm, style.width / 2)
    let down = vector.scale(up, -1)

    let m1 = vector.add(vector.add(a, q-dir), up)
    let m2 = vector.add(vector.sub(b, q-dir), down)

    return if not close and i == 0 {
      (a, m1, m2)
    } else if not close and i == N - 1 {
      (m1, m2, b)
    } else {
      (m1, m2)
    }
  }

  let pts = _path-effect(ctx, segments, fn, close: close, style)
  draw.line(..pts, name: name, close: close, ..style)
})

/// Draw a stretched coil/loop spring
///
/// The number of windings can be controlled via the `N` or `length` style key,
/// and the width via `width`.
///
/// - start (coordinate): Start point
/// - end (coordinate): End point
/// - name: (none,string): Element name
/// - ..style: (style): Style
#let coil(target, close: auto, name: none, ..style) = draw.get-ctx(ctx => {
  let style = styles.resolve(ctx, merge: style.named(),
    base: coil-default-style, root: "coil")

  let segments = get-segments(ctx, target)
  let style = resolve-style(ctx, segments, style)
  let close = if close == auto {
    resolve-auto-close(segments, style.start, style.stop)
  } else {
    close
  }

  let N = style.N
  let sin150x2 = calc.sin(150deg) * 2
  let overshoot = calc.max(0, style.factor)

  let fn(i, a, b) = {
    let ab = vector.sub(b, a)
    let up = vector.scale(
      vector.norm((-ab.at(1), ab.at(0), ab.at(2))), style.width)

    let angle = vector.angle2(a, b)
    let dist = vector.dist(a, b)

    let m = vector.scale(vector.add(a, b), .5)
    if not close and i == N - 1 {
      return draw.bezier-through(a, vector.add(m, vector.scale(up, 1/3)), b)
    }

    let e = vector.add(a, vector.scale(ab, (i + overshoot) / N))
    return draw.group({
      draw.translate(vector.scale(a, 1))
      draw.rotate(z: angle)
      draw.arc((0,0,0), start: 150deg, delta: -120deg, radius: (dist * overshoot / 1.732, style.width / sin150x2))
      draw.arc((dist,0,0), start: 30deg, delta: -240deg, radius: (dist * (overshoot - 1) / 1.732, style.width / sin150x2 / 3), anchor: "end")
    })
  }

  return draw.merge-path(
    _path-effect(ctx, segments, fn, close: close, style).flatten(),
    ..style,
    name: name,
    close: close)
})

/// Draw a stretched wave/sine spring
///
/// The number of windings can be controlled via the `N` or `length` style key,
/// and the width via `width`.
///
/// - start (coordinate): Start point
/// - end (coordinate): End point
/// - name: (none,string): Element name
/// - ..style: (style): Style
#let wave(target, close: auto, name: none, ..style) = draw.get-ctx(ctx => {
  let style = styles.resolve(ctx, merge: style.named(),
    base: wave-default-style, root: "wave")

  let segments = get-segments(ctx, target)
  let style = resolve-style(ctx, segments, style)
  let close = if close == auto {
    resolve-auto-close(segments, style.start, style.stop)
  } else {
    close
  }

  let N = style.N

  let fn(i, a, b) = {
    let ab = vector.sub(b, a)
    let up = vector.scale(
      vector.norm((-ab.at(1), ab.at(0), ab.at(2))), style.width / 2)
    let down = vector.scale(
      up, -1)

    let ma = vector.add(a, vector.scale(ab, .25))
    let m  = vector.add(a, vector.scale(ab, .50))
    let mb = vector.sub(b, vector.scale(ab, .25))

    if not close {
      if i == 0 {
        return (a, vector.add(ma, up), vector.add(mb, down),)
      } else if i == N - 1 {
        return (vector.add(ma, up), vector.add(mb, down), b,)
      }
    }

    return (vector.add(ma, up), vector.add(mb, down),)
  }

  return draw.catmull(
    .._path-effect(ctx, segments, fn, close: close, style),
    ..style,
    name: name,
    close: close)
})
