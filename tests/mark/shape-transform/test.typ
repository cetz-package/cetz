#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import cetz.draw: *

  set-style(mark: (transform-shape: true))

  scale(x: 3)
  line((-1,-1), (1,1), mark: (start: "rect", end: "]"))
})

#test-case({
  import cetz.draw: *

  set-style(mark: (transform-shape: false))

  scale(x: 3)
  line((-1,-1), (1,1), mark: (start: "rect", end: ">"))
})

#test-case({
  import cetz.draw: *

  set-style(mark: (transform-shape: false))

  rotate(45deg)
  line((-1,-1), (1,-1), (1,1), mark: (start: "rect", end: "rect", scale: 3))
})

#test-case({
  import cetz.draw: *

  set-style(mark: (transform-shape: false))

  rotate(30deg)
  rect((-1,-1), (1,1))

  mark((0,0), symbol: "x")
})
