#set page(width: auto, height: auto)
#import "/src/lib.typ": *

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
    rotate(-45deg)
    line((0,0), (calc.sqrt(2*calc.pow(2,2)),0))
  })
})

#box(stroke: 2pt + red, canvas({
  import draw: *

  intersections("i", {
    content((0, 0), [Das ist\ ein Text!], frame: "circle", name: "a")
    content((2, 1), [Hallo!], frame: "circle", name: "b")
    // Invisible intersection line
    line("a", "b", stroke: none)
  })
  line("i.0", "i.1", mark: (end: ">"))
}))

