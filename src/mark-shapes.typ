#import "drawable.typ"
#import "path-util.typ"
#import "vector.typ"

// Custom line function without all the special logic
// we do not need.
#let fast-line(..pts, stroke: none, fill: none, fill-rule: "non-zero", close: false) = {
  let pts = pts.pos()
  (ctx => {
    let transform = ctx.transform
    let drawables = drawable.line-strip(pts,
      stroke: stroke, fill: fill, close: close,
      fill-rule: fill-rule)

    return (
      ctx: ctx,
      drawables: drawable.apply-transform(transform, drawables),
    )
  },)
}

// Tiny bezier element.
#let fast-bezier(..pts, stroke: none, fill: none, fill-rule: "non-zero") = {
  import "bezier.typ" as bezier_

  let pts = pts.pos()
  if pts.len() == 3 {
    pts = bezier_.quadratic-to-cubic(..pts)
  }

  let (p1, p2, p3, p4) = pts
  (ctx => {
    let transform = ctx.transform
    let drawables = drawable.path(((p1, false, (("c", p3, p4, p2),)),),
      stroke: stroke, fill: fill, fill-rule: fill-rule)

    return (
      ctx: ctx,
      drawables: drawable.apply-transform(transform, drawables),
    )
  },)
}

// Calculate triangular tip offset, depending on the strokes
// join type.
//
// The angle is calculated for an isosceles triangle of base style.widh
// and height style.length
#let _calculate-tip-offset(style) = {
  if style.stroke.join == "round" {
    return style.canvas-thickness / 2
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
        return miter-limit * (style.canvas-thickness / 2)
      }
    }
  }

  // style.stroke.join must be "bevel"
  return calc.sin(angle/2) * (style.canvas-thickness / 2)
}

#let create-tip-and-base-anchor(style, tip, base, center: none, respect-stroke-thickness: false) = {
  if base == auto or base == tip {
    base = vector.add(tip, (1e-6, 0, 0))
  }
  let dir = vector.norm(vector.sub(tip, base))

  let thickness = if respect-stroke-thickness {
    let dist = vector.dist(tip, base)

    calc.min(style.canvas-thickness, dist / 2) / 2
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
  let thickness = calc.min(style.at("canvas-thickness", default: 0), dist) / 2

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
    let pts = if style.harpoon {
      ((0,0), (style.length, 0), (style.length, style.width / 2))
    } else {
      ((0,0), (style.length, -style.width / 2), (style.length, style.width / 2))
    }

    fast-line(..pts, stroke: style.stroke, fill: style.fill, close: true)
    create-triangle-tip-and-base-anchor(style, (0, 0), (style.length, 0))
  },
  // A mark in the shape of an arrow tip.
  stealth: (style) => {
    let (l, w, i) = (style.length, style.width, style.inset)

    let pts = if style.harpoon {
      ((0,0), (l, w / 2), (l - i, 0))
    } else {
      ((0,0), (l, w / 2), (l - i, 0), (l, -w / 2))
    }

    fast-line(..pts, stroke: style.stroke, fill: style.fill, close: true)
    create-triangle-tip-and-base-anchor(style, (0, 0), (l - i, 0))
  },
  curved-stealth: (style) => {
    import "/src/draw.typ": merge-path

    let (l, w, i) = (style.length, style.width, style.inset)

    // Force round join
    style.stroke.join = "round"

    merge-path(
      stroke: style.stroke,
      fill: style.fill,
      close: true, {
        fast-bezier(
          (0, 0),
          (l, w / 2),
          (l / 3, w / 8))
        fast-bezier(
          (l, w / 2),
          (l, -w / 2),
          (l - i, 0))
        fast-bezier(
          (l, -w / 2),
          (0, 0),
          (l / 3, -w / 8))
      },
    )

    let thickness = style.canvas-thickness
    create-triangle-tip-and-base-anchor(style, (0, 0), (l - i + thickness / 2, 0))
  },
  bar: (style) => {
    import "/src/draw.typ": anchor

    let w = style.width

    let pts = if style.harpoon {
      ((0, w / 2), (0, 0))
    } else {
      ((0, w / 2), (0, -w / 2))
    }

    fast-line(..pts, stroke: style.stroke, fill: style.fill)
    let offset = style.canvas-thickness / 2
    create-tip-and-base-anchor(style, (-offset, 0), (offset, 0))
    anchor("center", (0, 0))
  },
  ellipse: (style) => {
    import "/src/draw.typ": arc, circle

    let r = (style.length / 2, style.width / 2)

    if style.harpoon {
      arc((0, 0), stroke: style.stroke, fill: style.fill, delta: -180deg, start: 0deg, radius: r, anchor: "origin", mode: "PIE")
    } else {
      circle((0, 0), radius: r, fill: style.fill, stroke: style.stroke)
    }

    create-tip-and-base-anchor(style, (r.at(0), 0), (-r.at(0), 0), respect-stroke-thickness: true)
  },
  circle: (style) => {
    import "/src/draw.typ": arc, circle

    let r = calc.min(style.length, style.width) / 2

    if style.harpoon {
      arc((0, 0), delta: -180deg, start: 0deg, radius: r, anchor: "origin", mode: "PIE", stroke: style.stroke, fill: style.fill)
    } else {
      circle((0, 0), radius: r, fill: style.fill, stroke: style.stroke)
    }

    create-tip-and-base-anchor(style, (r, 0), (-r, 0), respect-stroke-thickness: true)
  },
  bracket: (style) => {
    let (l, w, i) = (style.length, style.width, style.inset)

    let pts = if style.harpoon {
      ((l + i, w / 2), (0, w / 2), (0, 0))
    } else {
      ((l + i, w / 2), (0, w / 2), (0, -w / 2), (l + i, -w / 2))
    }

    fast-line(..pts, stroke: style.stroke, fill: none)
    create-tip-and-base-anchor(style, (0, 0), (0, 0), respect-stroke-thickness: true)
  },
  diamond: (style) => {
    let (l, w) = (style.length, style.width)

    let pts = if style.harpoon {
      ((0,0), (l / 2, w / 2), (l, 0))
    } else {
      ((0,0), (l / 2, w / 2), (l, 0), (l / 2, -w / 2))
    }

    fast-line(..pts, stroke: style.stroke, fill: style.fill, close: true)
    create-diamond-tip-and-base-anchor(style, (0, 0), (l, 0))
  },
  rect: (style) => {
    import "/src/draw.typ": *

    let (l, w) = (style.length, style.width)

    if style.harpoon {
      rect((0, -w / 2), (-l, +w / 2), stroke: style.stroke)
    } else {
      rect((0, -w / 2), (-l, +w / 2), stroke: style.stroke)
    }

    create-tip-and-base-anchor(style, (0, 0), (-l, 0), respect-stroke-thickness: true)
  },
  hook: (style) => {
    import "/src/draw.typ": merge-path, arc

    let r = calc.min(style.length, style.width / 2) / 2
    let (l, i) = (style.length, style.inset)

    merge-path({
      fast-line((i, -2 * r), (0, -2 * r))
      arc((0, 0), delta: -180deg, start: -90deg, radius: r, anchor: "end")
      if not style.harpoon {
        arc((0, 0), delta: -180deg, start: -90deg, radius: r, anchor: "start")
        fast-line((i, +2 * r), (0, +2 * r))
      }
    }, stroke: style.stroke, fill: none)

    create-tip-and-base-anchor(style, (-r, 0), (0, 0), center: ((-r + i) / 2, 0))
  },
  // An unfilled mark in the shape of an angle bracket (>).
  straight: (style) => {
    let (l, w) = (style.length, style.width)

    let pts = if style.harpoon {
      ((l, w / 2), (0, 0))
    } else {
      ((l, w / 2), (0, 0), (l, -w / 2))
    }

    fast-line(..pts, stroke: style.stroke, fill: none)
    if style.harpoon {
      create-tip-and-base-anchor(style, (0, 0), (0, 0))
    } else {
      create-triangle-tip-and-base-anchor(style, (0, 0), (0, 0))
    }
  },
  barbed: (style) => {
    import "/src/draw.typ": merge-path, anchor

    let style = style
    style.stroke.join = "round"

    let (l, w) = (style.length, style.width)

    let thickness = style.canvas-thickness / 2
    let offset = if not style.reverse {
      thickness
    } else { 0 }
    let ctrl-a = (l + offset, 0)
    let ctrl-b = (0 + offset, 0)

    merge-path({
      fast-bezier((l + offset, w / 2), (offset, 0), ctrl-a, ctrl-b)
      if not style.harpoon {
        fast-bezier((offset, 0), (l + offset, -w / 2), ctrl-b, ctrl-a)
      }
    }, ..style)

    anchor("tip", (0, 0))
    anchor("base", (thickness, 0))
    anchor("reverse-tip", (0, 0))
    anchor("reverse-base", (-thickness, 0))
  },
  plus: (style) => {
    let (l, w) = (style.length, style.width)

    fast-line((-l / 2, 0), (+l / 2, 0), stroke: style.stroke)
    fast-line((0, -w / 2), (0, +w / 2), stroke: style.stroke)

    create-tip-and-base-anchor(style, (0, 0), (0, 0))
  },
  x: (style) => {
    let (l, w) = (style.length, style.width)

    fast-line((-l / 2, w / 2), (+l / 2, -w / 2), stroke: style.stroke)
    fast-line((-l / 2, -w / 2), (+l / 2, +w / 2), stroke: style.stroke)

    create-tip-and-base-anchor(style, (0, 0), (0, 0))
  },
  star: (style) => {
    let (l, w) = (style.length, style.width)

    let n = 5
    for i in range(0, n) {
      let a = 360deg / n * i
      fast-line((0, 0), (calc.cos(a) * l / 2, calc.sin(a) * w / 2), stroke: style.stroke)
    }

    create-tip-and-base-anchor(style, (0, 0), (0, 0))
  },
  parenthesis: (style) => {
    import "/src/draw.typ": *

    let thickness = style.canvas-thickness
    let width = style.width / 2
    let angle = style.at("angle", default: 80deg) / 2
    let radius = width / calc.sin(angle)
    let offset = radius / 4 + style.canvas-thickness / 2

    arc((-offset, 0), stroke: style.stroke, radius: radius, start: -angle, stop: angle, anchor: "center")

    anchor("tip", (0, 0))
    anchor("base", (-thickness, 0))
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
  ")>": ("curved-stealth", (:)),
  ">>": ("stealth",  (:)),
  ")":  ("parenthesis", (:)),
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
