#set page(width: auto, height: auto)
#import "/src/lib.typ": *

/* Draw smoothed data by using spline interpolation */
#box(stroke: 2pt + red, canvas({
  plot.plot(size: (6, 4),
    {
      plot.add(((0,0), (1,1), (2,-1), (3,3)), line: (type: "spline", tension: .40,
                                                     samples: 5))
      plot.add(((0,0), (1,1), (2,-1), (3,3)), line: (type: "spline", tension: .47))
      plot.add(((0,0), (1,1), (2,-1), (3,3)), line: "spline")
      plot.add(((0,0), (1,1), (2,-1), (3,3)), line: (type: "spline", tension: .5))
    })
}))
