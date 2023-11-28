#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#let data = (
  [A], ([B], [C], [D], [E]), ([F], ([G], [H], [J]))
)

#box(stroke: 2pt + red, canvas({
  import draw: *
  import tree: *

  set-style(
    mark: (fill: auto),
    content: (padding: .1),
    stroke: black)

  tree(data)
}))

#box(stroke: 2pt + red, canvas({
  import draw: *
  import tree: *

  set-style(
    mark: (fill: auto),
    content: (padding: .1),
    stroke: black)

  tree(data, direction: "right")
}))
