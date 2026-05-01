// The render should succeed (no panic) and produce a grid only.

#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *

  grid(
    (-3, -2),
    (3, 2),
    step: 1,
    stroke: 0.2pt + gray,
  )

  let A = circle((0, 0), radius: 2)
  let C = circle((1, 0), radius: 1.5)

  // Y is the empty set: a shape minus itself.
  let Y = path-bool({ C }, { C }, op: "difference", stroke: black)

  Y

  // Difference with empty Y: ∅ - A = ∅. Must not panic.
  path-bool({ Y }, { A }, op: "difference", fill: red, stroke: black)

  // Empty input as a (b non-empty): ∅ inter A = ∅. Must not panic.
  path-bool({ Y }, { A }, op: "intersection", fill: blue, stroke: none)
})
