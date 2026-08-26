#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *

  rect((0, -0.5), (1, 0.5), stroke: 0.4pt + gray, fill: none)
  line((-1, 0), (2, 0), stroke: 0.5pt + red)

  clip(
    { rect((0, -0.5), (1, 0.5)) },
    { line((-1, 0), (2, 0), stroke: 2pt + blue) },
    mode: "inside",
  )
})
