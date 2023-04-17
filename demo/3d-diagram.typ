#import "../canvas.typ": *

#set page(width: auto, height: auto)

#canvas(fill: none, length: 1cm, {
  import "../draw.typ": *

  // Draw grid
  stroke((color: black, dash: "dashed", thickness: .5pt))
  for i in range(0, 6) {
    line((0, i, 0), (0, i, 1), (7, i, 1))
    content((-.1, i, 0), [$#{i*20}$], position: "left")
  }
  stroke((color: black, thickness: .5pt))
  line((0, 0, 1), (0, 5, 1))
  line((0, 5, 0), (0, 0, 0), (7, 0, 0))

  // Draw data
  let draw-box(x, height, title) = {
    x = x * 1.2
    let color = blue
    let (top, front, side) = (color.lighten(20%), color, color.lighten(10%))
    let h = height / 20

    fill(front)
    rect((x - .5, 0), (x + .5, h))
    fill(side)
    rect((x + .5, 0, 0), (x + .5, h, 1))
    fill(top)
    line((x - .5, h, 0), (x - .5, h, 1),
         (x + .5, h, 1), (x + .5, h, 0), cycle: true)
    content((x, -.1), title, position: "bellow", angle: -90deg)
  }

  // Draw data
  draw-box(1, 10)[very good]
  draw-box(2, 30)[good]
  draw-box(3, 40)[ok]
  draw-box(4, 30)[bad]
  draw-box(5, 0)[very bad]
})
