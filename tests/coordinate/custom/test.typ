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
