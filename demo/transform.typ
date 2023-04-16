#import "../canvas.typ": *

#canvas(fill: gray, length: 2cm, ctx => {
  import "../draw.typ": *

  rect((-1, -1), (1, 1))

  node("A", {
    rotate((z: 40deg, x: 30deg))
    fill(white)
    stroke((color: black, thickness: 3pt, dash: "dotted"))
    merge-path({
      node("bubble", circle((0,0), radius: 1, start: 20deg))
      line((node: "bubble", at: "end"), (1.5,0), (node: "bubble", at: "start"))
    }, cycle: true)

    fill(none)
    content((0,0), [This is a merged path!])
  })

  rect((-2, -2), (2, 2))
})
