#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import cetz.draw: *

  set-style(mark: (shape-transform: true))

  scale(x: 3)
  line((-1,-1), (1,1), mark: (start: "rect", end: "]"))
})

#test-case({
  import cetz.draw: *

  set-style(mark: (shape-transform: false))

  scale(x: 3)
  line((-1,-1), (1,1), mark: (start: "rect", end: ">"))
})

#test-case({
  import cetz.draw: *

  set-style(mark: (shape-transform: false))

  rotate(45deg)
  line((-1,-1), (1,-1), (1,1), mark: (start: "rect", end: "rect", scale: 3))
})
