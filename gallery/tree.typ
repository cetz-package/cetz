#import "@preview/cetz:0.4.0": canvas, draw, tree

#set page(width: auto, height: auto, margin: .5cm)

#let data = (
  [A], ([B], [C], [D]), ([E], [F])
)

#canvas({
  import draw: *

  set-style(content: (padding: .2),
    fill: gray.lighten(70%),
    stroke: gray.lighten(70%))

  tree.tree(data, spread: 2.5, grow: 1.5, draw-node: (node, ..) => {
    circle((), radius: .45, stroke: none)
    content((), node.content)
  }, draw-edge: (from, to, ..) => {
    line((a: from, number: .6, b: to),
         (a: to, number: .6, b: from), mark: (end: ">"))
  }, name: "tree")

  // Draw a "custom" connection between two nodes
  let (a, b) = ("tree.0-0-1", "tree.0-1-0",)
  line((a, .6, b), (b, .6, a), mark: (end: ">", start: ">"))
})
