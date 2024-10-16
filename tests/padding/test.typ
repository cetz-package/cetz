#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case(padding: 1, background: gray, {
  import draw: *
  circle(())
})

#test-case(padding: (top: 1, left: 2), background: gray, {
  import draw: *
  scale(x: -1, y: -.5)
  circle(())
})
