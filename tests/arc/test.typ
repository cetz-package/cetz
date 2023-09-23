#set page(width: auto, height: auto)
#import "../../src/lib.typ": *

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *

  for r in ((1,1), (0.5,1), (1,0.5)) {
    translate((2.5, 0, 0))
    group({
      for a in range(0, 360 + 45, step: 45) {
        let a = a * 1deg
        circle((0,0), radius: r, stroke: red)
        arc((0,0), start: 45deg, delta: a, radius: r, name: "a",
            anchor: "origin", mode: "PIE", fill: blue)

        circle("a.start", fill: green, radius: .1)
        circle("a.end", fill: red, radius: .1)
        translate((0, 2.5, 0))
      }
    })
  }
}))


#box(stroke: 2pt + red, canvas(length: .5cm, {
  import draw: *

  arc((0, 0), start: 45deg, delta: 270deg, radius: (5, 2), name: "c",
      anchor: "origin")
  for-each-anchor("c", a => {
    if not a in ("below", "above", "default") {
      circle("c." + a, radius: .1, fill: green)
      content((rel: (0, .5), to: "c." + a), [#a], frame: "rect",
              fill: white, stroke: none)
    }
  })
}))
