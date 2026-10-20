#import "@preview/cetz:0.5.2"

#set page(width: auto, height: auto, margin: .5cm)

#cetz.canvas({
  import cetz.draw: *
  import cetz.decorations: text-along

  set-style(stroke: gray + .8pt)

  bezier((0, 0), (6, 0), (1.5, 2), (4.5, -2), name: "wave")
  text-along(
    "wave",
    text(11pt, fill: eastern)[Text along a path · CeTZ],
    raise: .22,
    align: center,
  )

  translate((0, -2.2))
  circle((2.5, 0), radius: 1.1, name: "ring")
  text-along("ring", [AROUND], raise: .2, align: center, upright: auto)

  translate((3.5, 0))
  line((0, -.8), (0, .8), (1.6, .8), name: "corner")
  text-along("corner", [corners], raise: .25, corners: "pad")
})
