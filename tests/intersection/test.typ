#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#let show-intersections(body) = test-case({
  import draw: *
  group({
    intersections("i", {
      body
    })
    for-each-anchor("i", (name) => {
      content((), [#name], frame: "circle", fill: white.transparentize(50%))
    })
  }, name: "g")
})

#show-intersections({
  import draw: *
  line((-1,-1), (1,1))
})

#show-intersections({
  import draw: *
  line((-1,-1), (1,1))
  line((-1,1), (1,-1))
})

#show-intersections({
  import draw: *
  line((-1,.5),(1,.5))
  line((-1,-1), (1,1))
  line((-1,1), (1,-1))
})

#show-intersections({
  import draw: *
  circle((0,0))
  line((-1,-1), (1,1))
})

#show-intersections({
  import draw: *
  circle((0,0))
  line((-1,.5),(1,.5))
})

#show-intersections({
  import draw: *
  bezier-through((-1,0), (0,1), (1,0))
  line((-1,.5),(1,.5))
})

#show-intersections({
  import draw: *
  bezier-through((-1,0), (0,.5), (1,0))
  circle((0,0), radius: .8)
})

#show-intersections({
  import draw: *
  bezier-through((-1,0), (0,.5), (1,0))
  bezier-through((-1,.5), (0,-.5), (1,.5))
})

#show-intersections({
  import draw: *
  bezier((-1,-1), (1,1), (-.5,2), (.5,-2))
  bezier((-1,1), (1,-1), (-.5,-2), (.5,2))
})

#show-intersections({
  import draw: *
  grid((0,0), (2,2), step: 1)
})

#show-intersections({
  import draw: *
  rect((0,0), (2,2))
  rotate(45deg)
  line((0,0), (calc.sqrt(2*calc.pow(2,2)),0))
})

#show-intersections({
  import draw: *
  // The marks must not generate intersections with the line!
  line((0,0), (2,2), mark: (start: ">", end: ">"))
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
    content("i." + name, [#name], frame: "circle", fill: white)
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

// No intersection with the mark shape
#test-case({
  import draw: *

  line((0,0), (1,0), mark: (end: ">", scale: 4), name: "a")
  line((0,-0.25), (0,0.25), (1,0.25), name: "b")

  intersections("i", "a", "b")
  for-each-anchor("i", (name) => {
    content((), [#name], frame: "circle", fill: white)
  })
})

// Example from a bug report
#show-intersections({
  import draw: *

  let points = ((1.0, 1.5), (1.0, 1.48), (1.0, 1.46), (1.0, 1.44), (1.0, 1.42), (1.0, 1.4), (1.0, 1.38), (1.0, 1.36), (1.0, 1.3399999999999999), (1.0, 1.32), (1.0, 1.3), (2.0, 1.71), (2.6, 1.36), (3.8, 1.85), (4.6, 1.29), (5.0, 2.0), (5.0, 2.02), (5.0, 2.04), (5.0, 2.06), (5.0, 2.08), (5.0, 2.1), (5.0, 2.12), (5.0, 2.1399999999999997), (5.0, 2.16), (5.0, 2.1799999999999997), (5.0, 2.2))

  hobby(..points)
  line((1.5, 0), (1.5, 6))
})

#{
  import "/src/intersection.typ": line-line
  import "/src/vector.typ"

  let pt = line-line(
    (0, 0, 0),
    (0.001, 0.001, 0.001),
    (0, 0.001, 0.001),
    (0.001, 0, 0),
  )
  assert.ne(pt, none)
  assert(vector.dist(pt, (0.0005, 0.0005, 0.0005)) < 1e-9)
}
