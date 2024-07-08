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

#for position in ("begin", "center", "end") {
  test-case({
    cetz.draw.set-style(content: (frame: "rect", padding: .1))
    cetz.tree.tree(data, parent-position: position)
  })
  h(.1cm)
}

#for direction in ("down", "up", "left", "right") {
  test-case({
    cetz.draw.set-style(content: (frame: "rect", padding: .1))
    cetz.tree.tree(data, direction: direction)
  })
  h(.1cm)
}

#test-case({
  // Specify branch lengths
  cetz.tree.tree(([], (1, ([], (1, []), (1, []))), (2, [])))
})
