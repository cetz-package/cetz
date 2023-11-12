#import "../drawable.typ"
#import "../styles.typ"
#import "../vector.typ"
#import "../util.typ"
#import "../coordinate.typ"
#import "../anchor.typ" as anchor_
#import "/src/draw.typ"

// Angle default-style
#let default-style = (
  fill: none,
  stroke: auto,
  radius: .5,
  label-radius: .25,
  mark: styles.default.mark,
)

/// Draw an angle between `a` and `b` through origin `origin`
///
/// *Style Root:* `angle`
///
/// *Anchors*
/// / `"a"`: Point a
/// / `"b"`: Point b
/// / `"origin"`: Origin
/// / `"label"`: Label center
/// / `"start"`: Arc start
/// / `"end"`: Arc end
///
/// You can use the `radius` and `label-radius` style-keys to set
/// the angle and label radius.
///
/// - origin (coordinate): Angle origin
/// - a (coordinate): Coordinate of side a
/// - b (coordinate): Coordinate of side b
/// - inner (bool): Draw the smaller (inner) angle
/// - label (none,content,function): Draw a label at the angles "label" anchor.
///   If label is a function, it gets the angle value passed as argument.
/// - name: (none,string): Element value
/// - ..style (style): Style
#let angle(
  origin,
  a,
  b,
  inner: true,
  label: none,
  name: none,
  ..style
) = draw.group(name: name, ctx => {
  let style = styles.resolve(ctx.style, style.named(), base: default-style, root: "angle")
  let (ctx, origin, a, b) = coordinate.resolve(ctx, origin, a, b)

  assert(origin.at(2) == a.at(2) and a.at(2) == b.at(2),
    message: "Angle z coordinates of all three points must be equal")

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

  let (r, _) = util.resolve-radius(style.radius).map(util.resolve-number.with(ctx))
  let (ra, _) = util.resolve-radius(style.label-radius).map(util.resolve-number.with(ctx))

  let label-pt = vector.add(origin, (calc.cos(ss) * ra, calc.sin(ss) * ra, 0))
  let start-pt = vector.add(origin, (calc.cos(s) * r, calc.sin(s) * r, 0))
  let end-pt = vector.add(origin, (calc.cos(e) * r, calc.sin(e) * r, 0))
  draw.anchor("origin", origin)
  draw.anchor("label", label-pt)
  draw.anchor("start", start-pt)
  draw.anchor("end", end-pt)
  draw.anchor("a", a)
  draw.anchor("b", b)

  if s != e {
    if style.fill != none {
      draw.arc(origin, start: s, stop: e, anchor: "origin",
        name: "arc", ..style, radius: r, mode: "PIE", mark: none, stroke: none)
    }
    if style.stroke != none {
      draw.arc(origin, start: s, stop: e, anchor: "origin",
        name: "arc", ..style, radius: r, fill: none)
    }
  }

  let label = if type(label) == function { label(e - s) } else { label }
  if label != none {
    draw.content(label-pt, label)
  }
})
