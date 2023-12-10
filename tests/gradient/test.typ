#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *

  fill(gradient.linear(red, blue))

  rect((2,2), (4,4))
  circle((0,0))
  line((0,2), (1,3), (0, 4), (-3, 3), close: true)
})
