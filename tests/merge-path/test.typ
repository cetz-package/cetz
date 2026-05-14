#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *

  // Merge lines
  fill(red)
  merge-path({
    line((0,0), (1,2))
    line((), (2,0))
    line((), (0,0))
  }, close: true)

  translate((0, -1))

  // Merge bezier paths
  fill(blue)
  merge-path({
    bezier((0,0), (2,0), (1, 1))
    bezier((2, -1), (0, -1), (.5, -2), (1.5, 0))
  }, close: true)

  translate((0, -2))

  // Merge different paths
  fill(green)
  merge-path({
    line((0,0), (1,0), (2,-1))
    arc((), start: 0deg, stop: -130deg, name: "arc")
    bezier("arc.arc-end", (0,0), (0, -1), (2, -2))
  })
})

#test-case({
  import draw: *

  rotate(45deg)
  merge-path({
    line((0,0), (1,0), (2,-1))
    arc((), start: 0deg, stop: -130deg, name: "arc")
    bezier("arc.arc-end", (0,0), (0, -1), (2, -2))
  }, name: "p", fill: yellow)

  for i in range(0, 110, step: 10) {
    circle((name: "p", anchor: 1% * i), radius: .1, fill: white)
  }
})

#test-case({
  import draw: *

  merge-path(close: true, fill: red, {
    line((0,0), (1,0), (1,1))
  })
})

// Place multiple marks along a merged path
#test-case({
  import draw: *

  merge-path({
    line((0,0), (1,0))
    arc((), start: 0deg, stop: 90deg)
  }, mark: (end: range(0, 110, step: 10).map(t => (symbol: "o", shorten-to: none, pos: t * 1%, fill: white))))
})

// Shorten merged paths
#test-case({
  import draw: *

  merge-path({
    line((0,0), (1,0))
    arc((), start: 0deg, stop: 90deg)
  }, mark: (
    end: ((symbol: "o", pos: 75%, fill: white), (symbol: "|", pos: 0%)),
    start: "|"
  ))
})

// Remove existing marks by default
#test-case({
  import draw: *

  merge-path({
    line((0,0), (1,0), mark: (end: ">"))
  })
})

// Keep marks if specified
#test-case({
  import draw: *

  merge-path(ignore-marks: false, {
    line((0,0), (1,0), mark: (end: ">"))
  })
})
