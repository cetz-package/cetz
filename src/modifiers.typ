#import "/src/styles.typ"
#import "/src/path-util.typ"
#import "/src/bezier.typ" as bezier_
#import "/src/vector.typ"
#import "/src/drawable.typ"
#import "/src/util.typ"

// Call callback `fn` for each decoration segment
// on path `segments`.
//
// The callback gets called with the following arguments:
//   - i Segment index
//   - start Segment start point
//   - end Segment end point
//   - norm Normal vector (length 1)
// Result values get returned as an array
#let _n-segment-effect(ctx, segments, fn, close: false, style) = {
  let n = style.at("segments", default: 10)
  assert(n > 0,
    message: "Number of segments must be greater than 0")

  let inc = 100% / n
  let pts = ()
  let len = path-util.length(segments)
  for i in range(0, n) {
    let p0 = path-util.point-on-path(segments, calc.max(0%,
      inc * i))
    let p1 = path-util.point-on-path(segments, calc.min(100%,
      inc * (i + 1)))
    if p0 == p1 { continue }

    let dir = vector.sub(p1, p0)
    let norm = vector.norm(vector.cross(dir, if p0.at(2) != p1.at(2) {
      style.at("z-up", default: (0, 1, 0))
    } else {
      style.at("xy-up", default: (0, 0, -1))
    }))

    pts += fn(i, p0, p1, norm)
  }
  return pts
}


#let linearize-default-style = (
  samples: 3,
)

/// Path modifier that linearizes bezier segments
/// by sampling n points along the curve.
#let linearize(ctx, style, segments, close) = {
  let style = styles.resolve(ctx.style, merge: style,
    base: linearize-default-style)
  let samples = calc.max(2, int(style.samples))

  let new = ()
  for s in segments {
    let kind = s.first()
    if kind == "cubic" {
      let pts = s.slice(1)
      new.push(path-util.line-segment(range(0, samples).map(i => {
        let t = calc.min(1, 1 / (samples - 1) * i)
        bezier_.cubic-point(..pts, t)
      })))
    } else {
      new.push(s)
    }
  }
  return (replacement: new)
}


#let wave-default-style = (
  tension: .5,
  amplitude: 1,
  segments: 10,
)

// Draw a wave along a path using a catmull-rom curve
#let wave(ctx, style, segments, close) = {
  let style = styles.resolve(ctx.style, merge: style,
    base: wave-default-style)
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

  let pts = _n-segment-effect(ctx, segments, fn, style, close: close)
  return (
    replacement: bezier_.catmull-to-cubic(pts, style.tension, close: close).map(c => {
      path-util.cubic-segment(..c)
    })
  )
}



#let ticks-default-style = (
  step: 10%,
  length: 1,
  origin: 50%,
  replace: false,
)

// Draw tick-marks along a path
#let ticks(ctx, style, segments, close) = {
  let style = styles.resolve(ctx.style, merge: style,
    base: ticks-default-style)

  let length = path-util.length(segments)
  let step = if type(style.step) == ratio {
    length * style.step / 100%
  } else {
    util.resolve-number(ctx, style.step)
  }

  assert(step > 1e-6,
    message: "Tick step must be > 0!")

  let tick-segments = ()

  let distance = 0
  while distance <= length {
    let (pt, dir) = path-util.direction(segments, distance)

    // Compute the tangent normal
    let norm = vector.scale(vector.norm((-dir.at(1), dir.at(0), dir.at(2))),
      style.length)

    // Compute points
    let p0 = vector.add(pt, vector.scale(norm, -style.origin / 100%))
    let p1 = vector.add(pt, vector.scale(norm, (100% - style.origin) / 100%))

    tick-segments.push(path-util.line-segment((p0, p1)))

    distance += step
  }

  return (
    replacement: if style.replace { none } else { segments },
    decoration: tick-segments.map(s => {
      drawable.path(s, stroke: style.stroke)
    }))
}
