#set page(width: auto, height: auto)
#import "../../src/lib.typ": *

#box(stroke: 2pt + red, canvas({
  import draw: *

  group(name: "g", {
    translate((-.5, .5, 0))

    // CCW
    rotate(30deg)

    rect((0, 0), (1, 1), name: "r")
    anchor("1", "r.north-west")
    anchor("2", "r.north-east")
    anchor("3", "r.south-west")
    anchor("4", "r.south-east")
  })

  stroke(green)
  circle("g.1", radius: .1)
  circle("g.2", radius: .1)
  circle("g.3", radius: .1)
  circle("g.4", radius: .1)
}))

#let draw-xyz() = {
  import draw: *
  line((-1,0), (1,0), stroke: red)
  line((0,-1), (0,1), stroke: blue)
  line((0,0,-1), (0,0,1), stroke: green)
}

#box(stroke: 2pt + red, canvas({
  import draw: *

  set-transform(none)
  rotate(z: 45deg)
  draw-xyz()
}))
#box(stroke: 2pt + red, canvas({
  import draw: *

  set-transform(none)
  rotate(x: 45deg)
  draw-xyz()
}))
#box(stroke: 2pt + red, canvas({
  import draw: *

  set-transform(none)
  rotate(y: 45deg)
  draw-xyz()
}))

#box(stroke: 2pt + red, canvas({
  import draw: *

  set-transform(none)
  rotate(yaw: 45deg)
  draw-xyz()
}))
#box(stroke: 2pt + red, canvas({
  import draw: *

  set-transform(none)
  rotate(pitch: 45deg)
  draw-xyz()
}))
#box(stroke: 2pt + red, canvas({
  import draw: *

  set-transform(none)
  rotate(roll: 45deg)
  draw-xyz()
}))
