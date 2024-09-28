#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case(padding: 1, {
  import draw: *
  circle(())
})

#test-case(padding: (top: 1, left: 2), {
  import draw: *
  scale(x: -1, y: -.5)
  circle(())
})
