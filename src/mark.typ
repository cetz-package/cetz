#let typst-length = length

#import "drawable.typ"
#import "vector.typ"
#import "path-util.typ"

// Calculate offset for a triangular mark (triangle, harpoon, ..)
#let _triangular-mark-offset(ctx, width, length, style) = {
  let revert = symbol == "<"
  let sign = if revert { 1 } else { -1 }

  let stroke = line(stroke: style.stroke).stroke
  let (width, limit, join) = (
    stroke.thickness, stroke.miter-limit, stroke.join)

  // Fallback to Typst's defaults
  if width == auto { width = 1pt }
  if limit == auto { limit = 4 }
  if join  == auto { join = "miter" }

  if type(width) == typst-length { width /= ctx.length }

  if style.length == 0 { return 0 }
  let angle = calc.atan(style.width / (2 * style.length)) * 2
  if join == "miter" {
    let angle = calc.abs(angle)
    let miter = if angle == 180deg {
      width / 2
    } else if angle == 0deg or angle == 360deg {
      0
    } else {
      (1 / calc.sin(angle / 2) * width / 2)
    }

    if calc.abs(2 * miter / width) <= limit {
      return miter * sign
    } else {
      // If the miter limit kicks in, use bevel calculation
      join = "bevel"
    }
  }

  if join == "bevel" {
    return calc.sin(angle / 2) * width / 2 * sign
  } else {
    return width / 2 * sign
  }

  return 0
}

// Calculate the offset of a mark symbol.
// For triangular marks, this is the half
// of the miter length or halt of the stroke
// thickness, depending on the joint style.
#let calc-mark-offset(ctx, symbol, style) = {
  if symbol in ("<", ">", "left-harpoon", "right-harpoon") {
    return _triangular-mark-offset(ctx, style.width, style.length, style)
  } else if symbol == "<>" {
    return _triangular-mark-offset(ctx, style.width, style.length / 2, style)
  }

  return 0
}
