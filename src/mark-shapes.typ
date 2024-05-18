#import "drawable.typ"
#import "path-util.typ"
#import "vector.typ"

// Calculate triangular tip offset, depending on the strokes
// join type.
//
// The angle is calculated for an isosceles triangle of base style.widh
// and height style.length
#let calculate-tip-offset(style) = {
  if style.stroke.join == "round" {
    return style.stroke.thickness / 2
  }

  if style.length == 0 {
    return 0
  }

  let angle = calc.atan(style.width / (2 * style.length) / if style.harpoon { 2 } else { 1 } ) * 2
  // If the miter length divided by the stroke width exceeds
  // the stroke miter limit then the miter join is converted to a bevel.
  // See: https://svgwg.org/svg2-draft/painting.html#LineJoin
  if style.stroke.join == "miter" {
    let angle = calc.abs(angle)
    if angle > 0deg {
      let miter-limit = 1 / calc.sin(angle / 2)
      if miter-limit <= style.stroke.miter-limit {
        return miter-limit * (style.stroke.thickness / 2)
      }
    }
  }

  // style.stroke.join must be "bevel"
  return calc.sin(angle/2) * (style.stroke.thickness / 2)
}

#let _star-shape(n, style, angle-offset: 0deg) = {
  let radius(angle) = {
    vector.dist((0,0), (calc.cos(angle) * style.length, calc.sin(angle) * style.width)) / 2
  }
  range(0, n)
    .map(i => i * 360deg / n + angle-offset)
    .filter(a => not style.harpoon or (a >= 0deg and a <= 180deg))
    .map(a => {
      let d = vector.scale(vector.rotate-z((1, 0, 0), a), radius(a))

      drawable.path(path-util.line-segment(((0,0,0), vector.add((0,0,0), d))),
        stroke: style.stroke, close: false)
  })
}

// Dictionary of built-in mark styles
//
// (style) => (drawables:, tip-offset:, distance:)
#let marks = (
  triangle: (style) => (
    drawables: drawable.path(
      path-util.line-segment(
        (
          (0, 0),
          (style.length, style.width/2),
          if style.harpoon { (style.length, 0) } else { (style.length, -style.width/2) }
        )
      ),
      close: true,
      fill: style.fill,
      stroke: style.stroke
    ),
    tip-offset: calculate-tip-offset(style),
    distance: style.length
  ),
  stealth: (style) => (
    drawables: drawable.path(
      path-util.line-segment(
        (
          (0, 0),
          (style.length, style.width/2),
          (style.length - style.inset, 0),
          if not style.harpoon {
            (style.length, -style.width/2)
          }
        ).filter(c => c != none)
      ),
      stroke: style.stroke,
      close: true,
      fill: style.fill
    ),
    distance: style.length - style.inset,
    tip-offset: calculate-tip-offset(style)
  ),
  bar: (style) => (
    drawables: drawable.path(
      path-util.line-segment(
        if style.harpoon {
          ((0, 0), (0, +style.width/2))
        } else {
          ((0, -style.width/2), (0, +style.width/2))
        }),
      stroke: style.stroke,
      fill: none,
      close: false,
    ),
    distance: 0,
    tip-offset: style.stroke.thickness / 2,
  ),
  ellipse: (style) => (
    drawables: drawable.ellipse(
      style.length / 2, 0, 0, style.length / 2, style.width / 2,
      stroke: style.stroke,
      fill: style.fill),
    distance: style.length,
    tip-offset: style.stroke.thickness / 2,
  ),
  circle: (style) => {
    let radius = calc.min(style.length, style.width) / 2
    (
      drawables: drawable.ellipse(
        radius, 0, 0, radius, radius,
        stroke: style.stroke,
        fill: style.fill),
      distance: radius * 2,
      tip-offset: style.stroke.thickness / 2,
    )
  },
  bracket: (style) => (
    drawables: drawable.path(
      path-util.line-segment(
        if style.harpoon {
          ((style.length - style.inset, style.width/2),
           (0, style.width/2),
           (0, 0))
        } else {
          ((style.length - style.inset, -style.width/2),
           (0, -style.width/2),
           (0, +style.width/2),
           (style.length - style.inset, +style.width/2))
        }),
      stroke: style.stroke,
      fill: none,
      close: false,
    ),
    distance: style.length,
    inset: style.length + style.stroke.thickness / 2,
    tip-offset: style.stroke.thickness / 2,
  ),
  diamond: (style) => (
    drawables: drawable.path(
      path-util.line-segment(
        if style.harpoon {
          ((0,0), (style.length / 2, style.width / 2), (style.length, 0))
        } else {
          ((0,0), (style.length / 2, style.width / 2), (style.length, 0), (style.length / 2, -style.width / 2))
        }
      ),
      close: true,
      fill: style.fill,
      stroke: style.stroke
    ),
    tip-offset: calculate-tip-offset(style),
    base-offset: calculate-tip-offset(style),
    distance: style.length
  ),
  rect: (style) => {
    let top = if style.harpoon { 0 } else { -style.width / 2 }
    let width = if style.harpoon { style.width / 2 } else { style.width }
    (drawables: drawable.path(
      path-util.line-segment(
        ((0, top), (0, top + width), (style.length, top + width), (style.length, top))
      ),
      close: true,
      fill: style.fill,
      stroke: style.stroke
    ),
    tip-offset: style.stroke.thickness / 2,
    base-offset: style.stroke.thickness / 2,
    distance: style.length
  )},
  hook: (style) => {
    let rx = calc.min(style.length, style.width / 2) / 2
    let length = calc.max(style.length - style.inset, rx)
    let lower = (
      path-util.line-segment(((length, style.width / 2), (rx, style.width / 2))),
      path-util.cubic-segment(
        (rx, style.width / 2),
        (rx, 0),
        (-rx, style.width / 2),
        (-rx, 0)),
      path-util.line-segment(((rx, 0), (style.length, 0))))
    let upper = (
      path-util.line-segment(((style.length, 0), (rx, 0))),
      path-util.cubic-segment(
        (rx, 0),
        (rx, -style.width / 2),
        (-rx, 0),
        (-rx, -style.width / 2)),
      path-util.line-segment(((rx, -style.width / 2), (length, -style.width / 2))))

    (drawables: drawable.path(
      lower + (if not style.harpoon {
        upper
      } else { () }),
      close: false,
      fill: none,
      stroke: style.stroke
    ),
    tip-offset: calculate-tip-offset(style),
    distance: style.length
  )},
  straight: (style) => (
    drawables: drawable.path(
      path-util.line-segment(
        if style.harpoon {
          ((style.length, style.width/2),
           (0, 0),)
        } else {
          ((style.length, +style.width/2),
           (0, 0),
           (style.length, -style.width/2),)
        }),
      close: false,
      fill: none,
      stroke: style.stroke
    ),
    tip-offset: calculate-tip-offset(style),
    distance: style.length,
    inset: style.length
  ),
  barbed: (style) => {
    // Force join to "round" as other joins look bad
    style.stroke.join = "round"
    let ctrl-a = (style.length, 0)
    let ctrl-b = (0, 0)
    (drawables: drawable.path(
      (path-util.cubic-segment(
         (style.length, style.width / 2), (0,0),
         ctrl-a, ctrl-b),)
      + if not style.harpoon {
        (path-util.cubic-segment(
          (0,0), (style.length, -style.width / 2),
          ctrl-b, ctrl-a),)
      } else { () },
      close: false,
      fill: none,
      stroke: style.stroke),
    tip-offset: calculate-tip-offset(style),
    distance: style.length,
    inset: style.length
  )},
  plus: (style) => (
    drawables: _star-shape(4, style),
    tip-offset: style.length / 2,
    distance: style.length / 2,
  ),
  x: (style) => (
    drawables: _star-shape(4, style, angle-offset: 45deg),
    tip-offset: style.length / 2,
    distance: style.length / 2,
    inset: style.length / 2
  ),
  star: (style) => (
    drawables: _star-shape(5, style),
    tip-offset: style.length / 2,
    distance: style.length / 2,
  )
)
#let names = marks.keys()

// Mark mnemonics
#let mnemonics = (
  ">":  ("triangle", false),
  "<":  ("triangle", true),
  "<>": ("diamond",  false),
  "[]": ("rect",     false),
  "]":  ("bracket",  false),
  "[":  ("bracket",  true),
  "|":  ("bar",      false),
  "o":  ("circle",   false),
  "+":  ("plus",     false),
  "x":  ("x",        false),
  "*":  ("star",     false),
)

// Get a mark shape + reverse tuple for a mark name
#let get-mark(ctx, symbol) = {
  // TODO: Support user supplied marks by looking them up in the ctx style

  let reverse = false
  if not symbol in marks {
    (symbol, reverse) = mnemonics.at(symbol)
  }
  return (marks.at(symbol), reverse)
}
