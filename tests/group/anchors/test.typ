#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import cetz.draw: *

  set-style(circle: (stroke: none, fill: gray))

  circle((0, 0), radius: .1cm, fill: blue)
  content((0, 0), [(0,0)], anchor: "north", padding: .1)

  group(name: "group", {
    anchor("default", (0, 0))
    rect((-1, 0), (2, 2))
  }, anchor: "north")

  on-layer(-1, {
    for-each-anchor("group", name => {
      circle("group." + name, radius: .1cm, fill: gray, stroke: none)
    })
  })
})
