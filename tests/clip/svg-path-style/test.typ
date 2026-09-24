#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *

  let svg = scope({
    rotate(x: 180deg)
    svg-path(
      stroke: 2pt + green,
      fill: blue,
      fill-rule: "even-odd",
      ("M", (0, 0)),
      ("L", (3, 0)),
      ("L", (3, 2)),
      ("L", (0, 2)),
      ("Z",),
      ("M", (1, 0.5)),
      ("L", (2, 0.5)),
      ("L", (2, 1.5)),
      ("L", (1, 1.5)),
      ("Z",),
    )
  })

  clip(
    { rect((-0.5, -1.5), (1.8, 0.5)) },
    svg,
    mode: "inside",
  )
})
