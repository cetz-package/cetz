#set page(width: auto, height: auto)
#import "../../canvas.typ": *
#import "../../lib/plot.typ"

#let data = (..(for x in range(-360, 360 + 1) {
  ((x, calc.sin(x * 1deg)),)
}))

/* Scientific Style */
#box(stroke: 2pt + red, canvas({
  import "../../draw.typ": *

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
  import "../../draw.typ": *

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
  import "../../draw.typ": *

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
  import "../../draw.typ": *

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

/* Epigraph */
#box(stroke: 2pt + red, canvas({
  import "../../draw.typ": *

  plot.plot(size: (5, 4),
    axis-style: "school-book",
    x-tick-step: 180,
    x-unit: $degree$,
    y-tick-step: 1,
    {
      plot.add(domain: (-360, 360), epigraph: true,
        x => calc.sin(x * 1deg), style: (fill: blue))
      plot.add(domain: (-360, 360), hypograph: true,
        x => calc.cos(x * 1deg), style: (fill: red))
      plot.add(domain: (-180, 180), fill: true,
        x => calc.sin(x * 1deg), style: (fill: green))
    })
}))

/* Marks */
#box(stroke: 2pt + red, canvas({
  import "../../draw.typ": *
  
  plot.plot(size: (5, 4),
    axis-style: "scientific",
    y-max: 2,
    y-min: -2,
    x-tick-step: 360,
    y-tick-step: 1,
    {
      for (i, m) in ("o", "square", "x", "triangle", "|", "-").enumerate() {
        plot.add(domain: (i * 180, (i + 1) * 180),
          samples: 12,
          style: (stroke: none),
          mark: m,
          mark-style: plot.palette.red,
          mark-size: .3,
          x => calc.sin(x * 1deg))
      }
    })
}))

/* Palettes */
#box(stroke: 2pt + red, canvas({
  import "../../draw.typ": *

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
  import "../../draw.typ": *

  plot.plot(size: (12, 4),
    y2-decimals: 4,
    {
      plot.add(((0,0), (1,10)), axes: ("x", "y"))
      plot.add(((0,0), (.1,.01)), axes: ("x2", "y2"))
    })
}); canvas({
  import "../../draw.typ": *

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
      import "../../draw.typ": *
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
  import "../../draw.typ": *

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
  import "../../draw.typ": *

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
