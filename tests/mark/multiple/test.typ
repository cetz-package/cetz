#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#let l = (">", ">", ">")

#box(stroke: 2pt + red, canvas({
  import draw: *
  rect((1,-2), (2,2))
  rect((-2,-2), (-1,2))
  bezier((-1,-.5), (1,1), (0,-.5), (0,1),
    mark: (start: l, end: l, fill: red, stroke: blue, flex: false))
  bezier((-1,-1.5), (1,0), (0,-1.5), (0,0),
    mark: (start: l, end: l, fill: red, stroke: blue, flex: false, scale: .05))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *
  rect((1,-2), (2,2))
  rect((-2,-2), (-1,2))
  bezier((-1,-.5), (1,1), (0,-.5), (0,1),
    mark: (start: l, end: l, fill: red, stroke: blue, flex: true))
  bezier((-1,-1.5), (1,0), (0,-1.5), (0,0),
    mark: (start: l, end: l, fill: red, stroke: blue, flex: true, scale: .05))
}))
