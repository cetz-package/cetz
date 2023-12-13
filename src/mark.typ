#let typst-length = length
#import "bezier.typ"
#import "drawable.typ"
#import "vector.typ"
#import "matrix.typ"
#import "util.typ"
#import "path-util.typ"

#let calculate-tip-offset(style) = {
  if style.length == 0 {
    return 0
  }
  if style.stroke.join == "round" {
    return style.stroke.thickness / 2
  }
  let angle = calc.atan(style.width / (2 * style.length)) * 2
  // https://svgwg.org/svg2-draft/painting.html#LineJoin If the miter length divided by the stroke width exceeds the stroke miter limit then the miter join is converted to a bevel.
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

// <-
// (style) => drawables
#let marks = (
  triangle: (style) => (
    drawables: drawable.path(
      path-util.line-segment(
        (
          (0, 0),
          (style.length, style.width/2),
          (style.length, -style.width/2)
        )
      ),
      close: true,
      fill: style.fill,
      stroke: style.stroke
    ),
    tip-offset: calculate-tip-offset(style),
    distance: style.length
  )
)

#let process-style(ctx, style) = {
  assert(style.stroke != none)
  style.stroke = util.resolve-stroke(style.stroke)
  style.stroke.thickness = util.resolve-number(ctx, style.stroke.thickness)

  for (k, v) in style {
    if k in ("length", "width", "inset", "sep") {
      style.insert(k, if type(v) == ratio {
        style.stroke.thickness * v
      } else {
        util.resolve-number(ctx, v)
      } * style.scale)
    }
  }

  return style
}

#let transform-mark(mark, pos, angle, flip: false, reverse: false, slant: none) = {
  mark.drawables = drawable.apply-transform(
    matrix.mul-mat(
      ..(
          // matrix.transform-scale(-1),
        matrix.transform-translate(..pos),
        matrix.transform-rotate-z(angle + if reverse { 180deg }),
        matrix.transform-translate(if reverse { -mark.length }  else { mark.tip-offset }, 0, 0),
        if slant not in (none, 0deg) {
          matrix.transform-shear-x(slant)
        },
      ).filter(e => e != none)
    ),
    mark.drawables
  )
  return mark
}

/// Places a mark with the given style at a position pointing towards in the direction of the given angle.
/// - style (dictionary): A dictionary of keys in order to style the mark. The following are the required keys.
///   - stroke
///   - fill
///   - width
///   - length
///   - symbol
///   - inset
/// - pos (vector): The position to place the mark at.
/// - angle (angle): The direction to point the mark towards.
/// -> A dictionary with the keys:
///   - drawables (drawables): The transformed drawables of the mark.
///   - distance: The distance between the tip of the mark and the end.
#let place-mark(style, pos, angle) = {
  let (drawables, distance, tip-offset) = (marks.at(style.symbol))(style)

  return (
    drawables: drawable.apply-transform(
      matrix.mul-mat(
        matrix.transform-translate(..pos),
        matrix.transform-rotate-z(angle),
        matrix.transform-translate(tip-offset, 0, 0)
      ),
      drawables
    ),
    distance: distance + tip-offset
  )
}

#let place-marks-along-path(ctx, style, segments) = {
  // panic(segments)
  style = process-style(ctx, style)
  
  let distance = (0, 0)
  let drawables = ()
  if style.start != none {
    let mark = (marks.at(style.start))(style)
    mark.length = mark.distance + mark.tip-offset

    let pos = path-util.point-on-path(segments, 0%)

    let angle = if style.flex { 
      vector.angle2(pos, path-util.point-on-path(segments, mark.length, samples: style.position-samples))
    } else {
      let (_, dir) = path-util.direction(segments, 0%)
      calc.atan2(dir.at(0), dir.at(1))
    }

    mark = transform-mark(mark, pos, angle, reverse: style.reverse, slant: style.slant)
    drawables += mark.drawables
    distance.first() = mark.length
  }
  if style.end != none {
    let mark = (marks.at(style.end))(style)
    mark.length = mark.distance + mark.tip-offset

    let pos = path-util.point-on-path(segments, 100%)
    let angle = if style.flex { 
      vector.angle2(pos, path-util.point-on-path(segments, -mark.length, samples: style.position-samples))
    } else {
      let (_, dir) = path-util.direction(segments, 100%)
      calc.atan2(dir.at(0), dir.at(1)) + 180deg
    }

    mark = transform-mark(mark, pos, angle, reverse: style.reverse, slant: style.slant)
    drawables += mark.drawables
    distance.last() = mark.length
  }

  segments = path-util.shorten-path(segments, ..distance, mode: if style.flex { "CURVED" } else { "LINEAR" }, samples: style.position-samples)
  // panic(segments)

  return (drawables, segments)

}