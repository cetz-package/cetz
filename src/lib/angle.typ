#import "../drawable.typ"
#import "../styles.typ"
#import "../vector.typ"
#import "../util.typ"
#import "../coordinate.typ"

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
    let (ctx, coordinates) = coordinate.resolve-many(ctx, (origin, a, b))
    let (origin, a, b) = coordinates
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

    let (x, y, z) = start
    if style.fill != none {
      drawables.push(
        drawable.arc(x, y, z, s, e, r, r, mode: "PIE", fill: style.fill, stroke: none)
      )
    }
    if style.stroke != none {
      drawables.push(
        drawable.arc(x, y, z, s, e, r, r, mode: "OPEN", fill: none, stroke: style.stroke)
      )
    }

    if style.mark.start != none {
      let f = vector.add(
        vector.scale(
          (
            calc.cos(s + 90deg), 
            calc.sin(s + 90deg), 
            0
          ), 
          style.mark.size
        ),
        start
      )
      drawables.push(
        drawable.mark(
          f,
          start,
          style.mark.start,
          style.mark.size,
          fill: style.mark.fill,
          stroke: style.mark.stroke
        )
      )
    }
    if style.mark.end != none {
      let f = vector.add(
        vector.scale(
          (
            calc.cos(e - 90deg), 
            calc.sin(e - 90deg), 
            0
          ), 
          style.mark.size
        ),
        end
      )
      drawables.push(
        drawable.mark(f, end, style.mark.end, style.mark.size, fill: style.mark.fill, stroke: style.mark.stroke)
      )
    }

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



    return (
      ctx: ctx,
      name: name,
      anchors: util.apply-transform-many(ctx.transform, (
        origin: origin,
        a: a,
        b: b,
        start: start,
        end: end,
        label: pt-label
      )),
      default-anchor: "label",
      drawables: drawable.apply-transform(
        ctx.transform,
        drawables
      )
    )
  },)
}