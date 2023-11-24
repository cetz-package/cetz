#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#let test(..args) = {
  import draw: *
  rect(..args, name: "r")
  for-each-anchor("r", n => {
    circle("r." + n, radius: .05, fill: gray)
  })
}

#box(stroke: 2pt + red, canvas({
  import draw: *

  test((-1,-1), (1,1))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *

  test((-1,-1), (1,1), radius: 0)
  set-origin((2.5, 0))
  test((-1,-1), (1,1), radius: .5)
  set-origin((2.5, 0))
  test((-1,-1), (1,1), radius: 1)
}))

#box(stroke: 2pt + red, canvas({
  import draw: *

  test((-1,-1), (1,1), radius: (north: 1))
  set-origin((2.5, 0))
  test((-1,-1), (1,1), radius: (east: 1))
  set-origin((2.5, 0))
  test((-1,-1), (1,1), radius: (south: 1))
  set-origin((2.5, 0))
  test((-1,-1), (1,1), radius: (west: 1))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *

  test((-1,-1), (1,1), radius: (north-west: 1))
  set-origin((2.5, 0))
  test((-1,-1), (1,1), radius: (north-east: 1))
  set-origin((2.5, 0))
  test((-1,-1), (1,1), radius: (south-east: 1))
  set-origin((2.5, 0))
  test((-1,-1), (1,1), radius: (south-west: 1))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *

  test((-1,-1), (1,1), radius: (north-west: 1, north-east: .5,
    south-west: .25, rest: 0.1))
}))

// Use ratio values
#box(stroke: 2pt + red, canvas({
  import draw: *

  test((-1,-1), (3,1), radius: (north-west: 50%, north-east: 25%,
    south-west: 10%, rest: 0))
}))

// Use different x & y radii
#box(stroke: 2pt + red, canvas({
  import draw: *

  test((-1,-1), (3,1), radius: (north-west: (50%, .2), south-east: (50%, .2)))
}))
