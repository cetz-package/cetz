#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#let l = (">", ">", ">",)

#box(stroke: 2pt + red, canvas({
  import draw: *
  rect((1,-2), (2,2))
  rect((-2,-2), (-1,2))
  line((-1,-.5), (1,1),
    mark: (start: l, end: l, fill: red, stroke: blue))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *
  rect((1,-2), (2,2))
  rect((-2,-2), (-1,2))
  bezier((-1,-.5), (1,1), (0,-.5), (0,1),
    mark: (start: l, end: l, fill: red, stroke: blue, flex: false))
  bezier((-1,-1.5), (1,0), (0,-1.5), (0,0),
    mark: (start: l, end: l, fill: red, stroke: blue, flex: false, scale: .5))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *
  rect((1,-2), (2,2))
  rect((-2,-2), (-1,2))
  bezier((-1,-.5), (1,1), (0,-.5), (0,1),
    mark: (start: l, end: l, fill: red, stroke: blue, flex: true))
  bezier((-1,-1.5), (1,0), (0,-1.5), (0,0),
    mark: (start: l, end: l, fill: red, stroke: blue, flex: true, scale: .5))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *
  rect((1,-2), (2,2))
  rect((-2,-2), (-1,2))
  catmull((-1,-.5), (0,-.5), (0,1), (1,1),
    mark: (start: l, end: l, fill: red, stroke: blue, flex: true))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *
  line((-.5,1), (2.5,1))
  arc((1,1), start: 0deg, stop: 180deg, anchor: "origin",
    mark: (start: l, end: l, fill: red, stroke: blue))
  arc((1,1), start: 180deg, stop: 360deg, anchor: "origin",
    mark: (start: l, end: l, fill: red, stroke: blue))
}))
