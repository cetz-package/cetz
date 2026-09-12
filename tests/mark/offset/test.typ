#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

// Bug #1099 - Offsetting "|" introduced a litte gap
#test-case({
  import cetz.draw: *

  line((0, 0), (1, 0), stroke: blue)
  line((0, 0), (1, 0), mark: (start: "|", end: "|", offset: 10%, stroke: black.transparentize(50%)))
})

#test-case({
  import cetz.draw: *

  line((0, 0), (1, 0), stroke: blue)
  line((0, 0), (1, 0), mark: (reverse: true, start: "|", end: "|", offset: 10%, stroke: black.transparentize(50%)))
})

#test-case({
  import cetz.draw: *

  line((0, 0), (1, 0), stroke: blue)
  line((0, 0), (1, 0), mark: (start: ">>", end: ">>", offset: 10%, stroke: black.transparentize(50%)))
})
