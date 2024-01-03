#set page(width: auto, height: auto)
#import "../../src/lib.typ": *

#let data = (
  [A], ([B], [C], [D]), ([E], [F])
)

#box(stroke: 2pt + red, canvas({
  import draw: *
  import tree: *

  set-style(
    mark: (fill: auto),
    content: (padding: .2),
    fill: gray.lighten(70%),
    stroke: gray.lighten(70%))

  tree(data, spread: 2.5, grow: 1.5, draw-node: (node, _) => {
    circle((), radius: .45, stroke: none)
    content((), node.content)
  }, draw-edge: (from, to, ..) => {
    line((a: from, number: .6, abs: true, b: to),
         (a: to, number: .6, abs: true, b: from), mark: (end: ">"))
  }, name: "tree")

  // Draw a "custom" connection between two nodes
  let (a, b) = ("tree.0-0-1", "tree.0-1-0",)
  line((a: a, number: .6, abs: true, b: b), (a: b, number: .6, abs: true, b: a), mark: (end: ">", start: ">"))
}))
