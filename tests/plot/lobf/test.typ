#set page(width: auto, height: auto)
#import "/src/lib.typ": *

/* Simple plot */
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (4, 4),
    x-tick-step: 1,
    y-tick-step: 1,
  {
    plot.add-lobf(
        (
            (0, 1),
            (1, 2),
        ),
        domain: (0, 2 * calc.pi),
    )
  })
}))