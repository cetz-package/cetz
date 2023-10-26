#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#let data = (
            outliers: (7, 65, 69),
            min: 15,
            q1: 25,
            q2: 35,
            q3: 50,
            max: 60
        )

#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (10, 10),
    y-min: 0,
    y-max: 100,
  {
    plot.add-boxwhisker((x: 1, ..data))
  })
}))

#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: (10, 10),
    y-min: 0,
    y-max: 100,
  {
    plot.add-boxwhisker((
      (x: 1, ..data),
      (x: 2, ..data),
      (x: 3, ..data),
      (x: 4, ..data),
    ))
  })
}))
