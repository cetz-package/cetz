#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *
  boolean(
    { rect((0, 0), (1, 1)) },
    { rect((0.5, 0.5), (1.5, 1.5)) },
    op: "xor",
    fill: purple,
    stroke: black,
  )
})
