#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#box(stroke: 2pt + red, canvas({
    import draw: *

    let next(mark) = {
        line((), (rel: (1, 0)), mark: mark)
        move-to((rel: (-1, .25)))
    }

    set-style(fill: blue, mark: (fill: auto))
    rotate(90deg)

    for m in mark-symbols {
        next((end: m))
    }

    for m in mark-symbols {
        next((start: m))
    }

    fill(none)

    for m in mark-symbols {
        next((end: m))
    }

    for m in mark-symbols {
        next((start: m))
    }
}))

#box(stroke: 2pt + red, canvas({
  import draw: *

  line((0,0), (9,0), stroke: blue + 1pt)
  line((0,0), (9,0), stroke: green + .1pt)
  line((0,-1), (9,-1), stroke: blue + 1pt)
  line((0,-1), (9,-1), stroke: green + .1pt)

  set-style(mark: (stroke: (paint: green, miter-limit: 50),
                   fill: red))

  for x in range(0, 18) {
    line((x * .5, -1), (x * .5, 0), mark: (start: ">", end: ">",
      width: (x / 50 + .05)))
  }
}))

#box(stroke: 2pt + red, canvas({
  import draw: *

  line((0,0), (9,0), stroke: blue + 1pt)
  line((0,0), (9,0), stroke: green + .1pt)
  line((0,-1), (9,-1), stroke: blue + 1pt)
  line((0,-1), (9,-1), stroke: green + .1pt)

  set-style(mark: (stroke: (paint: green, miter-limit: 50),
                   fill: red))

  for x in range(0, 18) {
    line((x * .5, -1), (x * .5, 0), mark: (start: "<", end: "<",
      width: (x / 50 + .05)))
  }
}))

#box(stroke: 2pt + red, canvas({
  import draw: *

  line((0,0), (9,0), stroke: blue + 1pt)
  line((0,0), (9,0), stroke: green + .1pt)
  line((0,-1), (9,-1), stroke: blue + 1pt)
  line((0,-1), (9,-1), stroke: green + .1pt)

  set-style(mark: (stroke: (paint: green, miter-limit: 50, join: "round"),
                   fill: red))

  for x in range(0, 18) {
    line((x * .5, -1), (x * .5, 0), mark: (start: "<", end: ">",
      width: (x / 50 + .05)))
  }
}))

#box(stroke: 2pt + red, canvas({
  import draw: *

  line((0,0), (9,0), stroke: blue + 1pt)
  line((0,0), (9,0), stroke: green + .1pt)
  line((0,-1), (9,-1), stroke: blue + 1pt)
  line((0,-1), (9,-1), stroke: green + .1pt)

  set-style(mark: (stroke: (paint: green, miter-limit: 50, join: "bevel"),
                   fill: red))

  for x in range(0, 18) {
    line((x * .5, -1), (x * .5, 0), mark: (start: "<", end: ">",
      width: (x / 50 + .05)))
  }
}))
