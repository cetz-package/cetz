#set page(width: auto, height: auto)
#import "/src/lib.typ" as cetz
#import "/tests/helper.typ": *

#test-case(radius => {
  import cetz.draw: *
  circle((0, 0), name: "c", radius: radius)
  show-compass-anchors("c")
}, args: (1, (2, 1)))

#test-case(radius => {
  import cetz.draw: *
  circle((0, 0), name: "c", radius: radius)
  show-border-anchors("c")
}, args: (1, (2, 1)))

#test-case(radius => {
  import cetz.draw: *
  circle((0, 0), name: "c", radius: radius)
  show-path-anchors("c")
}, args: (1, (2, 1)))

#test-case({
  import cetz.draw: *
  point((0, 0), [center], anchor: "north", offset: (0, -0.1))
  point((1, 1), [M], anchor: "south-west", offset: (0.1, 0.1))
  circle((0, 0), (1, 1))
})
