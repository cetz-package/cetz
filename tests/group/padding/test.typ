#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#let show-group(padding: none) = {
  draw.group(padding: padding, {
    draw.rect((0,0), (1,1), fill: blue)
  }, name: "g")
  draw.rect("g.south-west", "g.north-east")
}

#box(stroke: 2pt + red, canvas({
  import draw: *
  show-group()
}))

#box(stroke: 2pt + red, canvas({
  import draw: *
  show-group(padding: 1)
}))

#box(stroke: 2pt + red, canvas({
  import draw: *
  show-group(padding: (0, 1))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *
  show-group(padding: (1, 0))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *
  show-group(padding: (top: 1))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *
  show-group(padding: (bottom: 1))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *
  show-group(padding: (left: 1))
}))

#box(stroke: 2pt + red, canvas({
  import draw: *
  show-group(padding: (right: 1))
}))
