#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#let show-group(body: ()) = {
  draw.group({
    body + draw.rect((-2,-2), (2,2))
  }, name: "g")
  draw.for-each-anchor("g", n => {
    draw.content("g."+n, n)
  })
}

#box(stroke: 2pt + red, canvas({
  import draw: *

  translate((1,1,1))
  show-group()
}))

#box(stroke: 2pt + red, canvas({
  import draw: *

  scale((x: 2, y: .5))
  show-group()
}))

#box(stroke: 2pt + red, canvas({
  import draw: *

  rotate(30deg)
  show-group()
}))

#box(stroke: 2pt + red, canvas({
  import draw: *

  show-group(body: translate((1,1,1)))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *

  show-group(body: scale((x: 2, y: .5)))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *

  show-group(body: rotate(30deg))
}))
