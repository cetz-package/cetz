#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#let angles = (0, 90, 180, 270, 45, 135).map(v => v * 1deg)

#test-case(a => {
  import draw: *
  import angle: right-angle

  let (o, a, b) = (
    (0,0),
    ((0, 0), 100%, a, (1, 0)),
    ((0, 0), 100%, a + 90deg, (1, 0)),
  )

  line(a, o, b)
  right-angle(o, a, b)
}, args: angles)

#test-case(a => {
  import draw: *
  import angle: right-angle

  let (o, a, b) = (
    (0,0),
    ((0, 0), 100%, a, (1, 0)),
    ((0, 0), 100%, a + 45deg, (1, 0)),
  )

  line(a, o, b)
  right-angle(o, a, b)
}, args: angles)

#test-case(a => {
  import draw: *
  import angle: right-angle

  let (o, a, b) = (
    (0,0),
    ((0, 0), 100%, a, (1, 0)),
    ((0, 0), 100%, a + 135deg, (1, 0)),
  )

  line(a, o, b)
  right-angle(o, a, b)
}, args: angles)

#test-case({
  import draw: *
  import angle: right-angle

  let (o, a, b) = ((0,0), (0,1), (1,0))
  line(a, o, b)
  right-angle(o, a, b, name: "angle")
  for-each-anchor("angle", n => {
    if n in ("a", "b", "origin", "corner", "label") {
      circle("angle." + n, stroke: blue, radius: .1)
    }
  })
})

// Bug #571
#test-case({
  import draw: *
  import angle: right-angle

  let (o, a, b) = ((0,3), (0,4), (1,3))
  line(a, o, b)
  right-angle(o, a, b, name: "angle")
})
