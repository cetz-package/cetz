#import "@preview/cetz:0.5.1"
#set page(width: auto, height: auto, margin: .5cm)

#show math.equation: block.with(fill: white, inset: 1pt)

// Create a new canvas to draw on
#cetz.canvas(length: 3cm, {
  import cetz.draw: *

  // Change the design for all elements after it
  set-style(
    // Design of arrow tips at the end of lines
    mark: (fill: black, scale: 2),
    // Design of lines
    stroke: (thickness: 0.4pt, cap: "round"),
    // Design of angles
    angle: (
      radius: 0.3,
      label-radius: .22,
      fill: green.lighten(80%),
      stroke: (paint: green.darken(50%))
    ),
    // Design of all text elements with an anchor
    content: (padding: 1pt)
  )

  // Draws the grid behind the circle
  grid((-1.5, -1.5), (1.4, 1.4), step: 0.5, stroke: gray + 0.2pt)

  // Draw the unit circle
  circle((0,0), radius: 1)

  // Draw the axis lines and axis labels
  line((-1.5, 0), (1.5, 0), mark: (end: "stealth"))
  content((), $ x $, anchor: "west")
  line((0, -1.5), (0, 1.5), mark: (end: "stealth"))
  content((), $ y $, anchor: "south")

  // Draw the number steps on the x-axis
  for (x, ct) in ((-1, $ -1 $), (-0.5, $ -1/2 $), (1, $ 1 $)) {
    line((x, 3pt), (x, -3pt))
    content((), anchor: "north", ct)
  }

  // Draw the number steps on the y-axis
  for (y, ct) in ((-1, $ -1 $), (-0.5, $ -1/2 $), (0.5, $ 1/2 $), (1, $ 1 $)) {
    line((3pt, y), (-3pt, y))
    content((), anchor: "east", ct)
  }

  // Draw the green angle
  cetz.angle.angle((0,0), (1,0), (1, calc.tan(30deg)),
    label: text(green, [#sym.alpha]))

  // Draw the hypothenuse of the triangle
  line((0,0), (1, calc.tan(30deg)))

  // Change the stroke for all upcoming elements
  set-style(stroke: (thickness: 1.2pt))

  // Draw the inner opposite leg of the triangle:
  // "The intersection of a vertical line (|-) through (30deg, 1) and a horizontal line through (0, 0)"
  line((30deg, 1), ((), "|-", (0,0)), stroke: (paint: red), name: "sin")
  // Place the text halfway through on the opposite leg
  content(("sin.start", 50%, "sin.end"), text(red)[$ sin alpha $])
  
  // Draw the adjacent leg of the triangle
  line("sin.end", (0,0), stroke: (paint: blue), name: "cos")
  // Place the text halfway and position it below the line
  content(("cos.start", 50%, "cos.end"), text(blue)[$ cos alpha $], anchor: "north")

  // Draw the outer opposite leg of the triangle
  line((1, 0), (1, calc.tan(30deg)), name: "tan", stroke: (paint: orange))
  // Draw the tangent equasion at the top and to the right of the line
  content("tan.end", $ text(#orange, tan alpha) = text(#red, sin alpha) / text(#blue, cos alpha) $, anchor: "west")
})
