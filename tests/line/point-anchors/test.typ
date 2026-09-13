#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw:*

  line((0,0), (1,0), (rel: (90deg,1)), (2,1), name: "l")

  point("l.pt-0", "0")
  point("l.pt-1", "1")
  point("l.pt-2", "2")
  point("l.pt-3", "3")
})
