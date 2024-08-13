#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *

  anchor("test", (1, 1))
  circle((1,1))

  translate((3,1))
  circle("test", radius: .5, stroke: green)
  circle((1,1), radius: .5, stroke: red)
})
