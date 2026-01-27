#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#let show-points(..pts) = {
  import draw: *
  for pt in pts.pos() {
    circle(pt, radius: .1)
  }
}

#let test(a, b, c) = {
  import draw: *
  group({
    anchor("default", (0,0,0))
    show-points(a, b, c)
    arc-through(a, b, c)
  }, name: "g", anchor: "west", padding: .1)
  set-origin("g.east")
}

#test-case({
  import draw: *

  test((0,0), (1, 1), (2, 0))
  test((0,0), (1,-1), (2, 0))
  test((0,1), (1, 0), (0,-1))
  test((0,1), (-1,0), (0,-1))
})

#test-case({
  import draw: *

  for a in range(36, 360 + 36, step: 36) {
    let a = a * 1deg
    test((1,0),
         (calc.cos(a / 2), calc.sin(a / 2)),
         (calc.cos(a), calc.sin(a)))
  }
})

#test-case({
  import draw: *

  for d in range(0, 8 + 1) {
    let d = (d - 2) / 5
    test((0,0), (1,d), (2,.5))
  }
})

#test-case({
  import draw: *

  // The style radius must not influence the
  // arc radius!
  set-style(radius: 5)
  set-style(arc: (radius: 5))
  test((0,0), (1, 1), (2, 0))
})
