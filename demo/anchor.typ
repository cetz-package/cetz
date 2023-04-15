#import "../canvas.typ": *

#canvas(fill: gray, length: 1cm, ctx => {
  import "../draw.typ": *
  stroke(black + .5pt)

  line((-1.5, 0), (1.5, 0))
  line((0, -1.5), (0, 1.5))

  node("C", {
    circle((0, 0, 0), radius: 1cm)
    rect((0, 0), (.5, .5))
  })

  node("A", {
    rect((-.5, -.5), (-1, -1))
  })
  stroke(red + .5pt)

  stroke(black + .5pt)
  move-to((0, 0))
  content((rel: (0, -1em)), [Hallo], position: "bellow")
  line((-.3,0), (1, 1), mark-end: "|", mark-begin: "|")
  line((-.3,1), (1, 2), mark-end: ">", mark-begin: ">")

  stroke(red + .5pt)
  line((node: "C", at: "center"), (rel: (1, 1)))
})
