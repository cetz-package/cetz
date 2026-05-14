#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

// circle:
#test-case({
  import draw: *

  circle((3,2), name: "a", radius: 2pt)
  circle((0, 0), name: "c", radius: 1)

  line(
    // The starting point or element
    "a",
    // The tangent coordinate
    (element: "c", point: "a", solution: 1),
    // The center of the circle
    "c",
    // The other tangent coordinate
    (element: "c", point: "a", solution: 2),
    "a",
    stroke: green
  )
})

// ellipse:
#test-case({
  import draw: *

  circle((3,2), name: "a", radius: 2pt)
  circle((0, 0), name: "c", radius: (0.75, 1.25))

  line(
    "a",
    (element: "c", point: "a", solution: 1),
    "c",
    (element: "c", point: "a", solution: 2),
    "a",
    stroke: green
  )
})
