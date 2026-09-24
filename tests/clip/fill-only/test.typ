#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *

  circle((0, 0), radius: 1, stroke: 0.4pt + gray, fill: none)

  clip(
    { circle((0, 0), radius: 1) },
    { rect((-1.4, -0.35), (1.4, 0.35), fill: rgb("#8ecae6"), stroke: none) },
    mode: "inside",
  )
})
