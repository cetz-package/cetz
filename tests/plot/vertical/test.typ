#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (10, 10),
  {
    plot.add(domain: (0, 4*calc.pi), calc.sin, axes: ("y", "x"))
  })
}))

#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (10, 10),
  {
    plot.add-contour(x-domain: (0, 4), y-domain: (-2, 2),
      (x, y) => x - .5 * y, op: ">=", z: 2, axes: ("y", "x"), fill: true)
  })
}))

#box(stroke: 2pt + red, canvas({
  import draw: *

  let box1 = (
    outliers: (7, 65, 69),
    min: 15,
    q1: 25,
    q2: 35,
    q3: 50,
    max: 60)

  plot.plot(size: (10, 10),
  {
    plot.add-boxwhisker((x: 1, ..box1), axes: ("y", "x"))
  })
}))

#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (10, 10), y-label: $ x $,
                            x-label: $ y $,
                            x-min: -.75, x-max: .75,
  {
    plot.add(domain: (0, 4*calc.pi), calc.sin, axes: ("y", "x"))
  })
}))
