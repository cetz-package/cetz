#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#let test(..args) = {
  import draw: *
  rect(..args, name: "r")
  for-each-anchor("r", n => {
    circle("r." + n, radius: .05, fill: gray)
  })
}

#test-case({
  import draw: *

  test((-1,-1), (1,1))
})

#test-case({
  import draw: *

  test((-1,-1), (1,1), radius: 0)
  set-origin((2.5, 0))
  test((-1,-1), (1,1), radius: .5)
  set-origin((2.5, 0))
  test((-1,-1), (1,1), radius: 1)
})

#test-case({
  import draw: *

  test((-1,-1), (1,1), radius: (north: 1))
  set-origin((2.5, 0))
  test((-1,-1), (1,1), radius: (east: 1))
  set-origin((2.5, 0))
  test((-1,-1), (1,1), radius: (south: 1))
  set-origin((2.5, 0))
  test((-1,-1), (1,1), radius: (west: 1))
})

#test-case({
  import draw: *

  test((-1,-1), (1,1), radius: (north-west: 1))
  set-origin((2.5, 0))
  test((-1,-1), (1,1), radius: (north-east: 1))
  set-origin((2.5, 0))
  test((-1,-1), (1,1), radius: (south-east: 1))
  set-origin((2.5, 0))
  test((-1,-1), (1,1), radius: (south-west: 1))
})

#test-case({
  import draw: *

  test((-1,-1), (1,1), radius: (north-west: 1, north-east: .5,
    south-west: .25, rest: 0.1))
})

// Use ratio values
#test-case({
  import draw: *

  test((-1,-1), (3,1), radius: (north-west: 50%, north-east: 25%,
    south-west: 10%, rest: 0))
})

// Use different x & y radii
#test-case({
  import draw: *

  test((-1,-1), (3,1), radius: (north-west: (50%, .2), south-east: (50%, .2)))
})

// Use fixed length values
#test-case({
  import draw: *

  test((-1,-1), (3,1), radius: .5cm)
})

// Bug 1: small rect — .east fails, .north works
#test-case({
  import draw: *
  rect((0, 0), (1, 0.45), name: "r")
  circle("r.north-east", radius: 0.05, fill: blue)
  circle("r.east", radius: 0.05, fill: red)
})

// Bug 2: rounded rect — .east fails even on large rects
#test-case({
  import draw: *
  rect((0, 0), (2.4, 0.8), name: "r", radius: 0.3)
  circle("r.east", radius: 0.05, fill: red)
  circle("r.north-east", radius: 0.05, fill: blue)
})
