#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#let peaks(x, y) = (
  3 * calc.pow(1 - x, 2) * calc.exp(-(x*x) - calc.pow(y + 1, 2)) -
  10 * (x/5 - calc.pow(x, 3) - calc.pow(y, 5)) *
  calc.exp(-(x * x) - (y * y)) - 1/3 * calc.exp(-calc.pow(x + 1, 2) - (y * y))
)

/* Simple contour */
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (8, 8),
    x-tick-step: 5,
    y-tick-step: 5,
  {
    plot.add-contour(
      (x, y) => 2 - (x - 1) * (y - 1),
      fill: true,
      x-domain: (-10, 10),
      y-domain: (-10, 11),
    )

    plot.add-contour(
      (x, y) => 30 - (calc.pow(1 - x, 2) + calc.pow(1 - y, 2)),
      fill: true,
      x-domain: (-10, 10),
      y-domain: (-10, 10),
    )
  })
}))

/* Multi contour */
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (8, 8),
    x-tick-step: 1,
    y-tick-step: 1,
  {
    plot.add-contour(
      peaks,
      z: (0, 1, 2, 3, 4),
      fill: true,
      x-domain: (-2, 3),
      y-domain: (-2, 3),
      x-samples: 50,
      y-samples: 50,
    )
  })
}))

/* Multi contour */
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (8, 8),
    x-tick-step: 1,
    y-tick-step: 1,
  {
    let z(x, y) = {
      (1 - x/2 + calc.pow(x,5) + calc.pow(y,3)) * calc.exp(-(x*x) - (y*y))
    }
    plot.add-contour(
      z,
      z: (-.68, -.39, -.1, .1, .47, .76, 1.05),
      fill: true,
      x-domain: (-3, 3),
      y-domain: (-3, 3),
      x-samples: 50,
      y-samples: 50,
    )
  })
}))
