#import "@local/cetz:0.0.1": canvas, plot

#set page(width: auto, height: auto, margin: .5cm)

#canvas(length: 1cm, {
  let (x, y) = (
    plot.axis(min: -calc.pi, max: calc.pi, tics: (step: none,
      minor-step: calc.pi/4,
      list: ((0, [0]), (-calc.pi, $-pi$), (calc.pi, $pi$)))),
    plot.axis(min: -1, max: 1)
  )
  plot.scientific-axes(left: y, bottom: x,
    (data: x => calc.sin(x * 1rad), style: (stroke: blue, hypograph: (fill: blue.lighten(50%))),
     hypograph: true),
    (data: x => calc.cos(x * 1rad), style: (stroke: red)),
    size: (8, 6))
})
