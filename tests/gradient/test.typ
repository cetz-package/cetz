#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *

  fill(gradient.linear(red, blue))

  rect((2,2), (4,4))
  circle((0,0))
  line((0,2), (1,3), (0, 4), (-3, 3), close: true)
})

// Issue #1085
#test-case({
  import draw: *

  let ball = gradient.radial(white, blue, center: (25%, 25%))

  circle((0,0), fill: ball)
  rect((-2, -0.5), (rel: (1,1)), fill: ball)
})
