#import "@preview/cetz:0.2.2": canvas
#import "@preview/cetz-plot:0.1.0": plot

#set page(width: auto, height: auto, margin: .5cm)

#let style = (stroke: black, fill: rgb(0, 0, 200, 75))

#canvas(length: 1cm, {
  plot.plot(size: (8, 6),
    x-tick-step: none,
    x-ticks: ((-calc.pi, $-pi$), (0, $0$), (calc.pi, $pi$)),
    y-tick-step: 1,
    {
      plot.add(
        style: style,
        domain: (-calc.pi, calc.pi), calc.sin)
      plot.add(
        hypograph: true,
        style: style,
        domain: (-calc.pi, calc.pi), calc.cos)
      plot.add(
        hypograph: true,
        style: style,
        domain: (-calc.pi, calc.pi), x => calc.cos(x + calc.pi))
    })
})
