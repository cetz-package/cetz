#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *
  rect((0,0), (5,5))

  // Floating circle should not affect bounds
  floating(circle((6,6)))

  // Floating content
  floating(content((2.5, 6), [Floating content]))

  // Multiple floating elements
  floating({
    rect((-1,3), (0,2))
    rect((0,2), (1,1))
  })

  // Styles apply to floating elementss
  set-style(stroke: green)

  // Use floating anchor
  floating(circle((5,2), name: "floating-circle"))
  line("floating-circle", (0,0))
})

// The example used in `floating` docstring
#test-case({
  import draw: *

  group({
    circle((0,0))
    content((0,2), [Non-floating])
    floating(content((2,0), [Floating]))
  }, name: "bounds")

  set-style(stroke: red)
  rect("bounds.north-west", "bounds.south-east")
})