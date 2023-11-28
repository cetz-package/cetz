#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#box(stroke: 2pt + red, canvas({
  import draw: *

  arc((0,0), start: 0deg, stop: 180deg)
  circle((), radius: .1, fill: blue)
}))

#box(stroke: 2pt + red, canvas({
  import draw: *

  arc((0,0), start: 180deg, stop: 0deg)
  circle((), radius: .1, fill: blue)
}))
