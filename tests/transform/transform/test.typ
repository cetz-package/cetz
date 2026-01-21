#set page(width: auto, height: auto)

#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#let arrow = draw.polygon((0, 0), 3)

#test-case({
  import draw: *

  transform(none)
  arrow
})

#test-case({
  import draw: *

  transform(matrix.transform-rotate-z(45deg))
  transform(matrix.transform-scale((1, 0.5, 1)))
  arrow
})
