#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *

  circle((1, 1), radius: 0.1, fill: blue, name: "c1")
  circle((0, 1), radius: 0.1, fill: red, name: "c2")
  rect((0, 2), (1, 2.5), name: "r1")
	rect-around("c1", "c2", "r1", (0.5, 0.5), stroke: yellow, padding: 0.1)
})

#test-case({
  import cetz.draw: *
  rotate(30deg)
  group(name: "foo", {
    circle((0, 0))
    circle((2, 0))
  })
  rect-around((-1, -1), (3, 1))
})

#test-case({
  import cetz.draw: *
  anchor("a", (0,2))
  rotate(30deg)
  group(name: "foo", {
    circle((0, 0))
    circle((2, 0))
  })
  cross("a")
  rect-around("foo", "a")
})

#test-case({
  import cetz.draw: *
  rotate(30deg)
  group(name: "foo", {
    hobby((0,0), (1,2), (4,3), (3,-1), mark: (start: "|", scale: 10, fill: black))
  })
  rect-around("foo")
})

#test-case({
  import cetz.draw: *
  rotate(30deg)

  rect((-1, -0.5), (1, 0.5), name: "r", stroke: 2pt)
  rect-around("r", stroke: green)
  rect-around("r.north-west", "r.south-east", stroke: blue)
})

#test-case({
  import cetz.draw: *

  cross((0, 0))
  content((0, 0), [Label], frame: "circle", anchor: "west", name: "label",)
  rect-around("label", stroke: blue)
})

#test-case({
  import cetz.draw: *

  scope({
    rect((-1, -1), (0, 0), name: "a")
    rotate(45deg, origin: (-.5, -.5))
    rect((-1, -1), (0, 0), name: "b")
  })

  //intersections("i", "a", "b")
  intersections("i", {
    rect((-1, -1), (0, 0), name: "a")
    rotate(45deg, origin: (-.5, -.5))
    rect((-1, -1), (0, 0), name: "b")
  })

  rect-around("i", stroke: blue, ignore-shapes: true)
})
