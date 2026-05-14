#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *
  let (a, b, c) = ((0,0), (2,-.5), (1,1))
  point(a, [])
  point(b, [])
  point(c, [])
  circle-through(a, b, c, name: "c")
  point("c.center", [center], anchor: "north", offset: (0, -0.25em))
})

#test-case({
  import draw: *
  let (a, b, c) = ((-1, 0), (0, 0.25), (1, 0))
  point(a, [])
  point(b, [])
  point(c, [])
  circle-through(a, b, c, name: "c")
  point("c.center", [center], anchor: "north", offset: (0, -0.25em))
})

#test-case({
  import draw: *
  let (a, b) = ((-1, 0), (1, 0))
  point(a, [])
  point(b, [])
  circle-through(a, b, b, name: "c")
  point("c.center", [center], anchor: "north", offset: (0, -0.25em))
})
