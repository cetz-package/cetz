#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#let l = ("straight", "straight", "straight")

#box(stroke: 2pt + red, canvas({
  import draw: *
  rect((1,-2), (2,2))
  rect((-2,-2), (-1,2))
  line((-1,-.5), (1,1),
    mark: (start: l, end: l, fill: red, stroke: blue))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *
  rect((1,-2), (2,2))
  rect((-2,-2), (-1,2))
  bezier((-1,-.5), (1,1), (0,-.5), (0,1),
    mark: (start: l, end: l, fill: red, stroke: blue, flex: false))
  bezier((-1,-1.5), (1,0), (0,-1.5), (0,0),
    mark: (start: l, end: l, fill: red, stroke: blue, flex: false, scale: .5))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *
  rect((1,-2), (2,2))
  rect((-2,-2), (-1,2))
  bezier((-1,-.5), (1,1), (0,-.5), (0,1),
    mark: (start: l, end: l, fill: red, stroke: blue, flex: true))
  bezier((-1,-1.5), (1,0), (0,-1.5), (0,0),
    mark: (start: l, end: l, fill: red, stroke: blue, flex: true, scale: .5))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *
  rect((1,-2), (2,2))
  rect((-2,-2), (-1,2))
  catmull((-1,-.5), (0,-.5), (0,1), (1,1),
    mark: (start: l, end: l, fill: red, stroke: blue, flex: true))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *
  rect((1,-2), (2,2))
  rect((-2,-2), (-1,2))
  hobby((-1,-.5), (0,-.5), (0,1), (1,1),
    mark: (start: l, end: l, fill: red, stroke: blue, flex: true))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *
  line((-.5,1), (2.5,1))
  arc((1,1), start: 0deg, stop: 180deg, anchor: "origin",
    mark: (start: l, end: l, fill: red, stroke: blue))
  arc((1,1), start: 180deg, stop: 360deg, anchor: "origin",
    mark: (start: l, end: l, fill: red, stroke: blue))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *
  line((-1,0), (0,1), (1,0),
    mark: (start: l, end: l, fill: red, stroke: blue, shorten-to: 1))
  bezier-through((-1,0), (0,-1), (1,0),
    mark: (start: l, end: l, fill: red, stroke: blue, shorten-to: 1))
  arc-through((-1,-1), (0,-2), (1,-1),
    mark: (start: l, end: l, fill: red, stroke: blue, shorten-to: 1))
}))

// Test sep
#box(stroke: 2pt + red, canvas({
  import draw: *
  set-style(mark: (fill: white, shorten-to: 0))
  line((-1,2), (1,2), mark: (end: ("o", "o", "o"), sep: 0.0))
  line((-1,1), (1,1), mark: (end: ("o", "o", "o"), sep: 0.5))
  line((-1,0), (1,0), mark: (end: ("o", "o", "o"), sep: 1.0))
}))

// Test offset
#box(stroke: 2pt + red, canvas({
  import draw: *
  set-style(mark: (fill: white, shorten-to: none))
  line((-1,2), (1,2), mark: (end: ((symbol: "o", offset: 0.0), "o", "o")))
  line((-1,1), (1,1), mark: (end: ((symbol: "o", offset: 0.5), "o", "o")))
  line((-1,0), (1,0), mark: (end: ((symbol: "o", offset: 1.0), "o", "o")))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *

  set-style(mark: (fill: white, shorten-to: auto))
  hobby((0,0), ..range(1, 20).map(t => {
    (calc.cos(t * calc.pi/2) * t / 10, calc.sin(t * calc.pi/2) * t / 10)
  }), mark: (end: ("straight", "stealth",) * 25))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *

  set-style(mark: (fill: white, shorten-to: auto))
  catmull((0,0), ..range(1, 20).map(t => {
    (calc.cos(t * calc.pi/2) * t / 10, calc.sin(t * calc.pi/2) * t / 10)
  }), mark: (end: ("straight", "stealth") * 25))
}))
