#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *

  compound-path({
    circle((0, 0), radius: 1.2)
    circle((0, 0), radius: 0.55)
  }, fill-rule: "even-odd", stroke: 0.4pt + gray, fill: none)

  clip(
    {
      compound-path({
        circle((0, 0), radius: 1.2)
        circle((0, 0), radius: 0.55)
      }, fill-rule: "even-odd")
    },
    { line((-1.6, 0), (1.6, 0), stroke: 2pt + purple) },
    mode: "inside",
  )
})
