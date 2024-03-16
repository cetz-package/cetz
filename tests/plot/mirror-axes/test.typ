#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  // Force showing tick labels for mirrored axes
  cetz.draw.set-style(axes: (tick: (label: ("show": true))))

  cetz.plot.plot(size: (8,8), {
    cetz.plot.add(domain: (0, 1), x => x)
  })
})
