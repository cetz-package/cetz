#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *

  circle((0,0), fill: red, stroke: none)
  on-layer(0, {
    circle((1, 0), fill: green, stroke: none)
  })
  on-layer(1, {
    circle((2, 0), fill: blue, stroke: none)
  })
})

#test-case({
  import draw: *

  on-layer(2, {
    circle((2, 0), fill: blue, stroke: none)
  })
  on-layer(1, {
    circle((1, 0), fill: green, stroke: none)
  })
  circle((0,0), fill: red, stroke: none)
})

// Test nested layers
#test-case({
  import draw: *

  on-layer(1, {
    circle((1, 0), fill: green, stroke: none, name: "c2")
    on-layer(0, {
      circle((0,0), fill: red, stroke: none)
    })
  })

  on-layer(1, {
    content("c2.center", [Green])
  })
  content((0,0), [Red])
})

#test-case({
  import draw: *
  on-layer(1, none)
  on-layer(1, ctx => none)
})
