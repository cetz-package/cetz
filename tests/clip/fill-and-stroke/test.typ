#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *

  circle((0, 0), radius: 1, stroke: 0.4pt + gray, fill: none)

  clip(
    { circle((0, 0), radius: 1) },
    {
      rect(
        (-1.3, -0.7),
        (1.3, 0.7),
        fill: rgb("#b7e4c7"),
        stroke: 2pt + rgb("#1b4332"),
      )
    },
    mode: "inside",
  )
})
