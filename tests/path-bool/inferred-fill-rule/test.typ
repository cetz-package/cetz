#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *


#test-case({
  import draw: *

  let A = circle((-1, 0), radius: 2)
  let B = circle((-1, 0), radius: 0.6)
  let C = circle((1, 0), radius: 2)
  let D = circle((1, 0), radius: 1.2)
  let H = rect((-2, 0), (2, 4))

  path-bool(
    {
      A
      circle((-1, 0), radius: 1.7)
      circle((-1, 0), radius: 0.9)
      B
    },
    rect((-2.3, -0.15), (2, 0.15), radius: 0.18),
    op: "union",
  )

  set-origin((0, -4.3))

  path-bool(
    compound-path(
      {
        A
        circle((-1, 0), radius: 1.7)
        circle((-1, 0), radius: 0.9)
        B
      },
      fill-rule: "even-odd",
    ),
    rect((-2.3, -0.15), (2, 0.15), radius: 0.18),
    op: "union",
  )
})
