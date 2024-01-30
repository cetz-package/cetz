#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#let line-data = ((-1,-1), (1,1),)

#let data = (..(for x in range(-360, 360 + 1) {
  ((x, calc.sin(x * 1deg)),)
}))

/* Scientific Style */
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (5, 2),
    x-tick-step: 180,
    y-tick-step: 1,
    x-grid: "major",
    y-grid: "major",
    {
      plot.add(data)
    })
}))

/* 4-Axes */
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (5, 3),
    x-tick-step: 180,
    x-min: -360,
    x-max:  360,
    y-tick-step: 1,
    x2-label: none,
    x2-min: -90,
    x2-max:  90,
    x2-tick-step: 45,
    x2-minor-tick-step: 15,
    y2-label: none,
    y2-min: -1.5,
    y2-max:  1.5,
    y2-tick-step: .5,
    y2-minor-tick-step: .1,
    {
      plot.add(data)
      plot.add(data, style: (stroke: blue), axes: ("x2", "y2"))
    })
}))

/* School-Book Style */
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (5, 4),
    axis-style: "school-book",
    x-tick-step: 180,
    y-tick-step: 1,
    {
      plot.add(data)
    })
}))

/* Clipping */
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (5, 4),
    axis-style: "school-book",
    x-min: auto,
    x-max: 350,
    x-tick-step: 180,
    y-min: -.5,
    y-max: .5,
    y-tick-step: 1,
    {
      plot.add(data)
    })
}))

/* Palettes */
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (5, 4),
    x-label: [Rainbow],
    x-tick-step: none,
    axis-style: "scientific",
    y-label: [Color],
    y-max: 8,
    y-tick-step: none,
    {
      for i in range(0, 7) {
        plot.add(domain: (i * 180, (i + 1) * 180),
          epigraph: true,
          style: plot.palette.rainbow,
          x => calc.sin(x * 1deg))
      }
    })
}))

/* Tick Step Calculation */
#box(stroke: 2pt + red, {canvas({
  import draw: *

  plot.plot(size: (12, 4),
    y2-decimals: 4,
    {
      plot.add(((0,0), (1,10)), axes: ("x", "y"))
      plot.add(((0,0), (.1,.01)), axes: ("x2", "y2"))
    })
}); canvas({
  import draw: *

  plot.plot(size: (12, 4),
    y2-decimals: 9,
    x2-decimals: 9,
    y2-format: "sci",
    {
      plot.add(((0,0), (30,2500)), axes: ("x", "y"))
      plot.add(((0,0), (.001,.0001)), axes: ("x2", "y2"))
    })
})})

/* Axis Styles */
#box(stroke: 2pt + red, stack(dir: ltr,
  ..("scientific", "left", "school-book").map(axis-style => {
    canvas({
      import draw: *
      plot.plot(size: (4,4), x-tick-step: 90, y-tick-step: 1,
                axis-style: axis-style, {
        plot.add(domain: (0, 360), x => calc.sin(x * 1deg))
      })
    })
  })
))

/* Manual Axis Bounds */
#let circle-data = range(0, 361).map(
  t => (.5 * calc.cos(t*1deg), .5 * calc.sin(t*1deg)))
#box(stroke: 2pt + red, stack(dir: ltr, canvas({
  import draw: *

  plot.plot(size: (4, 4),
    x-tick-step: 1,
    y-tick-step: 1,
    x-min: -1, x-max: 1,
    y-min: -1, y-max: 1,
    xl-min: -1.5, xl-max: .5,
    xr-min: -.5, xr-max: 1.5,
    yb-min: -1.5, yb-max: .5,
    yt-min: -.5, yt-max: 1.5,
    {
      plot.add(circle-data)
      plot.add(circle-data, axes: ("xl", "y"), style: (stroke: green))
      plot.add(circle-data, axes: ("xr", "y"), style: (stroke: red))
      plot.add(circle-data, axes: ("x", "yt"), style: (stroke: blue))
      plot.add(circle-data, axes: ("x", "yb"), style: (stroke: yellow))
    })
}), canvas({
  import draw: *

  plot.plot(size: (4, 4),
    x-tick-step: 1,
    y-tick-step: 1,
    x-min: -1, x-max: 1,
    y-min: -1, y-max: 1,
    xl-min: -1.75, xl-max: .25,
    xr-min: -.25, xr-max: 1.75,
    yb-min: -1.75, yb-max: .25,
    yt-min: -.25, yt-max: 1.75,
    {
      plot.add(circle-data)
      plot.add(circle-data, axes: ("xl", "y"), style: (stroke: green))
      plot.add(circle-data, axes: ("xr", "y"), style: (stroke: red))
      plot.add(circle-data, axes: ("x", "yt"), style: (stroke: blue))
      plot.add(circle-data, axes: ("x", "yb"), style: (stroke: yellow))
    })
}),))

/* Anchors */
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (5, 3), name: "plot",
    x-tick-step: 180,
    y-tick-step: 1,
    x-grid: "major",
    y-grid: "major",
    {
      plot.add(data, fill: true)
      plot.add-anchor("from", (-270, "max"))
      plot.add-anchor("to", (90, "max"))
      plot.add-anchor("lo", (90, 0))
      plot.add-anchor("hi", (90, "max"))
    })

  line((rel: (0, .2), to: "plot.from"),
       (rel: (0, .2), to: "plot.to"),
       mark: (start: "|", end: "|"), name: "annotation")
  content((rel: (0, .1), to: ("annotation.start", 50%, "annotation.end")), $2 pi$, anchor: "south")

  line((rel: (0,  .2), to: "plot.lo"),
       (rel: (0, -.2), to: "plot.hi"),
       mark: (start: ">", end: ">"), name: "amplitude")
}))

/* Custom sample points */
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (6, 4), y-min: -2, y-max: 2,
    samples: 10,
    {
      plot.add(samples: 2, sample-at: (.99, 1.001, 1.99, 2.001, 2.99), domain: (0, 3),
        x => calc.pow(-1, int(x)))
    })
}))

/* Format tick values */
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (6, 4),
    x-tick-step: none,
    x-ticks: (-1, 0, 1),
    x-format: x => $x_(#x)$,
    y-tick-step: none,
    y-ticks: (-1, 0, 1),
    y-format: x => $y_(#x)$,
    x2-tick-step: none,
    x2-ticks: (-1, 0, 1),
    x2-format: x => $x_(2,#x)$,
    y2-tick-step: none,
    y2-ticks: (-1, 0, 1),
    y2-format: x => $y_(2,#x)$,
    {
      plot.add(samples: 2, domain: (-1, 1), x => -x, axes: ("x", "y"))
      plot.add(samples: 2, domain: (-1, 1), x => x, axes: ("x2", "y2"))
    })
}))

// Test plot with anchors only
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (6, 4), name: "plot",
    x-min: -1, x-max: 1, y-min: -1, y-max: 1,
    {
      plot.add-anchor("test", (0,0))
    })
  circle("plot.test", radius: 1)
}))

// Test empty plot
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (1, 1), {})
}))

// Some axis styling
#box(stroke: 2pt + red, canvas({
  import draw: *

  set-style(axes: (
    padding: .1,
    tick: (
      length: -.1,
    ),
    left: (
      stroke: (paint: red),
      tick: (
        stroke: auto,
      )
    ),
    bottom: (
      stroke: (paint: blue, thickness: 2pt),
      tick: (
        stroke: auto,
      )
    ),
  ))

  plot.plot(size: (6, 4), axis-style: "scientific-auto", {
    plot.add(line-data)
  })

  set-origin((7, 0))

  set-style(axes: (
    overshoot: .5,
    x: (
      padding: 1,
      overshoot: -.5,
      stroke: blue,
    ),
    y: (
      stroke: red,
    )
  ))
  plot.plot(size: (6, 4), axis-style: "school-book",
    x-tick-step: none,
    y-tick-step: none,
  {
    plot.add(line-data)
  })
}))
