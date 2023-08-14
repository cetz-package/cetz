#set page(width: auto, height: auto)
#import "../../src/lib.typ": *

#box(stroke: 2pt + red, canvas({
  import draw: *

  group(name: "g", {
    translate((-1.5, .5, 0))

    rect((0, 0), (1, 1))
    anchor("tl", (0, 0))
    anchor("tr", (1, 0))
    anchor("bl", (0, 1))
    anchor("br", (1, 1))
  })

  group({
    line((-2, 0), (2, 0))
    line((0, -2), (0, 2))
  })

  stroke(green)
  circle("g.tl", radius: .1)
  circle("g.tr", radius: .1)
  circle("g.bl", radius: .1)
  circle("g.br", radius: .1)
}))

#box(stroke: 2pt + red, canvas({
  import draw: *

  rect((0, 0), (1, 1), name: "a", fill: blue)
  content("a.center", [A])

  // The translation must not get scaled to 2,
  // the rects have to touch at the edge.
  group({
    translate((0, 1))
    scale(2)
    rect((0, 0), (1, 1), name: "b", fill: green)
    content("b.center", [B])
  })

  // Translation should get scaled if multiplied post
  // scaling.
  group({
    scale(2)
    translate((.5, 0), pre: false)
    rect((0, 0), (.5, .5), name: "c", fill: red)
    content("c.center", [C])
  })
}))
