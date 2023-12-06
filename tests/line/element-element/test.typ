#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#let test(a, b, ..line-args) = {
  import draw: *

  a; b;
  line("a", "b", ..line-args)
}

#box(stroke: 2pt + red, canvas({
  import draw: *

  test(rect((0,-.5), (rel: (1,1)), name: "a"),
       circle((3,0), name: "b"))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *

  test(rect((0,-1), (rel: (1,1)), name: "a"),
       circle((2,1), name: "b"))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *

  test(rect((0,-2), (rel: (1,1)), name: "a"),
       circle((2,2), name: "b"))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *

  test(rect((0,0), (rel: (1,1)), name: "a"),
       rect((0,0), (rel: (1,1)), name: "b"))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *

  set-style(content: (padding: .1))
  test(content((0,0), [Text], frame: "rect", name: "a"),
       content((1,1), [Text], frame: "rect", name: "b"))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *

  set-style(content: (padding: .1))
  test(rect((0,0), (rel: (1,1)), name: "a"),
       group({
         line((2,2), (3,1), (rel: (0,2)), (rel: (-.1, -1.6)), close: true)
         anchor("center", (5,3))
       }, name: "b"))
}))
