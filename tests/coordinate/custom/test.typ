#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *
  grid((-2,-1), (7,1), stroke: gray)

  let log-resolver(ctx, coordinate) = {
    if type(coordinate) == dictionary and "log" in coordinate {
      coordinate = coordinate.log
      coordinate = coordinate.map(n => calc.log(calc.max(n, util.float-epsilon), base: 10))
    }

    return coordinate
  }

  register-coordinate-resolver(log-resolver)

  set-style(circle: (radius: .1))
  for i in (.1, 1, 10, 100, 1000, 10000) {
    let pt = (log: (i * 1, 1))
    circle(pt)
    content(pt, repr(i), anchor: "north", padding: (top: .5))
  }
})

#test-case({
  import draw: *
  register-coordinate-resolver((cxt, c) => {
    if type(c) == array {
      let (r, theta, ..) = c
      return (r * calc.cos(theta), r * calc.sin(theta))
    }
    return c
  })

  circle((1, calc.pi / 2), radius: 0.1)
  circle((1, 0), radius: 0.1)
  line((1, calc.pi / 2), (1, 0), mark: (start: ">", end: ">", fill: white))
})
