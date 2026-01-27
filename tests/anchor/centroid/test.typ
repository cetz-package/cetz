#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#let x(pos) = {
  import draw: *
  group({
    set-origin(pos)
    scale(.1)
    stroke(red)
    line((-1, -1), (1,  1))
    line((-1,  1), (1, -1))
  })
}

#test-case({
  import draw: *

  line((-1, -1), (1, 1), name: "elem", close: true)
  x("elem.centroid")
})

#test-case({
  import draw: *

  line((-1, -1), (+1, -1), (0, 1), name: "elem", close: true)
  x("elem.centroid")
})

#test-case({
  import draw: *

  line((-1, -1), (+1, -1), (+1, +1), (-1, +1), name: "elem", close: true)
  x("elem.centroid")
})

#test-case({
  import draw: *

  line((-1, -1), (+1, -1), (+1, +0), (+0, +0),
       (+0, +1), (-1, +1), name: "elem", close: true)
  x("elem.centroid")
})

#test-case({
  import draw: *

  merge-path(name: "elem", close: true, {
    arc((0,0), start: 0deg, stop: 90deg)
    line((), (rel: (-1, 0)), (rel: (0, -1)))
  })
  x("elem.centroid")
})

#test-case({
  import draw: *

  merge-path(name: "elem", close: true, {
    // Circle is in merge-path!
    circle(())
  })
  x("elem.centroid")
})
