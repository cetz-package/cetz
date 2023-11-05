#import "../drawable.typ"
#import "../styles.typ"
#import "../vector.typ"
#import "../util.typ"
#import "../coordinate.typ"
#import "../anchor.typ" as anchor_

// Angle default-style
#let default-style = (
  fill: none,
  stroke: auto,
  radius: .5,
  label-radius: .25,
  mark: styles.default.mark,
)

#let angle(
  origin,
  a,
  b,
  inner: true,
  label: none,
  name: none,
  ..style
) = {
  let style = style.named()

  return (ctx => {
    let style = styles.resolve(ctx.style, style, root: "angle", base: default-style)
    let (ctx, origin, a, b) = coordinate.resolve(ctx, origin, a, b)
    assert(
      origin.at(2, default: 0) == 0 and
      a.at(2, default: 0) == 0 and
      b.at(2, default: 0) == 0,
      message: "FIXME: Angle only works for 2D coordinates."
    )
    let (s, e, ss) = {
      let s = vector.angle2(origin, a) * -1
      if s < 0deg { s += 360deg }
      let e = vector.angle2(origin, b) * -1
      if e < 0deg { e += 360deg }

      if s > e {
        (s, e) = (e, s)
      }

      if inner == true {
        let d = vector.angle(a, origin, b) 
        if e - s > 180deg {
          (s, e) = (e, e + d)
        } else {
          (s, e) = (s, s + d)
        }
      } else if inner == false {
        if e - s < 180deg {
          let d = 360deg - vector.angle(a, origin, b) 
          (s, e) = (e, e + d)
        }
      }
      (s, e, (s + e) / 2)
    }
    let (x, y, z) = origin
    let (r, _) = util.resolve-radius(style.radius).map(util.resolve-number.with(ctx))
    let (ra, _) = util.resolve-radius(style.label-radius).map(util.resolve-number.with(ctx))
    let start = (x + r * calc.cos(s), y + r * calc.sin(s), z)
    let end = (x + r * calc.cos(e), y + r * calc.sin(e), z)
    let pt-label = (x + ra * calc.cos(ss), y + ra * calc.sin(ss), z)

    let drawables = ()

    let (marks, draw-pt, draw-s, draw-e) = if style.mark != none {
      import "/src/mark.typ" as mark_
      mark_.place-marks-along-arc(ctx, s, e, start, r, r, style, style.mark)
    } else {
      (none, start, s, e)
    }
    if style.fill != none {
      drawables.push(
        drawable.arc(..draw-pt, draw-s, draw-e, r, r, mode: "PIE", fill: style.fill, stroke: none)
      )
    }
    if style.stroke != none {
      drawables.push(
        drawable.arc(..draw-pt, draw-s, draw-e, r, r, mode: "OPEN", fill: none, stroke: style.stroke)
      )
    }
    if marks != none {
      drawables += marks
    }

    let (x, y, z) = start
    let label = if type(label) == function { label(e - s) } else { label }
    if label != none {
      let (lx, ly, ..) = pt-label
      let (w, h) = util.measure(ctx, label)
      drawables.push(
        drawable.content(
          (lx, ly, 0),
          w, 
          h,
          label
        )
      )
    }

    let (transform, anchors) = anchor_.setup(
      anchor => {
        (
          origin: origin,
          a: a,
          b: b,
          start: start,
          end: end,
          label: pt-label
        ).at(anchor)
      },
      ("origin", "a", "b", "start", "end", "label"),
      transform: ctx.transform,
      name: name,
      default: "label"
    )

    return (
      ctx: ctx,
      name: name,
      anchors: anchors,
      drawables: drawable.apply-transform(
        transform,
        drawables
      )
    )
  },)
}
