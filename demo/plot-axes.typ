#import "../canvas.typ": *

#set page(width: auto, height: auto)

#canvas(background: gray, length: 1cm, {
  import "../draw.typ": *
  stroke(black + .5pt)
  fill(black)

  line((0, 0), (5, 0), mark-end: ">")
  for i in range(0, 10) {
    line((-.05, -i / 2), (rel: (.1, 0)))
    content((-.1, -i / 2), [$#i$], anchor: "right")
  }

  line((0, 0), (0, -5), mark-end: ">")
  for i in range(0, 10) {
    line((i / 2, -.05), (rel: (0, .1)))
    content((i / 2, .1), [$#i "text"$], anchor: "above", angle: -90deg)
  }
})

