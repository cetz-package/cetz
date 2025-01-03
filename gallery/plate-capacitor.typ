Copied from https://github.com/janosh/tikz/blob/d8b9cad400895aac3a3c90d00999153010b7c573/assets/plate-capacitor/plate-capacitor.typ#L15

#import "@preview/cetz:0.3.1": canvas, draw
#import draw: line, rect, content, bezier

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
#let plus-color = rgb("#cc2200")
#let minus-color = rgb("#0044cc")

// Helper function to draw a dipole
#let dipole(x, y) = {
  let dph = 0.3 // dipole height
  let dpw = 0.15 // dipole width

  // Negative part
  content(
    (x - dph / 2, y),
    text(0.7em, fill: white)[$-$],
    frame: "rect",
    padding: 2pt,
    stroke: none,
    fill: minus-color,
    radius: 0.2em,
  )

  // Positive part
  content(
    (x + dph / 2, y),
    text(0.7em, fill: white)[$+$],
    frame: "rect",
    padding: 2pt,
    stroke: none,
    fill: plus-color,
    radius: 0.2em,
  )
}

#canvas({
  // Dielectric slab
  rect(
    (diel-width, -0.03 * height),
    (width - diel-width, 1.08 * height),
    stroke: e-color,
    fill: rgb("#fff8f0"), // very light orange
  )
  content((width / 2, 1.15 * height), text(fill: e-color)[$arrow(E)$])
  content((width * 0.8, 1.09 * height), text(fill: plus-color)[$+Q_"surf"$], anchor: "south")
  content((1.3 * diel-width, 1.09 * height), text(fill: minus-color)[$-Q_"surf"$], anchor: "south")

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

  // Plates
  // Left plate (anode)
  rect(
    (-plate-width, 0),
    (0, height),
    stroke: (paint: plus-color, thickness: .7pt),
    fill: rgb("#ffcccc"),
  )
  content((-plate-width / 2 - 0.2, height + 0.1), text(fill: plus-color)[$+Q_"C"$], anchor: "south")

  // Right plate (cathode)
  rect(
    (width, 0),
    (width + plate-width, height),
    stroke: (paint: minus-color, thickness: .7pt),
    fill: rgb("#cce0ff"),
  )
  content((width + plate-width / 2 + 0.2, height + 0.1), text(fill: minus-color)[$-Q_"C"$], anchor: "south")

  // Charges on plates
  for ii in range(n-charges) {
    let y = ii * height / n-charges + 0.325
    content((-plate-width / 2, y), text(fill: plus-color)[$+$])
    content((width + plate-width / 2, y), text(fill: minus-color)[$-$])
  }

  // Dipoles
  for x in (0.3, 0.5, 0.7) {
    for ii in range(n-field-lines) {
      let y = (ii + 0.94) * height / n-field-lines
      dipole(x * width, y)
    }
  }
})
