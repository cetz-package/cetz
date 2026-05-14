#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case(solution => {
  import draw: *

  let p = (2, 1)
  circle((0, 0), name: "c")
  cross(p)
  line(p, (element: "c", point: p, solution: solution))
}, args: (0, 1))

#test-case(solution => {
  import draw: *

  let p = (1, 2)
  circle((0, 0), name: "c", radius: (2, 1))
  cross(p)
  line(p, (element: "c", point: p, solution: solution))
}, args: (0, 1))

// Special case: Point on the ellipse border
#test-case(p => {
  import draw: *

  circle((0, 0), name: "c")
  cross(p)

  line((p, -1, (element: "c", point: p, solution: 1)),
       (p, +1, (element: "c", point: p, solution: 1)))
}, args: ("c.0deg", "c.30deg", "c.185deg"))

#test-case(p => {
  import draw: *

  circle((0, 0), name: "c", radius: (2, 1))
  cross(p)

  line((p, -1, (element: "c", point: p, solution: 1)),
       (p, +1, (element: "c", point: p, solution: 1)))
}, args: ("c.0deg", "c.30deg", "c.185deg"))
