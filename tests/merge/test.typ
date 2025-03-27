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
