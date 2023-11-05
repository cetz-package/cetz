#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (6,3),
    x-tick-step: none,
    y-tick-step: none,
    x-equal: "y",
    a-equal: "b",
    b-horizontal: true,
  {
    plot.add(domain: (0, 2 * calc.pi), t => (calc.cos(t), calc.sin(t)))
    plot.add(domain: (0, 2 * calc.pi), t => (calc.cos(t), calc.sin(t)),
      axes: ("a", "b"))
  })
}))

#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (3,6),
    x-tick-step: none,
    y-tick-step: none,
    x-equal: "y",
    a-equal: "b",
    b-horizontal: true,
  {
    plot.add(domain: (0, 2 * calc.pi), t => (calc.cos(t), calc.sin(t)))
    plot.add(domain: (0, 2 * calc.pi), t => (calc.cos(t), calc.sin(t)),
      axes: ("a", "b"))
  })
}))
