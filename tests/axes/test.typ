#set page(width: auto, height: auto)
#import "../../lib.typ": *

// Schoolbook Axis Styling
#box(stroke: 2pt + red, canvas({
  import "../../draw.typ": *

  set-style(axes: (stroke: blue))
  set-style(axes: (padding: .75))
  set-style(axes: (x: (stroke: red)))
  set-style(axes: (y: (stroke: green, tick: (stroke: blue, length: .3))))
  axes.school-book(size: (6, 6),
    axes.axis(min: -1, max: 1, ticks: (step: 1, minor-step: auto,
      grid: "both")),
    axes.axis(min: -1, max: 1, ticks: (step: .5, minor-step: auto,
      grid: "major")))
}))

// Scientific Axis Styling
#box(stroke: 2pt + red, canvas({
  import "../../draw.typ": *

  set-style(axes: (stroke: blue))
  set-style(axes: (left: (tick: (stroke: green + 2pt))))
  set-style(axes: (bottom: (tick: (stroke: red, length: .5))))
  set-style(axes: (right: (tick: (label: (offset: 0)))))
  axes.scientific(size: (6, 6),
    frame: "set",
    top: none,
    bottom: axes.axis(min: -1, max: 1, ticks: (step: 1, minor-step: auto,
      grid: "both")),
    left: axes.axis(min: -1, max: 1, ticks: (step: .5, minor-step: auto,
      grid: false)),
    right: axes.axis(min: -10, max: 10, ticks: (step: auto, minor-step: auto,
      grid: "major")),)
}))
