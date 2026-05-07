#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *

  rect((-1, -1), (1, 1), name: "rect")
  show-compass-anchors(element: "rect")
})

#test-case({
  import draw: *

  rect((-1, -1), (1, 1), name: "rect")
  show-border-anchors(element: "rect")
})

#test-case({
  import draw: *

  rect((-2, -1), (2, 1), name: "rect")
  show-compass-anchors(element: "rect")
})

#test-case({
  import draw: *

  rect((-2, -1), (2, 1), name: "rect")
  show-border-anchors(element: "rect")
})

#test-case({
  import draw: *

  // Check size normalization (no “reversed” rect)
  rect((2, 1), (-2, -1), name: "rect")
  show-compass-anchors(element: "rect")
})
