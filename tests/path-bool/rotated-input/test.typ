#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *

  scope({
    rotate(30deg, origin: (0.5, 0.5))
    rect((0, 0), (1, 1))
  })

  scope({
    rotate(-15deg, origin: (1, 1))
    rect((0.5, 0.5), (1.5, 1.5))
  })


  path-bool(
    {
      rotate(30deg, origin: (0.5, 0.5))
      rect((0, 0), (1, 1))
    },
    {
      rotate(-15deg, origin: (1, 1))
      rect((0.5, 0.5), (1.5, 1.5))
    },
    op: "intersection",
    fill: olive,
    stroke: black,
  )
})
