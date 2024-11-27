#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#let test(body) = canvas(length: 1cm, {
  import draw: *

  group({
    intersections("i", {
      body
    })
    for-each-anchor("i", (name) => {
      circle("i."+name, radius: .1, fill: red)
    })
  })
})

#box(stroke: 2pt + red, {
  import draw: *
  test({
    line((-1,-1), (1,1))
  })
  test({
    line((-1,-1), (1,1))
    line((-1,1), (1,-1))
  })
  test({
    line((-1,.5),(1,.5))
    line((-1,-1), (1,1))
    line((-1,1), (1,-1))
  })
  test({
    circle((0,0))
    line((-1,-1), (1,1))
  })
  test({
    circle((0,0))
    line((-1,.5),(1,.5))
  })
  test({
    bezier-through((-1,0), (0,1), (1,0))
    line((-1,.5),(1,.5))
  })
  test({
    bezier-through((-1,0), (0,.5), (1,0))
    circle((0,0), radius: .8)
  })
  test({
    bezier-through((-1,0), (0,.5), (1,0))
    bezier-through((-1,.5), (0,-.5), (1,.5))
  })
  test({
    bezier((-1,-1), (1,1), (-.5,2), (.5,-2))
    bezier((-1,1), (1,-1), (-.5,-2), (.5,2))
  })
  test({
    grid((0,0), (2,2), step: 1)
  })
  test({
    rect((0,0), (2,2))
    rotate(45deg)
    line((0,0), (calc.sqrt(2*calc.pow(2,2)),0))
  })
  test({
    // The marks must not generate intersections with the line!
    line((0,0), (2,2), mark: (start: ">", end: ">"))
  })
})

#test-case({
  import draw: *

  intersections("i", {
    content((0, 0), [This is\ Text!], frame: "circle", name: "a")
    content((2, 1), [Hello!], frame: "circle", name: "b")
    // Invisible intersection line
    line("a.default", "b.default", stroke: none)
  })
  line("i.0", "i.1", mark: (end: ">"))
})

#test-case({
  import draw: *

  circle((0,0), name: "a")
  rect((0,0), (2,2), name: "b")
  intersections("i", "a", "b", {
    line((-1,-1), (1,1))
  })
  for-each-anchor("i", (name) => {
    circle("i."+name, radius: .1, fill: red)
  })
})

#test-case(fn => {
  import draw: *

  let c = circle((1,1), name: "a", radius: 1.25)
  let r = rect((0,0), (2,2), name: "b")
  intersections("i", r, c, sort: fn)

  for-each-anchor("i", (name) => {
    content((), [#name], frame: "circle", fill: white)
  })
}, args: (
  none,
  sorting.points-by-angle.with(reference: (1, 1)),
  sorting.points-by-distance.with(reference: (0, 0.1)),
))
