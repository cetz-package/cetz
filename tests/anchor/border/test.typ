#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#let names = (
  "north",
  "north-east",
  "north-west",
  "east",
  "west",
  "south",
  "south-east",
  "south-west",
)

// Bug #1006
#test-case({
  import draw: *

  // Setup a shear matrix
  set-transform((
    (1, 0, -1/2, 0),
    (0, 1, -1/2, 0),
    (0, 0, 1,    0),
    (0, 0, 0,    1),
  ))

  rect((-1, -1), (1, 1), stroke: blue)
  rect((-1, -1, 1), (1, 1, 1), name: "rect")

  // Expecting the marks on the black rect
  for name in names {
    cross("rect." + name)
  }
})
