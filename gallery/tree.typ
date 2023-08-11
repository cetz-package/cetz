#import "@preview/cetz:0.0.2": canvas, draw, tree

#set page(width: auto, height: auto, margin: .5cm)

#let data = (
  [A], ([B], [C], [D]), ([E], [F])
)

#canvas(length: 1cm, {
  import draw: *

  set-style(content: (padding: .2),
    fill: gray.lighten(70%),
    stroke: gray.lighten(70%))

  tree.tree(data, spread: 2.5, grow: 1.5, draw-node: (node, _) => {
    circle((), radius: .45, stroke: none)
    content((), node.content)
  }, draw-edge: (from, to, _) => {
    line((a: from, number: .6, abs: true, b: to),
         (a: to, number: .6, abs: true, b: from), mark: (end: ">"))
  }, name: "tree")

  // Draw a "custom" connection between two nodes
  let (a, b) = ("tree.0-0-1", "tree.0-1-0",)
  line((a: a, number: .6, abs: true, b: b), (a: b, number: .6, abs: true, b: a), mark: (end: ">", start: ">"))
})
