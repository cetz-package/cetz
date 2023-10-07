#set page(width: auto, height: auto)
#import "/src/lib.typ": *

/* Draw different line types */
#box(stroke: 2pt + red, canvas({
  import draw: *

  let data(i) = ((1, 2, 3, 4, 5).zip((1, 3, 2, 3, 1).map(v => v + i)))
  plot.plot(size: (6, 6),
    y-min: 0, y-max: 35,
    x-tick-step: 1,
    y-tick-step: 5,
    {
       plot.add(data(0), line: "linear", mark: "o")
       plot.add(data(5), line: "spline", mark: "o")
       plot.add(data(10), line: "hv", mark: "o")
       plot.add(data(15), line: "vh", mark: "o")
       plot.add(data(20), line: "vhv", mark: "o")
       plot.add(data(25), line: (type: "vhv", mid: .25), mark: "o")
       plot.add(data(30), line: (type: "vhv", mid: .75), mark: "o")
    })
}))

