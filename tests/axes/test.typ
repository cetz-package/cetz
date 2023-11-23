#set page(width: auto, height: auto)
#import "../../src/lib.typ": *

// Schoolbook Axis Styling
#box(stroke: 2pt + red, canvas({
  import draw: *

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
  import draw: *

  set-style(axes: (stroke: blue))
  set-style(axes: (left: (tick: (stroke: green + 2pt))))
  set-style(axes: (bottom: (tick: (stroke: red, length: .5,
                                   label: (angle: 90deg,
                                           anchor: "east")))))
  set-style(axes: (right: (tick: (label: (offset: .2,
                                          angle: -45deg,
                                          anchor: "north-west"), length: -.1))))
  axes.scientific(size: (6, 6),
    frame: "set",
    top: none,
    bottom: axes.axis(min: -1, max: 1, ticks: (step: 1, minor-step: auto,
      grid: "both", unit: [ units])),
    left: axes.axis(min: -1, max: 1, ticks: (step: .5, minor-step: auto,
      grid: false)),
    right: axes.axis(min: -10, max: 10, ticks: (step: auto, minor-step: auto,
      grid: "major")),)
}))

// Custom Tick Format
#box(stroke: 2pt + red, canvas({
  import draw: *

  axes.scientific(size: (6, 1),
    bottom: axes.axis(min: -2*calc.pi, max: 2*calc.pi, ticks: (
      step: calc.pi, minor-step: auto, format: v => {
        let d = v / calc.pi
        if d == 0 {return $0$}
        {$#{d}pi$}
      }
    )),
    left: axes.axis(min: -1, max: 1, ticks: (step: none, minor-step: none)))
}))
