#import "/src/lib.typ": *
#import "/tests/helper.typ": *
#set page(width: auto, height: auto)

#let axes(l) = {
  import draw: *

  set-style(mark: (end: ">"))

  on-layer(-1, {
    line((-l,0), (l,0), stroke: red, name: "x")
    content((rel: ((name: "x", anchor: 50%), .5, "x.end"), to: "x.end"), text(red, $x$))

    line((0,-l), (0,l), stroke: blue, name: "y")
    content((rel: ((name: "y", anchor: 50%), .5, "y.end"), to: "y.end"), text(blue, $y$))

    line((0,0,-l), (0,0,l), stroke: green, name: "z", mark: (z-up: (1,0,0)))
    content((rel: ((name: "z", anchor: 50%), .5, "z.end"), to: "z.end"), text(green, $z$))
  })
}

#let checkerboard() = {
  import draw: *
  for x in range(0, 3) {
    for y in range(0, 3) {
      rect((x,y),(rel: (1,1)),
        fill: if calc.rem(x + y, 2) != 0 { black } else { white })
    }
  }
}

#test-case({
  import draw: *
  ortho(reset-transform: false, {
    line((-1, 0), (1, 0), mark: (end: ">"))
  })
})

#test-case({
  import draw: *
  ortho({
    axes(4)
    checkerboard() // Same as on-xy
  })
})

#test-case({
  import draw: *
  ortho({
    axes(4)
    on-xy({
      checkerboard()
    })
  })
})

#test-case({
  import draw: *
  ortho({
    axes(4)
    on-xz({
      checkerboard()
    })
  })
})

#test-case({
  import draw: *
  ortho({
    axes(4)
    on-yz({
      checkerboard()
    })
  })
})

#test-case({
  import draw: *
  ortho(sorted: true, {
    axes(4)
    on-yz(x: -1, {
      checkerboard()
    })
    on-xy(z: -1, {
      checkerboard()
    })
    on-xz(y: -1, {
      checkerboard()
    })
  })
})

// Ordering
#test-case({
  import draw: *
  ortho(sorted: true, {
    scope({ translate((0, 0, +1)); rect((-1, -1), (1, 1), fill: blue) })
    scope({ translate((0, 0,  0)); rect((-1, -1), (1, 1), fill: red) })
    scope({ translate((0, 0, -1)); rect((-1, -1), (1, 1), fill: green) })
  })
})

// Fully visible
#test-case({
  import draw: *
  ortho(x: 0deg, y: 0deg, cull-face: "cw", {
    rect((-1, -1), (1, 1))
    circle((0,0))
  })
})

// Nothing visible
#test-case({
  import draw: *
  ortho(x: 0deg, y: 0deg, cull-face: "cw", {
    rect((-1, -1), (1, 1))
    rotate(y: 91deg)
    circle((0,0))
  })
})
