#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *
  set-style(fill: gray, stroke: gray)

  intersections("i", {
    content((0,0), [Text])
    on-layer(-1, {
      line((1,1), (-1,-1))
      bezier((-1,0), (1,0), (-.5,.5), (.5,-.5), fill: none)
    })
  })
  on-layer(-1, {
    for-each-anchor("i", n => {
      circle("i." + n, radius: .05)
    })
  })
})
