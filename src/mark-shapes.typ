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

#let tip-base(style, tip, base, center: none) = {
  if base == tip { base = vector.add(tip, (1e-8, 0, 0)) }
  let dir = vector.norm(vector.sub(tip, base))

  import "/src/draw.typ": *
  anchor("tip", vector.add(tip, vector.scale(dir, style.stroke.thickness / 2)))
  anchor("base", vector.sub(base, vector.scale(dir, style.stroke.thickness / 2)))
}

#let triangle-tip-base(style, tip, base, center: none) = {
  if base == tip { base = vector.add(tip, (1e-8, 0, 0)) }
  let dir = vector.norm(vector.sub(tip, base))

  import "/src/draw.typ": *
  anchor("tip", vector.add(tip, vector.scale(dir, _calculate-tip-offset(style))))
  anchor("base", vector.sub(base, vector.scale(dir, style.stroke.thickness / 2)))
}

#let diamond-tip-base(style, tip, base, center: none, ratio: 50%) = {
  if base == tip { base = vector.add(tip, (1e-8, 0, 0)) }
  let dir = vector.norm(vector.sub(tip, base))

  import "/src/draw.typ": *

  let tip-style = style
  tip-style.length = style.length * (ratio / 100%)
  anchor("tip", vector.add(tip, vector.scale(dir, _calculate-tip-offset(tip-style))))
  let base-style = style
  base-style.length = style.length * ((100% - ratio) / 100%)
  anchor("base", vector.sub(base, vector.scale(dir, _calculate-tip-offset(base-style))))
}

// Dictionary of built-in mark styles
//
// (style) => (<elements..>)
#let marks = (
  triangle: (style) => {
    import "/src/draw.typ": *

    if style.harpoon {
      line((0,0), (style.length, 0), (style.length, +style.width / 2), close: true)
    } else {
      line((0,0), (style.length, -style.width / 2), (style.length, +style.width / 2), close: true)
    }

    triangle-tip-base(style, (0, 0), (style.length, 0))
  },
  stealth: (style) => {
    import "/src/draw.typ": *

    let (l, w, i) = (style.length, style.width, style.inset)

    if style.harpoon {
      line((0,0), (l, w / 2), (l - i, 0), close: true)
    } else {
      line((0,0), (l, w / 2), (l - i, 0), (l, -w / 2), close: true)
    }

    triangle-tip-base(style, (0, 0), (l - i, 0))
  },
  bar: (style) => {
    import "/src/draw.typ": *

    let w = style.width

    if style.harpoon {
      line((0, w / 2), (0, 0))
    } else {
      line((0, w / 2), (0, -w / 2))
    }

    tip-base(style, (0, 0), (0, 0))
  },
  ellipse: (style) => {
    import "/src/draw.typ": *

    let r = (style.length / 2, style.width / 2)

    if style.harpoon {
      arc((0, 0), delta: -180deg, start: 0deg, radius: r, anchor: "origin", mode: "PIE")
    } else {
      circle((0, 0), radius: r)
    }

    tip-base(style, (r.at(0), 0), (-r.at(0), 0))
  },
  circle: (style) => {
    import "/src/draw.typ": *

    let r = calc.min(style.length, style.width) / 2

    if style.harpoon {
      arc((0, 0), delta: -180deg, start: 0deg, radius: r, anchor: "origin", mode: "PIE")
    } else {
      circle((0, 0), radius: r)
    }

    tip-base(style, (r, 0), (-r, 0))
  },
  bracket: (style) => {
    import "/src/draw.typ": *

    let (l, w, i) = (style.length, style.width, style.inset)

    if style.harpoon {
      line((-l - i, w / 2), (0, w / 2), (0, 0))
    } else {
      line((-l - i, w / 2), (0, w / 2), (0, -w / 2), (-l - i, -w / 2))
    }

    tip-base(style, (0, 0), (-1e-8, 0), center: ((-l - i) / 2, 0))
  },
  diamond: (style) => {
    import "/src/draw.typ": *

    let (l, w) = (style.length, style.width)

    if style.harpoon {
      line((0,0), (l / 2, w / 2), (l, 0), close: true)
    } else {
      line((0,0), (l / 2, w / 2), (l, 0), (l / 2, -w / 2), close: true)
    }

    diamond-tip-base(style, (0, 0), (l, 0))
  },
  rect: (style) => {
    import "/src/draw.typ": *

    let (l, w) = (style.length, style.width)

    if style.harpoon {
      rect((0, -w / 2), (-l, +w / 2))
    } else {
      rect((0, -w / 2), (-l, +w / 2))
    }

    tip-base(style, (0, 0), (-l, 0))
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
    })

    line((0, 0), (l - r, 0))

    tip-base(style, (-r, 0), (l - r, 0), center: ((-r + i) / 2, 0))
  },
  straight: (style) => {
    import "/src/draw.typ": *

    let (l, w) = (style.length, style.width)

    if style.harpoon {
      line((l, w / 2), (0, 0))
    } else {
      line((l, w / 2), (0, 0), (l, -w / 2))
    }

    triangle-tip-base(style, (0, 0), (0, 0))
  },
  barbed: (style) => {
    import "/src/draw.typ": *

    let style = style
    style.stroke.join = "round"

    let (l, w) = (style.length, style.width)

    // Force join to "round" as other joins look bad
    let ctrl-a = (l, 0)
    let ctrl-b = (0, 0)

    merge-path({
      bezier((l, w / 2), (0, 0), ctrl-a, ctrl-b)
      if not style.harpoon {
        bezier((0, 0), (l, -w / 2), ctrl-b, ctrl-a)
      }
    }, ..style)

    tip-base(style, (0, 0), (1e-6, 0))
  },
  plus: (style) => {
    import "/src/draw.typ": *

    let style = style
    style.stroke.join = "round"

    let (l, w) = (style.length, style.width)

    line((-l / 2, 0), (+l / 2, 0))
    line((0, -w / 2), (0, +w / 2))

    tip-base(style, (0, 0), (l / 2, 0))
  },
  x: (style) => {
    import "/src/draw.typ": *

    let style = style
    style.stroke.join = "round"

    let (l, w) = (style.length, style.width)

    line((-l / 2, w / 2), (+l / 2, -w / 2))
    line((-l / 2, -w / 2), (+l / 2, +w / 2))

    tip-base(style, (0, 0), (0, 0))
  },
  star: (style) => {
    import "/src/draw.typ": *

    let (l, w) = (style.length, style.width)

    let n = 5
    for i in range(0, n) {
      let a = 360deg / n * i
      line((0, 0), (calc.cos(a) * l / 2, calc.sin(a) * w / 2))
    }

    tip-base(style, (0, 0), (l / 2, 0))
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
  // TODO: Support user supplied marks by looking them up in the ctx style

  let defaults = (:)
  if not symbol in marks {
    (symbol, defaults) = mnemonics.at(symbol)
  }
  return (marks.at(symbol), defaults)
}
