#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *
  import angle: angle

  for a in range(0, 360, step: 36) {
    a *= 1deg
    translate((1.5, 0, 0))
    group({
      let (o, a, b) = ((0,0), (1,0), (calc.cos(a), calc.sin(a)))
      line(a, o, b)
      angle(o, a, b, label: $alpha$)
    })
  }
}))

#test-case({
  import draw: *
  import angle: angle

  for a in range(0, 360, step: 36) {
    a *= 1deg
    translate((1.5, 0, 0))
    group({
      let (o, a, b) = ((0,0), (1,0), (calc.cos(a), calc.sin(a)))
      line(a, o, b)
      angle(o, a, b, label: $alpha$, direction: "cw")
    })
  }
}))

#test-case({
  import draw: *
  import angle: angle

  for a in range(0, 360, step: 36) {
    a *= 1deg
    translate((1.5, 0, 0))
    group({
      let (o, a, b) = ((0,0), (calc.cos(a+90deg), calc.sin(a+90deg)), (calc.cos(a), calc.sin(a)))
      line(a, o, b)
      angle(o, b, a, label: $alpha$)
    })
  }
}))

#test-case({
  import draw: *
  import angle: angle

  for a in range(0, 360, step: 36) {
    a *= 1deg
    translate((1.5, 0, 0))
    group({
      let (o, a, b) = ((0,0), (calc.cos(a+90deg), calc.sin(a+90deg)), (calc.cos(a), calc.sin(a)))
      line(a, o, b)
      angle(o, b, a, label: $alpha$, direction: "cw")
    })
  }
}))

#test-case({
  import draw: *
  import angle: angle

  let (a, b, c) = ((-1, 1), (0, 0), (1, 2))

  line(a, b, c)
  set-style(angle: (stroke: red, label-radius: 1))
  angle(b, c, a, mark: (start: ">", end: ">"), label: $omega$)

  translate((2,0,0))

  line(a, b, c)
  set-style(stroke: blue)
  set-style(angle: (stroke: auto, radius: 1, label-radius: .5))
  angle(b, c, a, mark: (start: "|", end: ">"),
    direction: "cw", label: $alpha$, name: "alpha")

  set-style(stroke: black)
  circle("alpha.origin", radius: .15)
  circle("alpha.label", radius: .25)
  circle("alpha.start", radius: .25)
  circle("alpha.end", radius: .25)
}))

#test-case({
  import draw: *
  import angle: *

  angle((0,0), (1,0), (0,1), mark: (end: ">"))
})

#test-case({
  import draw: *
  import angle: *

  angle((0,0), (1,0), (0,1), mark: (end: ">"), direction: "cw")
})

#test-case({
  import draw: *
  import angle: *

  angle((0,0), (1,0), (0,1), radius: .5cm)
  angle((0,0), (1,0), (0,1), radius: 75%, stroke: blue)
  angle((0,0), (1,0), (0,1), radius: 1, stroke: green)
})
