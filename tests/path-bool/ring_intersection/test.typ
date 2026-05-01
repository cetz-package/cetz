#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *


#test-case({
  import draw: *

  grid(
    (-4, -3),
    (4, 3),
    step: 1,
    stroke: 0.2pt + gray,
  )

  let A = circle((-1, 0), radius: 2)
  let B = circle((-1, 0), radius: 1.2)
  let C = circle((1, 0), radius: 2)
  let D = circle((1, 0), radius: 1.2)
  let H = rect((-2, 0), (2, 4))

  let X = path-bool(
    A,
    B,
    op: "difference",
  )

  let Y = path-bool(
    C,
    D,
    op: "difference",
  )

  let O = path-bool(
    X,
    Y,
    op: "intersection",
  )

  path-bool(
    X,
    C,
    op: "difference",
    fill: rgb("#A8DADC"),
    stroke: none,
  )

  path-bool(
    X,
    D,
    op: "intersection",
    fill: rgb("#B8E0D2"),
    stroke: none,
  )

  path-bool(
    Y,
    B,
    op: "intersection",
    fill: rgb("#d8dee2"),
    stroke: none,
  )

  path-bool(
    Y,
    A,
    op: "difference",
    fill: rgb("#F4D6CC"),
    stroke: none,
  )

  path-bool(
    O,
    H,
    op: "intersection",
    fill: rgb("#E8C2CA"),
    stroke: (paint: gray, dash: "dashed"),
  )

  path-bool(
    O,
    H,
    op: "difference",
    fill: rgb("#d3c9d9"),
    stroke: (paint: gray, dash: "dashed"),
  )
})
