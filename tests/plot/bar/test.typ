#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#let data = (
  (0, (1, 2, 3)),
  (1, (6, 7, 8), (2, 1, 0)),
  (2, 5, ()),
)

#test-case({
  import draw: *
  plot.plot(size: (3, 3), x-tick-step: 1, y-tick-step: 1,
  {
    plot.add-bar(data,
      x-key: 0,
      y-key: 1,
      error-key: 2)
  })
})
