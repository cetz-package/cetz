#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#let draw-shapes() = {
  import draw: *

  rect((-2,-2), (-1,-1))
  circle((-1.5,1.5), radius: .5)
  line((1,1), (1.5,2), (2,1), close: true)
}

#test-case({
  import draw: *
  grid((-3,-3), (3,3))

  set-style(fill: gray)
  draw-shapes()

  rotate(45deg, origin: (0,0))
  set-style(fill: blue)
  draw-shapes()
})

#test-case({
  import draw: *
  grid((-3,-3), (3,5))

  set-style(fill: gray)
  draw-shapes()

  rotate(45deg, origin: (-1.5,1.5))
  set-style(fill: blue)
  draw-shapes()
})

#test-case({
  import draw: *
  grid((-5,-5), (1,1))

  scale(2, origin: (-2,-2))
  set-style(fill: blue)
  rect((-3,-3), (rel: (1,1)))
  rect((-2,-3), (rel: (1,1)))
  rect((-2,-2), (rel: (1,1)))
  rect((-3,-2), (rel: (1,1)))
})

#test-case({
  import draw: *
  grid((-4,-4), (2,2))

  set-style(fill: gray)
  rect((-3,-3), (rel: (2,2)))

  rotate(45deg, origin: (-2,-2))
  scale(.5, origin: (-2,-2))
  set-style(fill: blue)
  rect((-3,-3), (rel: (2,2)))
})

#test-case({
  import draw: *
  grid((-4,-4), (2,2))

  set-transform(none)
  scale(y: -1)

  set-style(fill: gray)
  rect((-3,-3), (rel: (2,2)))

  rotate(x: 60deg, y: 45deg, origin: (-2,-2))
  set-style(fill: blue)
  rect((-3,-3), (rel: (2,2)))
})
