#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#let shapes = (
  ..cetz.mark-shapes.marks.keys()
)

#test-case(shape => {
  import draw: *

  rect((0,0), (1,1), stroke: .1pt + green)

  line((0, 0), (1, 0), mark: (
    start: shape,
    end: shape,
  ))

  line((0, 1), (1, 1), mark: (
    start: (symbol: shape, reverse: true),
    end: (symbol: shape, reverse: true),
  ))
}, args: shapes)
