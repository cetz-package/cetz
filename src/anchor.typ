#import "@preview/oxifmt:0.2.0": strfmt

#import "util.typ"
#import "intersection.typ"
#import "drawable.typ"
#import "path-util.typ"
#import "matrix.typ"
#import "vector.typ"

// #let calculate(func, anchor-names, anchor, transform: none, name: none, default: none) = {
//   if anchor == () {
//     return anchor-names
//   }
//   if anchor == "default" {
//     anchor = default
//   }
//   assert(
//     anchor in anchor-names,
//     message: strfmt("Anchor '{}' not in anchors {}", anchor, repr(anchor-names)) + if name != none { strfmt(" for element '{}'", name) }
//   )

//   let out = func(anchor)
//   return if transform != none {
//     util.apply-transform(
//       transform,
//       out
//     )
//   } else {
//     out
//   }
// }

#let setup(callback, anchor-names, default: none, transform: none, name: none, offset-anchor: none) = {
  if default != none and transform != none and offset-anchor != none {
    assert(
      offset-anchor in anchor-names,
      message: strfmt("Anchor '{}' not in anchors {} for element '{}'", offset-anchor, repr(anchor-names), name)
    )
    transform = matrix.mul-mat(
      transform,
      matrix.transform-translate(
        ..vector.sub(callback(default), callback(offset-anchor))
      )
    )
  }

  let calculate-anchor(anchor) = {
    if anchor == () {
      return anchor-names
    }
    if anchor == "default" {
      assert.ne(default, none, message: strfmt("Element '{}' does not have a default anchor!", name))
      anchor = default
    }
    assert(
      anchor in anchor-names,
      message: strfmt("Anchor '{}' not in anchors {} for element '{}'", anchor, repr(anchor-names), name)
      // message: strfmt("Anchor '{}' not in anchors {}", anchor, repr(anchor-names)) + if name != none { strfmt(" for element '{}'", name) }
    )

    let out = callback(anchor)
    return if transform != none {
      util.apply-transform(
        transform,
        out
      )
    } else {
      out
    }
  }
  return (transform, calculate-anchor)
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