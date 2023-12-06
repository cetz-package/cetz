#let typst-length = length
#import "bezier.typ"
#import "drawable.typ"
#import "vector.typ"
#import "matrix.typ"
#import "util.typ"
#import "path-util.typ"

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
    distance: style.length
  )
)

#let place-marks-along-path(ctx, style, segments) = {
  let thickness = util.get-stroke(style.stroke).thickness

  for (k, v) in style {
    if k in ("length", "width", "inset", "sep") {
      style.insert(k, if type(v) == ratio {
        thickness * v
      } else {
        util.resolve-number(ctx, v)
      } * style.scale)
    }
  }

  let (drawables, distance) = (marks.triangle)(style)

  let (pos, dir) = path-util.direction(segments, 0)
  dir = vector.angle2(pos, dir) + 0deg
  let transform = matrix.mul-mat(
    matrix.transform-translate(..pos),
    matrix.transform-rotate-z(dir),
  )
  drawables = drawable.apply-transform(transform, drawables)

  segments = path-util.shorten-path(segments, distance, 0)

  return (drawables, segments)

}