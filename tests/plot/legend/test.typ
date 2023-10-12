#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#let dom = (domain: (0, 2 * calc.pi))
#let fn(x, offset: 0) = {calc.sin(x) + offset}

#for pos in ("north", "south", "west", "east",
             "north-east", "north-west",
             "south-east", "south-west",) {
  pos = "legend." + pos
  block(stroke: 2pt + red, canvas({
    import draw: *

    plot.plot(size: (2, 2),
      x-tick-step: none,
      y-tick-step: none,
      legend: pos,
      {
        plot.add(..dom, fn, label: $ f(x) $)
      })
  }))
}

#for pos in ("inner-north", "inner-south", "inner-west", "inner-east",
             "inner-north-east", "inner-north-west",
             "inner-south-east", "inner-south-west",) {
  pos = "legend." + pos
  block(stroke: 2pt + red, canvas({
    import draw: *

    plot.plot(size: (4, 2),
      x-tick-step: none,
      y-tick-step: none,
      legend: pos,
      {
        plot.add(..dom, fn, label: $ f(x) $)
      })
  }))
}

#block(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (4, 2),
    x-tick-step: none,
    y-tick-step: none,
    {
      plot.add(..dom, fn, label: $ f_1(x) $)
      plot.add(..dom, fn.with(offset: .1), label: $ f_2(x) $)
      plot.add(..dom, fn.with(offset: .2), label: $ f_3(x) $)
    })
}))

#block(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (4, 2),
    x-tick-step: none,
    y-tick-step: none,
    {
      plot.add(samples: 10, ..dom, fn, mark: "o", label: $ f(x) $)
      plot.add(samples: 10, ..dom, fn.with(offset: .1), mark: "x", fill: true, label: $ f_2(x) $)
      plot.add(samples: 10, ..dom, fn.with(offset: .2), mark: "|", style: (stroke: none), label: $ f_3(x) $)
    })
}))

#block(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (4, 2),
    x-tick-step: none,
    y-tick-step: none,
    {
      //plot.add-between(..dom, fn, fn.with(offset: .5), label: $ f(x) $)
    })
}))

#block(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (4, 2),
    x-tick-step: none,
    y-tick-step: none,
    {
      plot.add-hline(0, label: $ f(x) $)
      plot.add-vline(0, label: $ f(x) $)
    })
}))

#block(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (4, 2),
    x-tick-step: none,
    y-tick-step: none,
    {
      plot.add-contour(x-domain: (-1, 1), y-domain: (-1, 1),
        (x, y) => x, z: 0, op: "<=", label: $ f(x) $)
      plot.add-contour(x-domain: (-1, 1), y-domain: (-1, 1),
        (x, y) => x, z: 0, fill: true, label: $ f(x) $)
    })
}))

#block(stroke: 2pt + red, canvas({
  import draw: *

  let box1 = (
    x:  1,
    outliers: (7, 65, 69),
    min: 15,
    q1: 25,
    q2: 35,
    q3: 50,
    max: 60)

  plot.plot(size: (4, 2),
    x-tick-step: none,
    y-tick-step: none,
    {
      plot.add-boxwhisker(box1, label: [Box])
    })
}))
