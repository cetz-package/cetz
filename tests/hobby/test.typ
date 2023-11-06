#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#box(stroke: 2pt + red, canvas({
  import draw: *
  hobby((0,0), (1,0))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *
  hobby((0,-1), (1,1), (2,0), (3,1), (4,0), (5,2), omega: 0)
}))

#box(stroke: 2pt + red, canvas({
  import draw: *
  hobby((0,-1), (1,1), (2,0), (3,1), (4,0), (5,2), omega: .5)
}))

#box(stroke: 2pt + red, canvas({
  import draw: *
  hobby((0,-1), (1,1), (2,0), (3,1), (4,0), (5,2), omega: 1)
}))

#box(stroke: 2pt + red, canvas({
  import draw: *
  hobby((0,-1), (1,1), (2,0), (3,1), (4,0), (5,2), close: true, fill: blue)
}))

#box(stroke: 2pt + red, canvas({
  import draw: *
  hobby((0,-1), (1,1), (2,0), (3,1), (4,0), (5,2),
    rho: (a, b) => 0)
}))
