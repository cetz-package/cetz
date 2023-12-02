#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#box(stroke: 2pt + red, canvas({
  import draw: *

  let vp(from, to, bounds: (1,1,1)) = {
    group(name: "r", {
      rect(from, to)
      anchor("from", from)
      anchor("to", to)
    })
    group({
      set-viewport("r.from", "r.to", bounds: bounds)
      content((0,0), [A])
      content((1,0), [B])
      content((1,1), [C])
      content((0,1), [D])
    })
  }

  // Mark (0,0)
  line((-1,0),(1,0), stroke: blue)
  line((0,-1),(0,1), stroke: blue)

  group({
    translate(x: -1)
    rotate(45deg)
    rect((1,1), (4,4))
    set-viewport((1,1), (4,4))
    for i in range(0, 4) {
      for j in range(0, 4) {
        circle((i / 3, j / 3), radius: .1, fill: (red, green, blue).at(calc.rem(i+j, 3)))
      }
    }
  })

  group({
    translate((-2.5,-2.5))
    vp((2,2), (3,3))
  })

  vp((4,8), (1,5), bounds: (1,1,0)) // Mirrored edges
  vp((2,6), (3,7), bounds: (2,2,0)) // Non 1 bounds
}))
