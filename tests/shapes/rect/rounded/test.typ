#set page(width: auto, height: auto)
#import "/src/lib.typ" as cetz
#import "/tests/helper.typ": *

#let r = (rest: 0.25, north-west: 1, south-west: 0, south-east: (0.5, 0.1))

#test-case(pt => {
  import cetz.draw: *
  rect((0, 0), pt, name: "r", radius: r)
  show-compass-anchors("r")
}, args: ((1, 1), (2, 1)))

#test-case(pt => {
  import cetz.draw: *
  rect((0, 0), pt, name: "r", radius: r)
  show-border-anchors("r")
}, args: ((1, 1), (2, 1)))

#test-case(pt => {
  import cetz.draw: *
  rect((0, 0), pt, name: "r", radius: r)
  show-path-anchors("r")
}, args: ((1, 1), (2, 1)))
