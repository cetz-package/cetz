#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case(radius => {
  import draw: *

  circle((0, 0), radius: radius, name: "c")
  point("c.center", [center], fill: blue)
}, args: (1, 1cm, (1, .5), (1cm, .5), (.5, 1), (.5, 1cm)))

#test-case(outer => {
  import draw: *

  let center = (1, 1)
  circle(center, outer)
  move-to(center)
  point(outer, [Outer])
  point(center, [center], fill: blue)
  // Make sure, outer does not modify the current point
  point((), [Current Point], placement: "north", fill: blue)
}, args: ((2, 1), (rel: (-1, 0)), (rel: (1, 1))))

#test-case(radius => {
  import draw: *

  circle((0, 0), radius: radius, name: "circle")
  show-compass-anchors(element: "circle")
}, args: (1, (2, 1)))

#test-case(radius => {
  import draw: *

  circle((0, 0), radius: radius, name: "circle")
  show-border-anchors(element: "circle")
}, args: (1, (2, 1)))
