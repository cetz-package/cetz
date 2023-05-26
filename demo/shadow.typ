#import "../canvas.typ": *

#set page(width: auto, height: auto)

#canvas(background: gray, length: 1cm, {
  import "../draw.typ": *
  stroke(black + .5pt)
  fill(white)

  shadow(color: black, {
    rect((0,0), (1,1))
    circle((2,.5), radius: .5)
    line((0,1.5), (2.5,1.5), mark-begin: ">", mark-end: ">")
  })
})
