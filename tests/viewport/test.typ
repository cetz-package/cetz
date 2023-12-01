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

  rotate(50deg)
  translate((-2.5,2.5), pre: false)

  vp((1,1), (4,4))
  vp((2,2), (3,3))

  rotate(-50deg)
  vp((4,8), (1,5), bounds: (1,1,0)) // Mirrored edges
  vp((2,6), (3,7), bounds: (2,2,0)) // Non 1 bounds
}))
