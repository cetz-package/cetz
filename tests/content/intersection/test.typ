#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *
  set-style(fill: gray, stroke: gray)

  intersections("i", {
    content((0,0), [Text])
    on-layer(-1, {
      line((1,1), (-1,-1))
      bezier((-1,0), (1,0), (-.5,.5), (.5,-.5), fill: none)
    })
  })
  on-layer(-1, {
    for-each-anchor("i", n => {
      circle("i." + n, radius: .05)
    })
  })
})

#test-case({
  import draw: *

  draw.content(name: "test1", frame: "rect", (0,0))[Test 1]
  draw.content(name: "test2", frame: "rect", (-1,-1))[Test 2]
  draw.line("test1", "test2")
})

#test-case({
  let thide = hide
  import draw: *

  draw.content(name: "test1", (0,0))[Test 1]
  draw.content((-1,-1))[#box(stroke: 1pt + red, thide[Test 2])]
  draw.content(name: "test2", frame: "rect", anchor: "north-east", (-1,-1))[Test 2]
  draw.line("test1", "test2")
})

#test-case({
  let thide = hide
  import draw: *

  draw.content(name: "test1", (0,0))[Test 1]
  draw.content((-1,-1))[#box(stroke: 1pt + red, thide[Test 2])]
  draw.content(name: "test2", frame: "rect", anchor: "south", (-1,-1))[Test 2]
  draw.line("test1", "test2")
})

#test-case({
  import draw:*
  content((-1,0), [Text], name: "a")
  content((+1,0), [Text], name: "b")
  line("a", "b")
})
