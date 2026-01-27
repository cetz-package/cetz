#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#box(stroke: 2pt + red, canvas({
  import draw: *

	rect((1, 2), (rel:(1, 1)), stroke: none, fill: black, name: "r1")
	rect-around("r1", stroke: yellow, radius: 0.4, padding: (top: 0.1, left: 0.2, right: 0.3, bottom: 0.4), name: "r2")
	rect-around("r2", stroke: 0.5pt + black)
}))
