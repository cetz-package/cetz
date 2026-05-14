#set page(width: auto, height: auto)
#import "/src/lib.typ" as cetz
#import "/tests/helper.typ": *

#test-case(pt => {
  import cetz.draw: *
  rect((0, 0), pt, name: "r")
  show-compass-anchors("r")
}, args: ((1, 1), (2, 1)))

#test-case(pt => {
  import cetz.draw: *
  rect((0, 0), pt, name: "r")
  show-border-anchors("r")
}, args: ((1, 1), (2, 1)))

#test-case(pt => {
  import cetz.draw: *
  rect((0, 0), pt, name: "r")
  show-path-anchors("r")
}, args: ((1, 1), (2, 1)))
