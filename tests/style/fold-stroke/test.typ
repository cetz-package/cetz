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

// Fold multiple set-style calls
#test-case({
  import draw: *

  // Set color
  set-style(stroke: red)
  // Set thickness
  set-style(stroke: 5pt)

  line((0,0), (1,0))
})

// Reset a folded value between calls
#test-case({
  import draw: *

  // Set color
  set-style(stroke: red)
  // Reset
  set-style(stroke: none)
  // Set thickness (default color)
  set-style(stroke: 5pt)

  line((0,0), (1,0))
})

// Override a value
#test-case({
  import draw: *

  // Set color
  set-style(stroke: red + 10pt)
  set-style(stroke: 5pt + blue)

  line((0,0), (1,0))
})
