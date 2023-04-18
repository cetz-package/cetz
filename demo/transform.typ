#import "../canvas.typ": *

#set page(width: auto, height: auto)

#canvas(debug: true,  fill: gray, length: 2cm, {
  import "../draw.typ": *

  let hl(name) = (
      group({fill(red)
      circle(name, radius: .1)})
  )

  group(name: "full", {
    group({
      rotate((z: 40deg))
      fill(white)
      merge-path({
        circle((0,0), radius: 1, start: 20deg, name: "bubble")
        line("bubble.end", (1.5, 0), "bubble.start")
      }, cycle: true)
    })
        
    fill(none)
    content((0,0), [This is a merged path!])
  })

  hl("full.top")
  hl("bubble.bottom")
  hl("bubble.left")
  hl("bubble.right")
  hl("bubble.bottom-right")
  hl("bubble.bottom-left")

  rect((-2, -2), (2, 2))
})
