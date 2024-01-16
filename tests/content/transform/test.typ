#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#let test() = {
  import draw: *
  content((0,0), [This is a test.], padding: .1, name: "e")
  for-each-anchor("e", n => {
    circle("e." + n, radius: .05)
  })
}

#test-case({
  import draw: *
  cross((0,0))
  scale(2.5)
  cross((0,0))
  test()
})

#test-case({
  import draw: *
  cross((0,0))
  rotate(45deg)
  cross((0,0))
  test()
})

#test-case({
  import draw: *
  cross((0,0))
  translate((1,2,1))
  cross((0,0))
  test()
})
