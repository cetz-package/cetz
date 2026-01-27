#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

// No Position
#test-case({
  import draw: *
  set-style(mark: (fill: white))
  line((-1,0), (1,0), mark: (start: ">", end: ">"))
})

// Absolute Position
#test-case({
  import draw: *
  set-style(mark: (fill: white))
  line((-1,1), (1,1), mark: (start: ">", end: ">", pos: .25, shorten-to: none))
})

// Relative Offset
#test-case({
  import draw: *
  set-style(mark: (fill: white))
  line((-1,0), (1,0), mark: (start: ">", end: ">", pos: 25%, shorten-to: none))
  line((-1,1), (1,1), mark: (end: ">", pos: 50%, shorten-to: none))
  line((-1,2), (1,2), mark: (start: ">", pos: 50%, shorten-to: none))
  line((-1,3), (1,3), mark: (start: (">", (symbol: "|", pos: 50%, anchor: "center")), end: ">", shorten-to: 0))
})
