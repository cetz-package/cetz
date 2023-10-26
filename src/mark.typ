#import "drawable.typ"
#import "vector.typ"
#import "path-util.typ"

// Calculate the offset of a mark symbol.
// For triangular marks, this is the half
// of the miter length or halt of the stroke
// thickness, depending on the joint style.
#let calc-symbol-offset(ctx, symbol, style) = {
  if not symbol in ("<", ">") { return }
  let sign = if symbol == "<" { 1 } else { -1 }

  let stroke = line(stroke: style.stroke).stroke
  let (width, limit, join) = (
    stroke.thickness, stroke.miter-limit, stroke.join)
  // Fallback to Typst's defaults
  if width == auto { width = 1pt }
  if limit == auto { limit = 4 }
  if join  == auto { join = "miter" }

  if type(width) == length { width /= ctx.length }

  if join == "miter" {
    let angle = calc.abs(style.angle)
    let miter = if angle == 180deg {
      width / 2
    } else if angle == 0deg or angle == 360deg {
      0
    } else {
      (1 / calc.sin(angle / 2) * width / 2)
    }
  }

  if calc.abs(2 * miter / width) <= limit {
    return miter * sign
  } else {
    // If the miter limit kicks in, use bevel calculation
    join = "bevel"
  }
  if join == "bevel" {
    return calc.sin(style.angle / 2) * width / 2 * sign
  } else {
    return width / 2 * sign
  }

  return 0
}
