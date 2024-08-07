// Library for drawing springs
#import "/src/draw.typ"
#import "/src/styles.typ"
#import "/src/coordinate.typ"
#import "/src/vector.typ"
#import "/src/process.typ"
#import "/src/path-util.typ"
#import "/src/util.typ"
#import "/src/bezier.typ"

#let default-style = (
  /// Number of segments
  segments: 10,
  /// Length of a single segments
  segment-length: none,

  /// Amplitude of a segment in the direction of the segments normal
  amplitude: 1,
  /// Decoration start
  start: 0%,
  /// Decoration stop
  stop: 100%,
  /// Decoration alignment on the target path
  align: "START",
  /// Draw remaining space as line ("LINE") or none
  rest: "LINE",

  /// Up-vector for 3D lines
  z-up: (0, 1, 0),
  /// Up-vector for 2D lines
  xy-up: (0, 0, -1),

  stroke: auto,
  fill: none,
  mark: auto,
)

// Zig-Zag default style
#let zigzag-default-style = (
  ..default-style,
  /// Midpoint factor
  ///   0%: Sawtooth (up-down)
  ///  50%: Triangle
  /// 100%: Sawtooth (down-up)
  factor: 50%,
)

// Wave default style
#let wave-default-style = (
  ..default-style,
  /// Wave (catmull-rom) tension
  tension: .5,
)

// Coil default style
#let coil-default-style = (
  ..default-style,
  /// Coil "overshoot" factor
  factor: 150%,
)

#let resolve-style(ctx, segments, style) = {
  assert(not (style.segments == none and style.segment-length == none),
    message: "Only one of segments or segment-length must be set, while the other must be auto")
  assert(style.segments != none or style.segment-length != none,
    message: "Either segments or segment-length must be not equal to none")

  // Calculate absolute start/stop distances
  let len = path-util.length(segments)
  if type(style.start) == ratio {
    style.start = len * style.start / 100%
  }
  style.start = calc.max(0, calc.min(style.start, len))
  if type(style.stop) == ratio {
    style.stop = len * style.stop / 100%
  }
  style.stop = calc.max(0, calc.min(style.stop, len))

  if style.segment-length != none {
    // Calculate number of divisions
    let n = (style.stop - style.start) / style.segment-length
    style.segments = calc.floor(n)

    // Divides the rest between start, stop or both
    let r = (n - calc.floor(n)) * style.segment-length
    if style.align == "MID" {
      let m = (style.start + style.stop) / 2
      style.start = m - n * style.segment-length / 2
      style.stop = m + n * style.segment-length / 2
    } else if style.align == "STOP" {
      style.start = style.stop - n * style.segment-length
    } else if style.align == "START" {
      style.stop = style.start + n * style.segment-length
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

  let first = drawables.first()
  return (segments: first.segments, close: first.close)
}

// Add optional line elements from segments start to mid-path start
// and mid-path end to sgements end
#let finalize-path(ctx, segments, style, mid-path, close: false) = {
  let add = style.rest == "LINE" and not close

  let (ctx, drawables, ..) = process.many(ctx, mid-path)
  let mid-first = drawables.first().segments.first()
  let mid-last = drawables.last().segments.last()

  if add {
    let start = path-util.segment-start(segments.first())
    start = util.revert-transform(ctx.transform, start)

    let mid-start = path-util.segment-start(mid-first)
    mid-start = util.revert-transform(ctx.transform, mid-start)
    draw.line(start, mid-start, mark: none)
  }
  mid-path;
  if add {
    let end = path-util.segment-end(segments.last())
    end = util.revert-transform(ctx.transform, end)

    let mid-end = path-util.segment-end(mid-last)
    mid-end = util.revert-transform(ctx.transform, mid-end)
    draw.line(mid-end, end, mark: none)
  }
  // TODO: Add marks on path.
}

// Call callback `fn` for each decoration segment
// on path `segments`.
//
// The callback gets called with the following arguments:
//   - i Segment index
//   - start Segment start point
//   - end Segment end point
//   - norm Normal vector (length 1)
// Result values get returned as an array
#let _path-effect(ctx, segments, fn, close: false, style) = {
  let n = style.segments
  assert(n > 0,
    message: "Number of segments must be greater than 0")

  let (start, stop) = (style.start, style.stop)
  let inc = (stop - start) / n
  let pts = ()
  let len = path-util.length(segments)
  for i in range(0, n) {
    let p0 = path-util.point-on-path(segments, calc.max(start,
      start + inc * i))
    let p1 = path-util.point-on-path(segments, calc.min(stop,
      start + inc * (i + 1)))
    if p0 == p1 { continue }

    (p0, p1) = util.revert-transform(ctx.transform, p0, p1)

    let dir = vector.sub(p1, p0)
    let norm = vector.norm(vector.cross(dir, if p0.at(2) != p1.at(2) {
      style.z-up
    } else {
      style.xy-up
    }))

    pts += fn(i, p0, p1, norm)
  }
  return pts
}

/// Draw a zig-zag or saw-tooth wave along a path.
///
/// The number of tooths can be controlled via the `segments` or `segment-length` style key, and the width via `amplitude`.
///
/// ```typc example
/// line((0,0), (2,1), stroke: gray)
/// cetz.decorations.zigzag(line((0,0), (2,1)), amplitude: .25, start: 10%, stop: 90%)
/// ```
///
/// - target (drawable): Target path
/// - close (auto,bool): Close the path
/// - name (none,string): Element name
/// - ..style (style): Style
///
/// ## Styling
/// *Root*: `zigzag`
/// - factor (ratio) = 100%: Triangle mid between its start and end. Setting this to 0% leads to a falling sawtooth shape, while 100% results in a raising sawtooth.
#let zigzag(target, name: none, close: auto, ..style) = draw.get-ctx(ctx => {
  let style = styles.resolve(ctx, merge: style.named(),
    base: zigzag-default-style, root: "zigzag")

  let (segments, close) = get-segments(ctx, target)
  let style = resolve-style(ctx, segments, style)
  let num-segments = style.segments

  // Return points for a zigzag line
  //
  //     m1          ▲
  //    /  \         │ Up
  // ..a....\....b.. '
  //         \  /
  //          m2
  //   |--|
  //    q-dir (quarter length between a and b)
  //
  // For the first/last segment, a/b get added. For all
  // other segments we only have to add m1 and m2 to the
  // list of points for the line-strip.
  let fn(i, a, b, norm) = {
    let ab = vector.sub(b, a)

    let f = .25 - (50% - style.factor) / 50% * .25
    let q-dir = vector.scale(ab, f)
    let up = vector.scale(norm, style.amplitude / 2)
    let down = vector.scale(up, -1)

    let m1 = vector.add(vector.add(a, q-dir), up)
    let m2 = vector.add(vector.sub(b, q-dir), down)

    return if not close and i == 0 {
      (a, m1, m2) // First segment: add a
    } else if not close and i == num-segments - 1 {
      (m1, m2, b) // Last segment: add b
    } else {
      (m1, m2)
    }
  }

  let pts = _path-effect(ctx, segments, fn, close: close, style)
  return draw.merge-path(
    finalize-path(ctx, segments, style,
      draw.line(..pts, name: name, ..style, mark: none),
      close: close),
    close: close,
    ..style)
})

/// Draw a stretched coil/loop spring along a path
///
/// The number of windings can be controlled via the `segments` or `segment-length` style key, and the width via `amplitude`.
///
/// ```typc example
/// line((0,0), (2,1), stroke: gray)
/// cetz.decorations.coil(line((0,0), (2,1)), amplitude: .25, start: 10%, stop: 90%)
/// ```
/// - target (drawable): Target path
/// - close (auto,bool): Close the path
/// - name (none,string): Element name
/// - ..style (style): Style
///
/// ## Styling
/// *Root*: `coil`
/// - factor (ratio) = 150%: Factor of how much the coil overextends its length to form a curl.
#let coil(target, close: auto, name: none, ..style) = draw.get-ctx(ctx => {
  let style = styles.resolve(ctx, merge: style.named(),
    base: coil-default-style, root: "coil")

  let (segments, close) = get-segments(ctx, target)
  let style = resolve-style(ctx, segments, style)

  let num-segments = calc.max(style.segments, 1)
  let length = path-util.length(segments)
  let phase-length = length / num-segments
  let overshoot = calc.max(0, (style.factor - 100%) / 100% * phase-length)

  // Offset both control points so the curve approximates
  // an elliptic arc
  let ellipsize-cubic(s, e, c1, c2) = {
    let m = vector.scale(vector.add(c1, c2), .5)
    let d = vector.sub(e, s)

    c1 = vector.sub(m, vector.scale(d, .5))
    c2 = vector.add(m, vector.scale(d, .5))

    return (s, e, c1, c2)
  }

  // Return a list of drawables to form a coil-like loop
  //
  //     ____     ┐
  //    /    \    │ Upper curve
  //   |      |   ┘
  // ..a...b..|.. ┐ Lower curve
  //        \_/   ┘
  //
  //       └──┘
  //         Overshoot
  //
  let fn(i, a, b, norm) = {
    let ab = vector.sub(b, a)
    let up = vector.scale(norm, style.amplitude / 2)
    let dist = vector.dist(a, b)

    let d = vector.norm(ab)
    let overshoot-at(i) = if num-segments <= 1 {
      0
    } else if close {
      overshoot / 2
    } else {
      i / (num-segments - 1) * overshoot
    }

    let next-a = vector.sub(b, vector.scale(d, overshoot-at(i + 1)))
    let a = vector.sub(a, vector.scale(d, overshoot-at(i)))
    let b = vector.add(b, vector.scale(d, overshoot-at(num-segments - i)))
    let m = vector.scale(vector.add(a, b), .5)
    let m-up = vector.add(m, up)
    let m-down = vector.sub(vector.scale(vector.add(next-a, b), .5), up)

    let upper = bezier.cubic-through-3points(a, m-up, b)
    upper = ellipsize-cubic(..upper)

    let lower = bezier.cubic-through-3points(b, m-down, next-a)
    lower = ellipsize-cubic(..lower)

    if i < num-segments - 1 or close {
      return (
        draw.bezier(..upper, mark: none),
        draw.bezier(..lower, mark: none),
      )
    } else {
      return (draw.bezier(..upper, mark: none),)
    }
  }

  return draw.merge-path(
    finalize-path(ctx, segments, style,
      _path-effect(ctx, segments, fn, close: close, style).flatten(),
      close: close),
    ..style,
    name: name,
    close: close)
})

/// Draw a wave along a path using a catmull-rom curve
///
/// The number of phases can be controlled via the `segments` or `segment-length` style key, and the width via `amplitude`.
///
/// ```typc example
/// line((0,0), (2,1), stroke: gray)
/// cetz.decorations.wave(line((0,0), (2,1)), amplitude: .25, start: 10%, stop: 90%)
/// ```
///
/// - target (drawable): Target path
/// - close (auto,bool): Close the path
/// - name (none,string): Element name
/// - ..style (style): Style
///
/// ## Styling
/// *Root*: `wave`
///
/// - tension (float) = 0.5 Catmull-Rom curve tension, see [Catmull](/api/draw-functions/shapes/catmull)
#let wave(target, close: auto, name: none, ..style) = draw.get-ctx(ctx => {
  let style = styles.resolve(ctx, merge: style.named(),
    base: wave-default-style, root: "wave")

  let (segments, close) = get-segments(ctx, target)
  let style = resolve-style(ctx, segments, style)
  let num-segments = style.segments

  // Return a list of points for the catmull-rom curve
  //
  //   ╭ ma ╮        ▲
  //   │    │        │ Up
  // ..a....m....b.. '
  //        │    │
  //        ╰ mb ╯
  //
  let fn(i, a, b, norm) = {
    let ab = vector.sub(b, a)
    let up = vector.scale(norm, style.amplitude / 2)
    let down = vector.scale(
      up, -1)

    let ma = vector.add(vector.add(a, vector.scale(ab, .25)), up)
    let m  = vector.add(a, vector.scale(ab, .50))
    let mb = vector.add(vector.sub(b, vector.scale(ab, .25)), down)

    if not close {
      if i == 0 {
        return (a, ma, mb)
      } else if i == num-segments - 1 {
        return (ma, mb, b,)
      }
    }

    return (ma, mb)
  }

  return draw.merge-path(
    finalize-path(ctx, segments, style, draw.catmull(
      .._path-effect(ctx, segments, fn, close: close, style),
      close: close), close: close) ,
    name: name,
    close: close,
    ..style)
})
