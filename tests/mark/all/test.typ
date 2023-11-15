#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#box(stroke: 2pt + red, canvas({
  import draw: *

  set-style(stroke: 4pt, mark: (fill: yellow))

  group({
    anchor("zero", (0,0))
    for (i, s) in mark-symbols.enumerate() {
      line((0,i), (5,i), mark: (start: s, end: s))
    }
    anchor("top", ())
  }, name: "g")

  on-layer(-1, {
    rect("g.zero", "g.top", stroke: green)
  })
}))
