#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import cetz.draw: *

  set-style(mark: (post-transform: false))

  scale(x: 3)
  line((-1,-1), (1,1), mark: (start: "rect", end: ">"))
})

#test-case({
  import cetz.draw: *

  set-style(mark: (post-transform: true))

  scale(x: 3)
  line((-1,-1), (1,1), mark: (start: "rect", end: ">"))
})
