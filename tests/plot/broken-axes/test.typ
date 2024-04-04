#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#let data = ((5,5), (10,10))

#test-case({
  plot.plot(size: (8,8),
    x-break: true,
    y-break: true,
  {
    plot.add(data)
  })
})

#test-case({
  plot.plot(size: (8,8),
    axis-style: "school-book",
    x-break: true,
    y-break: true,
  {
    plot.add(data)
  })
})
