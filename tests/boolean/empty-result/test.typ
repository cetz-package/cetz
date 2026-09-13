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

  // Keep the operands on a nonzero z-plane. Once Y becomes empty it has no
  // z-plane; treating that as z=0 would make the operations below panic.
  let A = circle((0, 0, 2), radius: 2)
  let C = circle((1, 0, 2), radius: 1.5)

  // Y is the empty set: a shape minus itself.
  let Y = boolean({ C }, { C }, op: "difference", stroke: black)

  Y

  // Difference with empty Y: ∅ - A = ∅. Must not panic.
  boolean({ Y }, { A }, op: "difference", fill: red, stroke: black)

  // Empty input as a (b non-empty): ∅ inter A = ∅. Must not panic.
  boolean({ Y }, { A }, op: "intersection", fill: blue, stroke: none)
})
