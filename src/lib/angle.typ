#import "/src/drawable.typ"
#import "/src/styles.typ"
#import "/src/vector.typ"
#import "/src/util.typ"
#import "/src/coordinate.typ"
#import "/src/anchor.typ" as anchor_
#import "/src/draw.typ"

// Angle default-style
#let default-style = (
  fill: none,
  stroke: auto,
  radius: .5,
  label-radius: 50%,
  mark: auto,
)

/// Draw an angle between `a` and `b` through origin `origin`
///
/// #example(```
/// line((0,0), (1,1.5), name: "a")
/// line((0,0), (2,-1), name: "b")
///
/// // Draw an angle between the two lines
/// cetz.angle.angle("a.start", "a.end", "b.end", label: $ alpha $,
///   mark: (end: ">"), radius: 1.5)
/// cetz.angle.angle("a.start", "b.end", "a.end", label: $ alpha' $,
///   radius: 50%, inner: false)
/// ```)
///
/// *Style Root:* `angle`
///
/// *Style Keys:*
///   #show-parameter-block("radius", ("number"), [
///     The radius of the angles arc. If of type `ratio`, it is relative to the smaller distance of either origin to a or origin to b.], default: .5)
///   #show-parameter-block("label-radius", ("number", "ratio"), [
///     The radius of the angles label origin. If of type `ratio`, it is relative to `radius`.], default: 50%)
///
/// *Anchors*
/// / `"a"`: Point a
/// / `"b"`: Point b
/// / `"origin"`: Origin
/// / `"label"`: Label center
/// / `"start"`: Arc start
/// / `"end"`: Arc end
///
/// - origin (coordinate): Angle origin
/// - a (coordinate): Coordinate of side `a`, containing an angle between `origin` and `b`.
/// - b (coordinate): Coordinate of side `b`, containing an angle between `origin` and `a`.
/// - inner (bool): Draw the smaller (inner) angle if true, otherwise the outer angle gets drawn.
/// - label (none,content,function): Draw a label at the angles "label" anchor.
///   If label is a function, it gets the angle value passed as argument. The function must
///   be of the format `angle => content`.
/// - name (none,string): Element name, used for querying anchors.
/// - ..style (style): Style key-value pairs.
#let angle(
  origin,
  a,
  b,
  inner: true,
  label: none,
  name: none,
  ..style
) = draw.group(name: name, ctx => {
  let style = styles.resolve(ctx.style, merge: style.named(), base: default-style, root: "angle")
  let (ctx, origin) = coordinate.resolve(ctx, origin)
  let (ctx, a, b) = coordinate.resolve(ctx, a, b, update: false)

  assert(origin.at(2) == a.at(2) and a.at(2) == b.at(2),
    message: "Angle z coordinates of all three points must be equal")

  let (s, e, ss) = {
    let s = vector.angle2(origin, a)
    if s < 0deg { s += 360deg }
    let e = vector.angle2(origin, b)
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

  // Radius can be relative to the min-distance between origin-a and origin-b
  if type(style.radius) == ratio {
    style.radius = style.radius * calc.min(vector.dist(origin, a), vector.dist(origin, b)) / 100%
  }
  let (r, _) = util.resolve-radius(style.radius).map(util.resolve-number.with(ctx))

  // Label radius can be relative to radius
  if type(style.label-radius) == ratio {
    style.label-radius = style.label-radius * style.radius / 100%
  }
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

/// Draw a right angle between `a` and `b` through origin `origin`
///
/// #example(```
/// line((0,0), (1,2), name: "a")
/// line((0,0), (2,-1), name: "b")
///
/// // Draw an angle between the two lines
/// cetz.angle.right-angle("a.start", "a.end", "b.end",
///   radius: 1.5)
/// ```)
///
/// *Style Root:* `angle`
///
/// *Style Keys:*
///   #show-parameter-block("radius", ("number"), [
///     The radius of the angles arc. If of type `ratio`, it is relative to the smaller distance of either origin to a or origin to b.], default: .5)
///   #show-parameter-block("label-radius", ("number", "ratio"), [
///     The radius of the angles label origin. If of type `ratio`, it is relative to the distance between `origin` and the angle corner.], default: 50%)
///
/// *Anchors*
/// / `"a"`: Point a
/// / `"b"`: Point b
/// / `"origin"`: Origin
/// / `"corner"`: Angle corner
/// / `"label"`: Label center
///
/// - origin (coordinate): Angle origin
/// - a (coordinate): Coordinate of side `a`, containing an angle between `origin` and `b`.
/// - b (coordinate): Coordinate of side `b`, containing an angle between `origin` and `a`.
/// - label (none,content): Draw a label at the angles "label" anchor.
/// - name (none,string): Element name, used for querying anchors.
/// - ..style (style): Style key-value pairs.
#let right-angle(
  origin,
  a,
  b,
  label: "•",
  name: none,
  ..style
) = draw.group(name: name, ctx => {
  let style = styles.resolve(ctx.style, merge: style.named(), base: default-style, root: "angle")
  let (ctx, origin) = coordinate.resolve(ctx, origin)
  let (ctx, a, b) = coordinate.resolve(ctx, a, b, update: false)
  let vo = origin; let va = a; let vb = b

  // Radius can be relative to the min-distance between origin-a and origin-b
  if type(style.radius) == ratio {
    style.radius = style.radius * calc.min(vector.dist(vo, va), vector.dist(vo, vb)) / 100%
  }
  let (r, _) = util.resolve-radius(style.radius).map(util.resolve-number.with(ctx))

  let va = vector.add(vo, vector.scale(vector.norm(vector.sub(va, vo)), r))
  let vb = vector.add(vo, vector.scale(vector.norm(vector.sub(vb, vo)), r))
  let angle-b = vector.angle2(vo, vb)
  let vm = vector.add(va, (calc.cos(angle-b) * r, calc.sin(angle-b) * r, 0))

  // Label radius can be relative to the distance between origin and the
  // angle corner
  if type(style.label-radius) == ratio {
    style.label-radius = style.label-radius * vector.dist(vm, vo) / 100%
  }
  let (ra, _) = util.resolve-radius(style.label-radius).map(util.resolve-number.with(ctx))

  if style.fill != none {
    draw.line(vo, va, vm, vb, close: true, stroke: none, fill: style.fill)
  }
  draw.line(va, vm, vb, ..style, fill: none)

  let label-pt = vector.scale(vector.norm(vector.sub(vm, vo)), ra)
  if label != none {
    draw.content(label-pt, label)
  }

  draw.anchor("a", a)
  draw.anchor("b", b)
  draw.anchor("origin", origin)
  draw.anchor("corner", vm)
  draw.anchor("label", label-pt)
})
