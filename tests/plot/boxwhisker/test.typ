#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#let box1 = (
  outliers: (7, 65, 69),
  min: 15,
  q1: 25,
  q2: 35,
  q3: 50,
  max: 60)

#let box2 = (
  min: -1,
  q1: 0,
  q2: 3,
  q3: 6,
  max: 8)

#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (10, 10),
    y-min: 0,
    y-max: 100,
  {
    plot.add-boxwhisker((x: 1, ..box1))
  })
}))

#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (10, 10),
    y-min: 0, y-max: 100,
  {
    plot.add-boxwhisker((
      (x: 1, ..box1),
      (x: 2, ..box1),
      (x: 3, ..box1),
      (x: 4, ..box1),
    ))
  })
}))

// Test auto-sizing of the plot
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (10, 10), {
    plot.add-boxwhisker((
      (x: 1, ..box1),
      (x: 2, ..box2),
    ))
  })
}))
