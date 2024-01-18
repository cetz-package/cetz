#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *
  hobby((0,-1), (1,1), (2,0), (3,1), (4,0), (5,2), omega: 0)
})

#test-case({
  import draw: *
  hobby((0,-1), (1,1), (2,0), (3,1), (4,0), (5,2), omega: .5)
})

#test-case({
  import draw: *
  hobby((0,-1), (1,1), (2,0), (3,1), (4,0), (5,2), omega: 1)
})

#test-case({
  import draw: *
  hobby((0,-1), (1,1), (2,0), (3,1), (4,0), (5,2), close: true, fill: blue)
})

// Two points, not closed
#test-case({
  import draw: *
  hobby((0,0), (1,1))
})

// Two points, closed
#test-case({
  import draw: *
  hobby((0,0), (1,1), close: true)
})
