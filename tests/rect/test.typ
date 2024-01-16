#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#box(stroke: 2pt + red, canvas({
  import draw: *

  rect((1,1), (0,0), name: "r")
  circle("r.center", radius: .1)
  circle("r.north", fill: red, radius: .1)
  circle("r.south", fill: green, radius: .1)
  circle("r.west", fill: blue, radius: .1)
  circle("r.east", fill: yellow, radius: .1)
}))
