#import "../draw.typ"
#import "../cmd.typ"
#import "../styles.typ"
#import "../vector.typ"
#import "../util.typ"

// Angle default-style
#let default-style = (
  fill: none,
  stroke: auto,
  radius: .5,
  label-radius: .25,
  mark: (
    start: none,
    end: none,
    size: auto,
    fill: none,
    stroke: auto,
  )
)

/// Draw an angle between origin-a and origin-b
/// Only works for coordinates with z = 0!
///
/// *Anchors:*
///   / start: Arc starting point
///   / end: Arc end point
///   / origin: Arc origin
///   / label: Label center
///
/// - origin (coordinate): Angle corner origin
/// - a (coordinate): First coordinate
/// - b (coordinate): Second coordinate
/// - inner (bool): Draw inner `true` or outer `false` angle
/// - label (content,function,none): Angle label/content or function of the form `angle => content` that receives the angle and must return a content object
/// - ..style (style): Angle style
#let angle(origin, a, b,
           inner: true,
           label: none,
           name: none, ..style) = {
  let start-end(origin, a, b) = {
    assert(origin.at(2, default: 0) == 0 and
           a.at(2, default: 0) == 0 and
           b.at(2, default: 0) == 0,
           message: "FIXME: Angle only works for 2D coordinates.")

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

  let style = style.named()
  ((
    name: name,
    default-anchor: "label",
    coordinates: (origin, a, b),
    transform-coordinates: (ctx, origin, a, b) => {
      let style = util.merge-dictionary(default-style,
        styles.resolve(ctx.style, style, root: "angle"))
      let (s, e, ss) = start-end(origin, a, b)
      let (x, y, z) = origin
      let (r, _) = util.resolve-radius(style.radius)
        .map(util.resolve-number.with(ctx))
      let (ra, _) = util.resolve-radius(style.label-radius)
        .map(util.resolve-number.with(ctx))

      let start = (x + r * calc.cos(s),
                   y + r * calc.sin(s), z)
      let end = (x + r * calc.cos(e),
                 y + r * calc.sin(e), z)

      let label = (x + ra * calc.cos(ss),
                   y + ra * calc.sin(ss), z)

      (origin, a, b, start, end, label)
    },
    custom-anchors-ctx: (ctx, origin, a, b, start, end, label) => {
      (origin: origin,
       a: a,
       b: b,
       start: start,
       end: end,
       label: label,
      )
    },
    render: (ctx, origin, a, b, start, end, pt-label) => {
      let style = util.merge-dictionary(default-style,
        styles.resolve(ctx.style, style, root: "angle"))
      let (s, e, _) = start-end(origin, a, b)
      let (r, _) = util.resolve-radius(style.radius)
        .map(util.resolve-number.with(ctx))

      let (x, y, z) = start
      if style.fill != none {
        cmd.arc(x, y, z, s, e, r, r,
          mode: "PIE", fill: style.fill, stroke: none)
      }
      if style.stroke != none {
        cmd.arc(x, y, z, s, e, r, r,
          mode: "OPEN", fill: none, stroke: style.stroke)
      }

      if style.mark.start != none {
        let f = vector.add(vector.scale(
          (calc.cos(s + 90deg), calc.sin(s + 90deg), 0), style.mark.size),
          start)
        cmd.mark(f, start, style.mark.start,
          fill: style.mark.fill, stroke: style.mark.stroke)
      }
      if style.mark.end != none {
        let f = vector.add(vector.scale(
          (calc.cos(e - 90deg), calc.sin(e - 90deg), 0), style.mark.size),
          end)
        cmd.mark(f, end, style.mark.end,
          fill: style.mark.fill, stroke: style.mark.stroke)
      }

      let label = if type(label) == function {
        label(e - s)
      } else { label }
      if label != none {
        let (lx, ly, ..) = pt-label
        let (w, h) = draw.measure(label, ctx)
        let (width: width, height: height) = draw.typst-measure(label,
          ctx.typst-style)
        cmd.content(
          lx, ly, w, h,
          move(dx: -width/2,
               dy: -height/2,
               label))
      }
    },
  ),)
}
