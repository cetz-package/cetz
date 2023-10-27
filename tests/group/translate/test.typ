#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#let cross(pos: (0,0)) = {
  draw.line((rel: (-.2,0), to: pos),
            (rel: (.4,0)), stroke: blue + 2pt)
  draw.line((rel: (0,-.2), to: pos),
            (rel: (0,.4)), stroke: blue + 2pt)
}

/* Test the translation of grouped elements
   via the group anchor. */
#box(stroke: 2pt + red, canvas({
  import draw: *

  cross()
  set-style(content: (padding: 1))
  group({
    content((0,0), [Center])
  })
  group({
    content((0,0), [North])
  }, anchor: "north")
  group({
    content((0,0), [South])
  }, anchor: "south")
  group({
    content((0,0), [West])
  }, anchor: "west")
  group({
    content((0,0), [East])
  }, anchor: "east")
  group({
    content((0,0), [North-West])
  }, anchor: "north-west")
  group({
    content((0,0), [North-East])
  }, anchor: "north-east")
  group({
    content((0,0), [South-West])
  }, anchor: "south-west")
  group({
    content((0,0), [South-East])
  }, anchor: "south-east")
  group({
    anchor("custom", (0,-2))
    content((0,0), [Custom])
  }, anchor: "custom")
}))
