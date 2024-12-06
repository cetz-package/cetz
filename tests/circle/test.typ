#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case(radius => {
  import draw: *

  circle((0, 0), radius: radius, name: "c")
  point("c.center", "M")
}, args: (1, 1cm, (1, .5), (1cm, .5), (.5, 1), (.5, 1cm)))

#test-case(outer => {
  import draw: *

  let center = (1, 1)
  circle(center, outer)
  move-to(center)
  point(outer, "O")
  point(center, "M")
}, args: ((2, 1), (rel: (1, 0)), (rel: (1, 1))))

#test-case({
  import draw: *

  for z in range(-1, 2) {
    circle((0,0,z))
  }
})
