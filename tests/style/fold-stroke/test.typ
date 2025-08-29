#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *

  // Set color
  set-style(stroke: red)

  // Fold color + thickness to stroke
  line((0,0), (1,0), stroke: 5pt)
})
