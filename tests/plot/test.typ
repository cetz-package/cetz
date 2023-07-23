#set page(width: auto, height: auto)
#import "../../canvas.typ": *
#import "../../plot.typ"

#let data = (..(for x in range(-360, 360) {
  ((x, calc.sin(x * 1deg)),)
}))

/* Scientific Style */
#box(stroke: 2pt + red, canvas({
    import "../../draw.typ": *

    let (x, y) = (
      plot.axis(min: -360, max: 360, tics: (step: 180)),
      plot.axis(min: -1, max: 1)
    )

    plot.scientific-axes(size: (5, 4), left: y, bottom: x, data)
}))

/* 4-Axes */
#box(stroke: 2pt + red, canvas({
    import "../../draw.typ": *

    let (x, y, x2, y2) = (
      plot.axis(min: -360, max: 360, tics: (step: 180)),
      plot.axis(min: -1, max: 1),
      plot.axis(min: -90, max: 90, tics: (step: 45, minor-step: 15)),
      plot.axis(min: -1.5, max: 1.5, tics: (minor-step: .1, step: .5))
    )

    plot.scientific-axes(size: (5, 4), left: y, right: y2, bottom: x, top: x2,
      (data: data),
      (data: data, style: (stroke: blue), axes: (x2, y2)))
}))

/* School-Book Style */
#box(stroke: 2pt + red, canvas({
    import "../../draw.typ": *

    let (x, y) = (
      plot.axis(min: -360, max: 360, tics: (step: 180)),
      plot.axis(min: -1, max: 1)
    )

    plot.school-book-axes(x, y, size: (5, 4), data)
}))

/* Clipping */
#box(stroke: 2pt + red, canvas({
    import "../../draw.typ": *

    let (x, y) = (
      plot.axis(min: -360, max: 350, tics: (step: 180)),
      plot.axis(min: -.5, max: .5)
    )

    plot.school-book-axes(x, y, size: (5, 4), data)
}))

/* Epigraph */
#box(stroke: 2pt + red, canvas({
    import "../../draw.typ": *

    let (x, y) = (
      plot.axis(min: -360, max: 360, tics: (step: 180), label: $x$),
      plot.axis(min: -1.5, max: .5, label: $y$)
    )

    plot.school-book-axes(x, y, size: (5, 4),
      (data: data, epigraph: true, hypograph: true, fill: true,
       style: (epigraph: (fill: blue),
               hypograph: (fill: red),
               fill: green)))
}))

/* Sampled Plots */
#box(stroke: 2pt + red, canvas({
    import "../../draw.typ": *

    let (x, y) = (
      plot.axis(min: -3, max: 5, tics: (step: 1), label: $x$),
      plot.axis(min: -1, max: 5, label: $y$)
    )

    plot.scientific-axes(size: (5, 4), left: y, bottom: x,
      (data: x => calc.pow(x, 2), samples: 25, style: (stroke: blue)),
      (data: x => if x >= 0 {calc.sqrt(x)}, samples: 100, style: (stroke: green)),
      (data: x => calc.abs(x), style: (stroke: red)),
      )
}))
