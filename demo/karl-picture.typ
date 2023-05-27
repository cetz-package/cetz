#import "../canvas.typ": *

#show math.equation: block.with(fill: white, inset: 2pt)

= A Picture for Karl's Students

#canvas(length: 4cm,   {
  import "../draw.typ": *
  
  stroke(gray + .2pt)
  for v in range(-10, 11, step: 5) {
    line((v/10, -1.4), (v/10, 1.4))
    line((-1.4, v/10), (1.4, v/10))
  }

  fill(green)
  arc((0,0), 0deg, 30deg, radius: 0.25, mode: "PIE", anchor: "origin", name: "arc")

  stroke(black + .5pt)
  fill(black)
  line((-1.5, 0), (1.5, 0), mark-end: ">", mark-begin: ">")
  line((0, 1.5), (0, -1.5), mark-end: ">", mark-begin: ">")
  fill(none)
  circle((0,0), radius: 1)

  stroke(red + 2pt)
  line((30deg, 1), (rel: (0, -0.5)), name: "red line")
  stroke(blue + 2pt)
  line("red line.end", (0,0))
  stroke(orange + 2pt)
  line((1, 0), (rel: (0, calc.tan(30deg))), name: "orange line")

  stroke(black)
  line("orange line.end", (0,0))

  content("red line.center", [$ sin alpha $], anchor: "right")
  content((0.5, -0.03), [$ cos alpha $], anchor: "above")
  content("arc.center", [$a$])
  content("orange line.center", [$ tan alpha = (sin alpha)/(cos alpha) $], anchor: "left")

  for (x, xtext) in ((-1, [$ -1 $]), (-0.5,[$ -1/2 $]), (1, [$ 1 $])) {
    line((x, 0.1), (rel: (0, -0.2)))
    content((rel: (0, -0.1)), xtext)
  }
  for (y, ytext) in ((-1, [$ -1 $]), (-0.5,[$ -1/2 $]),(0.5,[$ 1/2 $]), (1, [$ 1 $])) {
    line((0.1, y), (rel: (-0.2, 0)))
    content((rel: (-0.1, 0)), ytext)
  }
})

This is a "where we are" demo by comparing this library's functionality with Tikz. 

Things missing:
  - Easy coloring of math

The comparison can be made here: #link("https://tikz.dev/tutorial")
