#set page(width: auto, height: auto)
#import "/src/lib.typ": *

/* X grid */
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (3, 3),
    x-grid: true,
    x-tick-step: .5,
    y-tick-step: .5,
  {
    plot.add(((0,0), (1,1)))
  })
}))

/* X grid */
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (3, 3),
    x-grid: "both",
    x-tick-step: .5,
    x-minor-tick-step: .25,
    y-tick-step: .5,
  {
    plot.add(((0,0), (1,1)))
  })
}))

/* Y grid */
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (3, 3),
    y-grid: true,
    x-tick-step: .5,
    y-tick-step: .5,
  {
    plot.add(((0,0), (1,1)))
  })
}))

/* Y grid */
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (3, 3),
    y-grid: "both",
    x-tick-step: .5,
    y-tick-step: .5,
    y-minor-tick-step: .25,
  {
    plot.add(((0,0), (1,1)))
  })
}))

/* X-Y grid */
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (3, 3),
    x-grid: "both",
    y-grid: "both",
    x-tick-step: .5,
    x-minor-tick-step: .25,
    y-tick-step: .5,
    y-minor-tick-step: .25,
  {
    plot.add(((0,0), (1,1)))
  })
}))
