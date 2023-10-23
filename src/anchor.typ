#import "@preview/oxifmt:0.2.0": strfmt

#import "util.typ"
#import "intersection.typ"
#import "drawable.typ"
#import "path-util.typ"

#let calculate(func, anchors, transform, anchor, name: none, default: none) = {
  if anchor == () {
    return anchors
  }
  if anchor == "deufault" {
    anchor = default
  }
  assert(
    anchor in anchors,
    message: strfmt("Anchor '{}' not in anchors {}", anchor, repr(anchors)) + if name != none { strfmt(" for element '{}'", name) }
  )

  return util.apply-transform(
    transform,
    func(anchor)
  )
}

#let border(center, x-dist, y-dist, drawables, angle) = {
  if type(drawables) == dictionary {
    drawables = (drawables,)
  }

  let test-path = drawable.path(
    path-util.line-segment(
      (
        center,
        (
          center.at(0) + x-dist * calc.cos(angle),
          center.at(1) + y-dist * calc.sin(angle),
          center.at(2),
        )
      )
    )
  )

  let pts = ()
  for drawable in drawables {
    if drawable.type != "path" {
      continue
    }
    pts += intersection.path-path(test-path, drawable)
  }
  assert(pts.len() > 0, message: strfmt("{} {} {}", test-path, drawables, angle))
  return pts.first()
}