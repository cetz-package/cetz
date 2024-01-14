#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

// No Offset
#test-case({
  import draw: *
  set-style(mark: (fill: white))
  line((-1,0), (1,0), mark: (start: ">", end: ">"))
})

// Absolute Offset
#test-case({
  import draw: *
  set-style(mark: (fill: white))
  line((-1,1), (1,1), mark: (start: ">", end: ">", offset: .25, shorten-to: none))
})


// Relative Offset
#test-case({
  import draw: *
  set-style(mark: (fill: white))
  line((-1,0), (1,0), mark: (start: ">", end: ">", offset: 25%, shorten-to: none))
  line((-1,1), (1,1), mark: (end: ">", offset: 50%, shorten-to: none))
  line((-1,2), (1,2), mark: (start: ">", offset: 50%, shorten-to: none))
})
