#set page(width: auto, height: auto)
#import "../../src/lib.typ": *

#box(stroke: 2pt + red, canvas({
  import draw: *
  catmull((0,0), (1,0))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *
  catmull((0,-1), (1,1), (2,0), (3,1), (4,0), (5,2), k: .3)
}))

#box(stroke: 2pt + red, canvas({
  import draw: *
  catmull((0,-1), (1,1), (2,0), (3,1), (4,0), (5,2))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *
  catmull((0,-1), (1,1), (2,0), (3,1), (4,0), (5,2), k: .7)
}))

#box(stroke: 2pt + red, canvas({
  import draw: *
  catmull((0,-1), (1,1), (2,0), k: .45, close: true, fill: blue)
}))
