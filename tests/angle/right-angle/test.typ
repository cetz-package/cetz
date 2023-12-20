#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *
  import angle: right-angle

  for a in range(0, 360, step: 36) {
    a *= 1deg
    translate((1.5, 0, 0))
    group({
      let (o, a, b) = ((0,0), (calc.cos(a), calc.sin(a)), (calc.cos(a+90deg), calc.sin(a+90deg)))
      line(a, o, b)
      right-angle(o, a, b)
    })
  }
})

#test-case({
  import draw: *
  import angle: right-angle

  for a in range(0, 360, step: 36) {
    a *= 1deg
    translate((1.5, 0, 0))
    group({
      let (o, a, b) = ((0,0), (calc.cos(a), calc.sin(a)), (calc.cos(a+45deg), calc.sin(a+45deg)))
      line(a, o, b)
      right-angle(o, a, b)
    })
  }
})

#test-case({
  import draw: *
  import angle: right-angle

  for a in range(0, 360, step: 36) {
    a *= 1deg
    translate((1.5, 0, 0))
    group({
      let (o, a, b) = ((0,0), (calc.cos(a), calc.sin(a)), (calc.cos(a+120deg), calc.sin(a+120deg)))
      line(a, o, b)
      right-angle(o, a, b)
    })
  }
})

#test-case({
  import draw: *
  import angle: right-angle, angle

  scale(3)
  let (o, a, b) = ((0,0), (0,1), (1,0))
  line(a, o, b)
  right-angle(o, a, b, name: "angle")
  for-each-anchor("angle", n => {
    if n in ("a", "b", "origin", "corner", "label") {
      circle("angle." + n, stroke: blue, radius: .1)
      content("angle." + n, [#n])
    }
  })
})
