#import "drawable.typ"
#import "path-util.typ"

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
    let miter-limit = 1 / calc.sin(angle / 2)
    if miter-limit <= style.stroke.miter-limit {
      return miter-limit * (style.stroke.thickness / 2)
    }
  }

  // style.stroke.join must be "bevel"
  return calc.sin(angle/2) * (style.stroke.thickness / 2)
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
      path-util.line-segment(((0, -style.width/2), (0, +style.width/2))),
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
)

// Mark mnemonics
#let mnemonics = (
  ">": ("triangle", false),
  "<": ("triangle", true),
  "|": ("bar",      false),
  "o": ("circle",   false),
)

// Get a mark shape + rever tuple for a mark name
#let get-mark(ctx, symbol) = {
  // TODO: Support user supplied marks by looking them up in the ctx style

  let reverse = false
  if not symbol in marks {
    (symbol, reverse) = mnemonics.at(symbol)
  }
  return (marks.at(symbol), reverse)
}
