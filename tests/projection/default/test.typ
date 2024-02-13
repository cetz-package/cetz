#import "/src/lib.typ" as cetz
#import "/tests/helper.typ": *

// Positive direction
#test-case({
  import cetz.draw: *

  set-style(mark: (transform-shape: false))
  line((0,0,0), (1,0,0), mark: (end: ">"))
  line((0,0,0), (0,1,0), mark: (end: ">"))
  line((0,0,0), (0,0,1), mark: (end: ">"))
})

// Negative direction
#test-case({
  import cetz.draw: *

  set-style(mark: (transform-shape: false))
  line((0,0,0), (-1,0,0), mark: (end: ">"))
  line((0,0,0), (0,-1,0), mark: (end: ">"))
  line((0,0,0), (0,0,-1), mark: (end: ">"))
})
