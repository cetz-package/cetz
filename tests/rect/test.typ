#set page(width: auto, height: auto)
#import "../../src/lib.typ": *

#box(stroke: 2pt + red, canvas({
  import draw: *

  rect((1,1), (0,0), name: "r")
  circle("r.center", radius: .1)
  circle("r.top", fill: red, radius: .1)
  circle("r.bottom", fill: green, radius: .1)
  circle("r.left", fill: blue, radius: .1)
  circle("r.right", fill: yellow, radius: .1)
}))
