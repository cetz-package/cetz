#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *

  rect((-1, -1), (1, 1), stroke: 0.35pt + gray, fill: none)

  clip(
    { rect((-1, -1), (1, 1)) },
    {
      compound-path({
        circle((-0.45, 0), radius: 0.75)
        circle((-0.45, 0), radius: 0.3)
      }, fill: rgb("#ffccd5"), stroke: none, fill-rule: "even-odd")

      line((-1.5, 0.65), (1.5, 0.65), stroke: 2pt + rgb("#1d4ed8"))

      rect((-0.15, -1.25), (1.25, 0.15), fill: rgb("#c7f9cc"), stroke: 1.5pt + rgb("#2d6a4f"))
    },
    mode: "outside",
    eps: 1e-6,
  )
})
