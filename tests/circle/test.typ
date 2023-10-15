#set page(width: auto, height: auto)
#import "../../src/lib.typ": *

#box(stroke: 2pt + red, canvas(length: .5cm, {
    import draw: *

    set-style(radius: (4, .5), stroke: none)
    for r in range(0, 6) {
      group({
        rotate(r * 30deg)
        translate((4.5, 4.5))
        
        circle((0,0), fill: (red, green, blue, yellow).at(calc.rem(r, 4)))
      })
    }

    set-style(radius: 0.45, stroke: black, fill: none)
    for x in range(0, 10) {
      for y in range(0, 10) {
        circle((x, y))
      }
    }
}))

#box(stroke: 2pt + red, canvas(length: .5cm, {
  import draw: *

  for z in range(-2, 2) {
    circle((0,0,z))
  }
}))

#box(stroke: 2pt + red, canvas(length: .5cm, {
  import draw: *

  circle((0, 0), radius: (5, 2), name: "c")
  for-each-anchor("c", a => {
    if not a in ("default",) {
      circle("c." + a, radius: .1, fill: green)
      content((rel: (0, .5), to: "c." + a), [#a], frame: "rect",
              fill: white, stroke: none)
    }
  })
}))
