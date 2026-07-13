#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import cetz.draw: *

  rect((-1,-1),(1,1), name:"r")
  cross("r.0deg")
})
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

// Group with 0 height #1088
#test-case(arg => {
  import cetz.draw: *

  group(name: "g", {
    line((0,0), (1,0))
  })

  cross("g." + arg)
}, args: ("0deg", "45deg", "90deg", "200deg"))

// Group with 0 width #1088
#test-case(arg => {
  import cetz.draw: *

  group(name: "g", {
    line((0,0), (0,1))
  })

  cross("g." + arg)
}, args: ("0deg", "45deg", "90deg", "200deg"))

#test-case(arg => {
  import cetz.draw: *

  group(name: "g", {
    rect((0,0), (1,1))
  })

  cross("g." + arg)
}, args: ("0deg", "45deg", "90deg", "200deg"))
