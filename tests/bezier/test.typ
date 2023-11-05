#set page(width: auto, height: auto)
#import "/src/lib.typ": *

/* Make sure the current position is set to the curves end point [236] */
#block(stroke: 2pt + red, canvas(length: .5cm, {
  import draw: *

  set-style(radius: .1)
  circle((), fill: green)
  bezier((0,0), (3, 0), (1,1), (2,-1))
  circle((), fill: red)
}))
