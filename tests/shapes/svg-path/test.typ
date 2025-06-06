#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#import draw: svg-path, set-style, content

#test-case({
  svg-path(
    ("L", (1,0)),
  )
})

#test-case({
  svg-path(
    ("H", 1),
  )
})

#test-case({
  svg-path(
    ("V", 1),
  )
})

#test-case({
  svg-path(
    ("C", (0,1), (1,1), (1,0)),
  )
})

#test-case({
  svg-path(
    ("Q", (1/2,1), (1,0)),
  )
})

#test-case({
  svg-path(
    ("h", 1),
    ("v", 1),
    ("h", -1),
    "z"
  )
})

#test-case({
  svg-path(
    ("h", 1),
    ("c", (1,0), (0,1), (-1,0)),
    ("h", -1),
    "z",
  )
})

// Test that marks work
#test-case({
  svg-path(
    ("h", 1),
    ("c", (1,0), (0,1), (-1,0)),
    ("h", -1),
    mark: (start: ">", end: ">")
  )
})

// Test anchors
#test-case({
  draw.circle((0,0), stroke: red, radius: 0.3cm)
  svg-path(
    ("anchor", "default", (0,0)),
    ("h", 1),
    ("anchor", "a"),
    ("c", (1,0), (0,1), (-1,0)),
    ("anchor", "b", (0, 0)),
    ("h", -1),
    ("anchor", "c", (2, -1/2)),
    name: "svg", anchor: "b"
  )

  set-style(content: (frame: "circle", padding: 0.01, fill: white))
  content("svg.a", [A])
  content("svg.b", [B])
  content("svg.c", [C])
})
