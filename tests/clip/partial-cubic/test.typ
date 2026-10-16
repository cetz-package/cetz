#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *

  let reference = luma(70%)

  // Inside: the retained middle must stay a smooth cubic.
  rect((0, -0.6), (1, 0.6), stroke: 0.4pt + gray, fill: none)
  bezier((-1, 0), (2, 0), (0, 0.8), (1, -0.8), stroke: 0.6pt + reference)
  clip(
    { rect((0, -0.6), (1, 0.6)) },
    { bezier((-1, 0), (2, 0), (0, 0.8), (1, -0.8), stroke: 2pt + blue) },
    mode: "inside",
    eps: 1e-7,
  )

  // Outside: both remaining pieces must also stay cubic.
  rect((0, -2.6), (1, -1.4), stroke: 0.4pt + gray, fill: none)
  bezier((-1, -2), (2, -2), (0, -1.2), (1, -2.8), stroke: 0.6pt + reference)
  clip(
    { rect((0, -2.6), (1, -1.4)) },
    {
      bezier(
        (-1, -2),
        (2, -2),
        (0, -1.2),
        (1, -2.8),
        stroke: 2pt + rgb("#d97706"),
      )
    },
    mode: "outside",
    eps: 1e-7,
  )
})
