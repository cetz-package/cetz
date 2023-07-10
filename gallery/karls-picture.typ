#import "@local/cetz:0.0.1"

#set page(width: auto, height: auto, margin: .5cm)

#show math.equation: block.with(fill: white, inset: 1pt)

#cetz.canvas(length: 3cm, {
  import cetz.draw: *

  set-style(
    mark: (fill: black),
    stroke: (thickness: 0.4pt, cap: "round"),
    arc: (
      radius: 0.3,
      mode: "PIE",
      fill: green.lighten(80%),
      stroke: (paint: green.darken(50%))
    ),
    content: (padding: 1pt)
  )

  grid((-1.5, -1.5), (1.4, 1.4), step: 0.5, stroke: gray + 0.2pt)

  circle((0,0), radius: 1)

  line((-1.5, 0), (1.5, 0), mark: (end: ">"))
  content((), $ x $, anchor: "left")
  line((0, -1.5), (0, 1.5), mark: (end: ">"))
  content((), $ y $, anchor: "bottom")

  for (x, ct) in ((-1, $ -1 $), (-0.5, $ -1/2 $), (1, $ 1 $)) {
    line((x, 3pt), (x, -3pt))
    content((), anchor: "above", ct)
  }

  for (y, ct) in ((-1, $ -1 $), (-0.5, $ -1/2 $), (0.5, $ 1/2 $), (1, $ 1 $)) {
    line((3pt, y), (-3pt, y))
    content((), anchor: "right", ct)
  }

  // Draw the green angle
  arc((0,0), start: 0deg, stop: 30deg, anchor: "origin", name: "arc")
  content((15deg + 4deg, 0.2), text(green)[#sym.alpha])

  line((0,0), (1, calc.tan(30deg)))

  set-style(stroke: (thickness: 1.2pt))

  line((30deg, 1), ((), "|-", (0,0)), stroke: (paint: red), name: "sin")
  content("sin", text(red)[$ sin alpha $], anchor: "right")
  line("sin.end", (0,0), stroke: (paint: blue), name: "cos")
  content("cos", text(blue)[$ cos alpha $], anchor: "top")
  line((1, 0), (1, calc.tan(30deg)), name: "tan", stroke: (paint: orange))
  content("tan", $ text(#orange, tan alpha) = text(#red, sin alpha) / text(#blue, cos alpha) $, anchor: "left")
})
