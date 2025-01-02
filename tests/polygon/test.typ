#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import cetz.draw: *

  polygon((0, 0), 5, radius: 1, name: "poly")

  for-each-anchor("poly", name => {
    if name.starts-with(regex("(corner|edge)")) {
      circle((), fill: gray, radius: .1)
    }
  })
})

#test-case(sides => {
  import cetz.draw: *

  polygon((0, 0), sides, radius: 1, angle: 90deg)
}, args: (3, 4, 5, 6))

#test-case({
  import cetz.draw: *

  set-style(polygon: (radius: 1, fill: blue, stroke: red + 4pt))
  polygon((0, 0), 6)
})

#test-case({
  import cetz.draw: *

  polygon((0, 0), 6, radius: 1,
    fill: red, stroke: blue + 4pt)
})

#test-case({
  import cetz.draw: *

  polygon((0, 0), 5, name: "p1")
  polygon((2, 2), 3, name: "p2")
  line("p1", "p2")
})
