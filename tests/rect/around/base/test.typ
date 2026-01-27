#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#box(stroke: 2pt + red, canvas({
  import draw: *

  circle((1, 1), radius: 0.1, fill: blue, name: "c1")
  circle((0, 1), radius: 0.1, fill: red, name: "c2")
  rect((0, 2), (1, 2.5), name: "r1")
	rect-around("c1", "c2", "r1", (0.5, 0.5), stroke: yellow, padding: 0.1)
}))
