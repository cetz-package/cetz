#set page(width: auto, height: auto)
#import "../../src/lib.typ": *

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  import angle: angle

  for a in range(0, 360, step: 36) {
    a *= 1deg
    translate((1.5, 0, 0))
    group({
      let (o, a, b) = ((0,0), (1,0), (calc.cos(a), calc.sin(a)))
      line(a, o, b)
      angle(o, a, b, label: $alpha$, inner: true)
    })
  }
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  import angle: angle

  for a in range(0, 360, step: 36) {
    a *= 1deg
    translate((1.5, 0, 0))
    group({
      let (o, a, b) = ((0,0), (1,0), (calc.cos(a), calc.sin(a)))
      line(a, o, b)
      angle(o, a, b, label: $alpha$, inner: false)
    })
  }
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  import angle: angle

  for a in range(0, 360, step: 36) {
    a *= 1deg
    translate((1.5, 0, 0))
    group({
      let (o, a, b) = ((0,0), (calc.cos(a+90deg), calc.sin(a+90deg)), (calc.cos(a), calc.sin(a)))
      line(a, o, b)
      angle(o, b, a, label: $alpha$, inner: true)
    })
  }
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  import angle: angle

  for a in range(0, 360, step: 36) {
    a *= 1deg
    translate((1.5, 0, 0))
    group({
      let (o, a, b) = ((0,0), (calc.cos(a+90deg), calc.sin(a+90deg)), (calc.cos(a), calc.sin(a)))
      line(a, o, b)
      angle(o, b, a, label: $alpha$, inner: false)
    })
  }
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  import angle: angle

  let (a, b, c) = ((-1, 1), (0, 0), (1, 2))

  line(a, b, c)
  set-style(stroke: red, label-radius: 1, selector: "angle")
  angle(b, a, c, mark: (start: ">", end: ">"),
    inner: true, label: $omega$)

  translate((2,0,0))

  line(a, b, c)
  set-style(stroke: blue, radius: 1, label-radius: .5, selector: "angle")
  angle(b, c, a, mark: (start: ">", end: ">"),
    inner: false, label: $alpha$, name: "alpha")

  circle("alpha.origin", radius: .15)
  circle("alpha.label", radius: .25)
  circle("alpha.start", radius: .25)
  circle("alpha.end", radius: .25)
}))
