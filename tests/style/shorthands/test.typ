#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

// Test fill() and stroke() shortcuts
#test-case({
  import draw: *

  set-style(fill: yellow, stroke: black)
  rect((-1, -1), (1, 1))

  fill(none)
  circle((0, 0))

  stroke(blue + 2pt)
  line((-1, -1), (1, 1))
})
