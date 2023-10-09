#set page(width: auto, height: auto)
#import "/src/lib.typ": *

/* Simple plot */
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (4, 4),
    x-tick-step: 1,
    y-tick-step: 1,
  {
    plot.add((t) => (calc.cos(t * 1rad), calc.sin(t * 1rad)),
             domain: (0, 2 * calc.pi))
  })
}))

/* Test clipping */
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (4, 4),
    x-min: -1, x-max: 1,
    y-min: -1, y-max: 1,
    x-tick-step: 1,
    y-tick-step: 1,
  {
    plot.add((t) => (calc.cos(t * 1rad) + .5, calc.sin(t * 1rad)),
             domain: (0, 2 * calc.pi))
    plot.add((t) => (calc.cos(t * 1rad) - .5, calc.sin(t * 1rad)),
             domain: (0, 2 * calc.pi))
    plot.add((t) => (calc.cos(t * 1rad), calc.sin(t * 1rad) + .5),
             domain: (0, 2 * calc.pi))
    plot.add((t) => (calc.cos(t * 1rad), calc.sin(t * 1rad) - .5),
             domain: (0, 2 * calc.pi))
  })
}))

/* Test filling */
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (4, 4),
    x-tick-step: 1,
    y-tick-step: 1,
  {
    plot.add((t) => (calc.cos(t * 1rad), calc.sin(t * 1rad)),
             domain: (0, 2 * calc.pi),
             fill: true)
  })
}))

/* Test clipping + filling */
/*
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (4, 4),
    x-min: -1, x-max: 1,
    y-min: -1, y-max: 1,
    x-tick-step: 1,
    y-tick-step: 1,
  {
    plot.add((t) => (calc.cos(t * 1rad) + .5, calc.sin(t * 1rad)),
             domain: (0, 2 * calc.pi), fill: true)
    plot.add((t) => (calc.cos(t * 1rad) - .5, calc.sin(t * 1rad)),
             domain: (0, 2 * calc.pi), fill: true)
    plot.add((t) => (calc.cos(t * 1rad), calc.sin(t * 1rad) + .5),
             domain: (0, 2 * calc.pi), fill: true)
    plot.add((t) => (calc.cos(t * 1rad), calc.sin(t * 1rad) - .5),
             domain: (0, 2 * calc.pi), fill: true)
  })
}))
*/


/* oo */
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (10, 5),
    x-grid: "major",
    y-grid: "major",
    {
      plot.add(line: (type: "spline", samples: 3), domain: (0, 2 * calc.pi), t =>
        (calc.cos(t) / (calc.pow(calc.sin(t), 2) + 1),
         calc.cos(t) * calc.sin(t) / (calc.pow(calc.sin(t), 2) + 1)))
    })
}))
