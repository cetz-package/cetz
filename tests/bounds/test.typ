#set page(width: auto, height: auto)
#import "../../src/lib.typ": *

#box(stroke: 2pt + red, canvas({
  import draw: *

  group(name: "g", {
    scale(.25)
    rotate(37deg)
    bezier((0,0), (0, 10), (1,-10), (-5,20))
  })
  on-layer(-1, {
    rect("g.south-west", "g.north-east", stroke: .5pt + green)
  })
}))

#box(stroke: 2pt + red, canvas({
  import draw: *

  group(name: "g", {
    arc((0,0), start: 45deg, stop: 360deg - 45deg)
  })
  on-layer(-1, {
    rect("g.south-west", "g.north-east", stroke: .5pt + green)
  })
}))

#box(stroke: 2pt + red, canvas({
  import draw: *

  let pts = ((-1.414213562373095, 0),
             (-1.4142135623730954, -1.414213562373095),
             (-1.8047378541243648, -0.3905242917512698),
             (-1.8047378541243653, -1.023689270621825))
  group(name: "g", {
    bezier(..pts)
  })

  on-layer(-1, {
    rect("g.south-west", "g.north-east", stroke: .5pt + green)
  })
}))
