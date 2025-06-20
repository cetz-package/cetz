#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#let data = (
  [A], ([B], [C], [D]), ([E], [F])
)

#test-case({
  import draw: *
  import tree: *

  set-style(
    mark: (fill: auto),
    content: (padding: .2),
    fill: gray.lighten(70%),
    stroke: gray.lighten(70%))

  tree(data, spread: 2.5, grow: 2, draw-node: (node, ..) => {
    content((), node.content, frame: "circle")
  }, draw-edge: (from, to, ..) => {
    line(from, to, mark: (start: "stealth", end: "stealth"))
  }, name: "tree")

  // Draw a "custom" connection between two nodes
  let (a, b) = ("tree.0-0-1", "tree.0-1-0",)
  line((a, .6, b), (b, .6, a), mark: (end: ">", start: ">"))
})

#for direction in ("down", "up", "left", "right") {
  test-case({
    cetz.draw.set-style(content: (frame: "rect", padding: .1))
    cetz.tree.tree(data, direction: direction)
  })
  h(.1cm)
}

#test-case(edge-layer => {
  import cetz.draw: *
  cetz.tree.tree(data, edge-layer: edge-layer, draw-node: (node, ..) => {
    circle((), radius: .3, fill: white)
    content((), node.content)
  }, draw-edge: (from, to, ..) => {
    line((anchor: "center", name: from),
         (anchor: "center", name: to), stroke: red + 2pt)
  })
}, args: (0, 1))

#test-case({
  import cetz.draw: *
  cetz.tree.tree(data, draw-node: (node) => {
    if node.depth == 2 and node.n == 1 {
      node.content = [This is an extra wide node.]
    }
    content((), node.content, frame: "rect", padding: 0.1)
  })
})
