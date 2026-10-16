#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *

  rect((0, 0), (1, 1), stroke: 0.4pt + gray, fill: none)

  clip(
    { rect((0, 0), (1, 1)) },
    { line((0, 0), (1, 0), stroke: 2pt + blue) },
    mode: "inside",
  )

  set-origin((0, -1.4))
  rect((0, 0), (1, 1), stroke: 0.4pt + gray, fill: none)

  clip(
    { rect((0, 0), (1, 1)) },
    { line((0, 0), (1, 0), stroke: 2pt + red) },
    mode: "outside",
  )
})
