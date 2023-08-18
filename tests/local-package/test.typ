#set page(width: auto, height: auto)

#import "@local/cetz:0.1.0"

#box(stroke: 2pt + red, cetz.canvas({
  import cetz.draw: *
  circle(())
  circle((-.25, .35), radius: (.15, .2))
  circle((rel: (.08, -.09)), radius: .05, fill: black)
  circle((+.25, .35), radius: (.15, .2))
  circle((rel: (.08, -.09)), radius: .05, fill: black)
  bezier((-.5, -.3), (+.5, -.3), (0, -.8))
}))
