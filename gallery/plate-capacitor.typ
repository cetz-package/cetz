// Copied from https://github.com/janosh/tikz/blob/87754ea/assets/plate-capacitor/plate-capacitor.typ

#import "@preview/cetz:0.4.1": canvas, draw
#import draw: line, rect, content, bezier, group, anchor

#set page(width: auto, height: auto, margin: 5pt)

// Constants
#let height = 5
#let width = 4
#let plate-width = 0.5
#let diel-width = 0.16 * width
#let n-field-lines = 7
#let n-charges = 7

// Colors
#let e-color = rgb("#e67300")
#let plus-color = rgb("#cc2200").transparentize(20%)
#let minus-color = rgb("#0044cc").transparentize(20%)

// Helper function to draw a capacitor plate with charges
#let plate(x, is-anode: true) = {
  let color = if is-anode { plus-color } else { minus-color }
  let fill-base = if is-anode { rgb("#f29797") } else { rgb("#9fc2f6") }
  let sign = if is-anode { $+$ } else { $-$ }

  // Draw plate with gradient fill
  rect(
    (x, 0),
    (x + plate-width, height),
    stroke: (paint: color, thickness: .7pt),
    fill: gradient.linear(fill-base.lighten(50%), fill-base, angle: 90deg),
  )
  // Draw charge label
  content(
    (x + plate-width / 2, height + 0.1),
    text(fill: color)[$sign Q_"C"$],
    anchor: "south",
  )
  // Draw charges
  for ii in range(n-charges) {
    let y = ii * height / n-charges + 0.325
    content((x + plate-width / 2, y), text(fill: color)[$sign$])
  }
}

// Helper function to draw a dipole
#let dipole(x, y, ..style) = group({
  let plus-grad = gradient.linear(
    angle: 90deg,
    minus-color.lighten(30%),
    minus-color.darken(30%),
  )
  let minus-grad = gradient.linear(
    angle: 90deg,
    plus-color.lighten(30%),
    plus-color.darken(30%),
  )
  rect(x, ((x, "|-", y), 50%, y), fill: plus-grad, radius: (west: .5), name: "minus", ..style)
  rect(y, ((x, "-|", y), 50%, x), fill: minus-grad, radius: (east: .5), name: "plus", ..style)
  content("plus", [+])
  content("minus", [--])
})

#canvas({
  // Dielectric slab
  rect(
    (diel-width, -0.03 * height),
    (width - diel-width, 1.08 * height),
    stroke: e-color,
    fill: rgb("#fff8f0"), // very light orange
  )
  content((width / 2, 1.15 * height), text(fill: e-color)[$arrow(E)$])
  content((width * 0.8, 1.09 * height), text(fill: minus-color)[$+Q_"surf"$], anchor: "south")
  content((1.3 * diel-width, 1.09 * height), text(fill: plus-color)[$-Q_"surf"$], anchor: "south")

  // Electric field lines
  for ii in range(n-field-lines) {
    let y = (ii + 0.42) * height / n-field-lines
    line(
      (-plate-width, y),
      (width + plate-width, y),
      stroke: (paint: e-color, thickness: 1.2pt),
      mark: (pos: 0.5, end: "stealth", fill: e-color),
    )
  }

  // Draw plates
  plate(width, is-anode: false) // Left plate (cathode)
  plate(-plate-width, is-anode: true) // Right plate (anode)

  // Dipoles
  for x in (0.3, 0.5, 0.7) {
    for ii in range(n-field-lines) {
      let y = (ii + 0.94) * height / n-field-lines
      dipole((x * width - 0.3, y - 0.12), (x * width + 0.3, y + 0.12), stroke: 0.5pt)
    }
  }
})
