#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import cetz.draw: *
  for i in range(0, 90 + 1) {
    rotate(22deg)
    translate((0,1))
    rotate(-25deg)
    translate((0,-1))
    scale(y: -1)
  }

  // With rounding errors, the line and decoration
  // won't be at the same location.
  line((-1,0), (1,0), stroke: red)

  cetz.decorations.wave(line((-1,0), (1,0), stroke: green))
})
