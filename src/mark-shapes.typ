#import "drawable.typ"
#import "path-util.typ"
#import "vector.typ"

// Calculate triangular tip offset, depending on the strokes
// join type.
//
// The angle is calculated for an isosceles triangle of base style.widh
// and height style.length
#let _calculate-tip-offset(style) = {
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

#let create-tip-and-base-anchor(style, tip, base, center: none, respect-stroke-thickness: false) = {
  if base == auto or base == tip {
    base = vector.add(tip, (1e-6, 0, 0))
  }
  let dir = vector.norm(vector.sub(tip, base))

  let thickness = if respect-stroke-thickness {
    let dist = vector.dist(tip, base)

    calc.min(style.stroke.thickness, dist / 2) / 2
  } else {
    0
  }

  import "/src/draw.typ": anchor
  anchor("tip", vector.add(tip, vector.scale(dir, thickness)))
  anchor("base", vector.sub(base, vector.scale(dir, thickness)))
}

#let create-triangle-tip-and-base-anchor(style, tip, base, center: none) = {
  if base == auto or base == tip {
    base = vector.add(tip, (1e-6, 0, 0))
  }
  let dir = vector.norm(vector.sub(tip, base))
  let dist = vector.dist(tip, base)
  let thickness = calc.min(style.stroke.at("thickness", default: 0), dist) / 2

  import "/src/draw.typ": anchor
  if style.reverse {
    // Since tip and base are now "swapped", we add the stroke thickness to the triangle
    // base. To get smooth looking connections between the triangle tip and a connecting line,
    // we do not add the tip-offset.
    anchor("tip", tip)
    anchor("base", vector.sub(base, vector.scale(dir, thickness)))
  } else {
    anchor("tip", vector.add(tip, vector.scale(dir, _calculate-tip-offset(style))))
    anchor("base", base)
  }
}

#let create-diamond-tip-and-base-anchor(style, tip, base, center: none, ratio: 50%) = {
  if base == tip { base = vector.add(tip, (1e-8, 0, 0)) }
  let dir = vector.norm(vector.sub(tip, base))

  import "/src/draw.typ": anchor

  let tip-style = style
  tip-style.length = style.length * (ratio / 100%)
  if style.reverse {
    anchor("tip", tip)
  } else {
    anchor("tip", vector.add(tip, vector.scale(dir, _calculate-tip-offset(tip-style))))
  }
  if style.reverse {
    anchor("base", vector.sub(base, vector.scale(dir, _calculate-tip-offset(tip-style))))
  } else {
    anchor("base", base)
  }
}

// Dictionary of built-in mark styles
//
// (style) => (<elements..>)
#let marks = (
  triangle: (style) => {
    import "/src/draw.typ": *

    if style.harpoon {
      line((0,0), (style.length, 0), (style.length, style.width / 2), close: true)
    } else {
      line((0,0), (style.length, -style.width / 2), (style.length, style.width / 2), close: true)
    }

    create-triangle-tip-and-base-anchor(style, (0, 0), (style.length, 0))
  },
  // A mark in the shape of an arrow tip.
  stealth: (style) => {
    import "/src/draw.typ": *

    let (l, w, i) = (style.length, style.width, style.inset)

    if style.harpoon {
      line((0,0), (l, w / 2), (l - i, 0), close: true)
    } else {
      line((0,0), (l, w / 2), (l - i, 0), (l, -w / 2), close: true)
    }

    create-triangle-tip-and-base-anchor(style, (0, 0), (l - i, 0))
  },
  bstealth: (style) => {
    import "/src/draw.typ": *
    let (l, w, i) = (style.length, style.width, style.inset)
    merge-path(
      fill: style.stroke.paint,
      stroke: (thickness: 1pt, join: "round"),
      close: true,
      {
        bezier(
          (0, 0),
          (l, w / 2),
          (l / 3, w / 8),
          stroke: none,
        )
        bezier(
          (l, w / 2),
          (l, -w / 2),
          (l - i, 0),
          stroke: none,
        )
        bezier(
          (l, -1 / 2),
          (0, 0),
          (l / 3, -w / 8),
          stroke: none,
        )
      },
    )
    create-triangle-tip-and-base-anchor(style, (0, 0), (l - i, 0))
  },
  bar: (style) => {
    import "/src/draw.typ": line, anchor

    let w = style.width

    if style.harpoon {
      line((0, w / 2), (0, 0))
    } else {
      line((0, w / 2), (0, -w / 2))
    }

    let offset = style.stroke.thickness / 2
    create-tip-and-base-anchor(style, (-offset, 0), (offset, 0))
    anchor("center", (0, 0))
  },
  ellipse: (style) => {
    import "/src/draw.typ": *

    let r = (style.length / 2, style.width / 2)

    if style.harpoon {
      arc((0, 0), delta: -180deg, start: 0deg, radius: r, anchor: "origin", mode: "PIE")
    } else {
      circle((0, 0), radius: r)
    }

    create-tip-and-base-anchor(style, (r.at(0), 0), (-r.at(0), 0), respect-stroke-thickness: true)
  },
  circle: (style) => {
    import "/src/draw.typ": arc, circle

    let r = calc.min(style.length, style.width) / 2

    if style.harpoon {
      arc((0, 0), delta: -180deg, start: 0deg, radius: r, anchor: "origin", mode: "PIE")
    } else {
      circle((0, 0), radius: r)
    }

    create-tip-and-base-anchor(style, (r, 0), (-r, 0), respect-stroke-thickness: true)
  },
  bracket: (style) => {
    import "/src/draw.typ": *

    let (l, w, i) = (style.length, style.width, style.inset)

    if style.harpoon {
      line((l + i, w / 2), (0, w / 2), (0, 0), fill: none)
    } else {
      line((l + i, w / 2), (0, w / 2), (0, -w / 2), (l + i, -w / 2), fill: none)
    }

    create-tip-and-base-anchor(style, (0, 0), (0, 0), respect-stroke-thickness: true)
  },
  diamond: (style) => {
    import "/src/draw.typ": *

    let (l, w) = (style.length, style.width)

    if style.harpoon {
      line((0,0), (l / 2, w / 2), (l, 0), close: true)
    } else {
      line((0,0), (l / 2, w / 2), (l, 0), (l / 2, -w / 2), close: true)
    }

    create-diamond-tip-and-base-anchor(style, (0, 0), (l, 0))
  },
  rect: (style) => {
    import "/src/draw.typ": *

    let (l, w) = (style.length, style.width)

    if style.harpoon {
      rect((0, -w / 2), (-l, +w / 2))
    } else {
      rect((0, -w / 2), (-l, +w / 2))
    }

    create-tip-and-base-anchor(style, (0, 0), (-l, 0), respect-stroke-thickness: true)
  },
  hook: (style) => {
    import "/src/draw.typ": *

    let r = calc.min(style.length, style.width / 2) / 2
    let (l, i) = (style.length, style.inset)

    merge-path({
      line((i, -2 * r), (0, -2 * r))
      arc((0, 0), delta: -180deg, start: -90deg, radius: r, anchor: "end")
      if not style.harpoon {
        arc((0, 0), delta: -180deg, start: -90deg, radius: r, anchor: "start")
        line((i, +2 * r), (0, +2 * r))
      }
    }, fill: none)

    create-tip-and-base-anchor(style, (-r, 0), (0, 0), center: ((-r + i) / 2, 0))
  },
  // An unfilled mark in the shape of an angle bracket (>).
  straight: (style) => {
    import "/src/draw.typ": *

    let (l, w) = (style.length, style.width)

    if style.harpoon {
      line((l, w / 2), (0, 0), fill: none)
    } else {
      line((l, w / 2), (0, 0), (l, -w / 2), fill: none)
    }

    if style.harpoon {
      create-tip-and-base-anchor(style, (0, 0), (0, 0))
    } else {
      create-triangle-tip-and-base-anchor(style, (0, 0), (0, 0))
    }
  },
  barbed: (style) => {
    import "/src/draw.typ": *

    let style = style
    style.stroke.join = "round"

    let (l, w) = (style.length, style.width)

    let ctrl-a = (l, 0)
    let ctrl-b = (0, 0)

    merge-path({
      bezier((l, w / 2), (0, 0), ctrl-a, ctrl-b)
      if not style.harpoon {
        bezier((0, 0), (l, -w / 2), ctrl-b, ctrl-a)
      }
    }, ..style)

    let offset = style.stroke.thickness / 2
    create-tip-and-base-anchor(style, (-offset, 0), (2 * offset, 0))
  },
  plus: (style) => {
    import "/src/draw.typ": *

    let (l, w) = (style.length, style.width)

    line((-l / 2, 0), (+l / 2, 0))
    line((0, -w / 2), (0, +w / 2))

    create-tip-and-base-anchor(style, (0, 0), (0, 0))
  },
  x: (style) => {
    import "/src/draw.typ": *

    let (l, w) = (style.length, style.width)

    line((-l / 2, w / 2), (+l / 2, -w / 2))
    line((-l / 2, -w / 2), (+l / 2, +w / 2))

    create-tip-and-base-anchor(style, (0, 0), (0, 0))
  },
  star: (style) => {
    import "/src/draw.typ": *

    let (l, w) = (style.length, style.width)

    let n = 5
    for i in range(0, n) {
      let a = 360deg / n * i
      line((0, 0), (calc.cos(a) * l / 2, calc.sin(a) * w / 2))
    }

    create-tip-and-base-anchor(style, (0, 0), (0, 0))
  },
)
#let names = marks.keys()

// Mark mnemonics
// Each mnemonic maps to a dictionary of:
//   - reverse (bool)
//   - flip (bool)
//   - harpoon (bool)
// TODO: Resolve mark styles at a later point, to support all style keys here
#let mnemonics = (
  ">":  ("triangle", (:)),
  "<":  ("triangle", (reverse: true)),
  "<>": ("diamond",  (:)),
  "[]": ("rect",     (:)),
  "]":  ("bracket",  (:)),
  "[":  ("bracket",  (reverse: true)),
  "|":  ("bar",      (:)),
  "o":  ("circle",   (:)),
  "+":  ("plus",     (:)),
  "x":  ("x",        (:)),
  "*":  ("star",     (:)),
)

// Get a mark shape + reverse tuple for a mark name
#let get-mark(ctx, symbol) = {
  symbol = ctx.marks.mnemonics.at(symbol, default: symbol)
  if symbol in ctx.marks.marks {
    return (ctx.marks.marks.at(symbol), (:))
  }

  let (symbol, defaults) = mnemonics.at(symbol, default: (symbol, (:)))
  assert(symbol in marks, message: "Unknown mark '" + symbol + "'")
  return (marks.at(symbol), defaults)
}
