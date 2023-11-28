#import "@preview/cetz:0.2.0": canvas, draw, tree

#set page(width: auto, height: auto, margin: .5cm)

#let data = (
  [A], ([B], [C], [D]), ([E], [F])
)

#canvas(length: 1cm, {
  import draw: *

  set-style(content: (padding: .2),
    fill: blue,
    stroke: blue)

  tree.tree(data, spread: 2.5, grow: 1.4, draw-node: (node, _) => {
    circle((), radius: .45)
    content((), text(white, node.content))
  }, draw-edge: (from, to, _, _) => {
    line(from, to, mark: (end: ">"))
  }, name: "tree")
})

// You can use the tree API to draw lists of items
#canvas(length: 1cm, {
  import draw: *

  let data = ([1], ([2], ([3], ([4], ([5],)))))

  set-style(fill: none, stroke: blue)
  tree.tree(data, direction: "right", grow: 1.1, draw-node: (node, _) => {
    // Draw a block arrow shape
    let shape = ((-.8, .5), (.9, 0), (.5, -.5),
                 (-.5, -.5), (-.9, 0), (.5, .5))
    line(..shape.map(pt => (rel: pt)), close: true)
    content("center", text(blue, node.content))
  }, draw-edge: none)
})
