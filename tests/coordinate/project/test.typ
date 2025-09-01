#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *

  let orig = (0, 0)
  let (o, a, b) = ((0, 0), (45deg, 2), (5deg, 2.25))
  line(o, a, mark: (end: ">"), name: "v1")
  line(o, b, mark: (end: ">"), name: "v2")

  line("v1.80%", (project: (), onto: ("v2.start", "v2.end")),
    stroke: red)

  line("v1.60%", ((), "_|_", "v2.start", "v2.end"),
    stroke: blue)

  line("v1.40%", ((), "⟂", "v2.start", "v2.end"),
    stroke: green)
})
