#import "@preview/cetz:0.4.1": canvas, draw, tree

#set page(width: auto, height: auto, margin: .5cm)

#canvas({
  import draw: *
  let encircle(i) = {
    std.box(baseline: 2pt, std.circle(stroke: .5pt, radius: .5em)[#move(dx: -0.36em, dy: -1.1em, $#i$)])
  }

  set-style(content: (padding: 0.5em))
  tree.tree(
    ([Expression #encircle($5$)], (
        [Expression #encircle($3$)],
        ([Expression #encircle($1$)], `Int(1)`),
        `Plus`,
        ([Expression #encircle($2$)], `Int(2)`),
      ),
      `Lt`,
      ([Expression #encircle($4$)], `Int(4)`),
    ))
})
