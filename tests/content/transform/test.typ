#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#let test() = {
  import draw: *
  content((1,1), [This is a test.], padding: .1, name: "e")
  for-each-anchor("e", n => {
    circle("e." + n, radius: .05)
  })
}

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  scale(2.5)
  test()
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  rotate(45deg)
  test()
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  translate((2,3,4))
  test()
}))
