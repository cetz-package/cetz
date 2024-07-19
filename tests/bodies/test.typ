#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#let h-test-case = test-case
#let test-case(body) = h-test-case({
  draw.set-style(stroke: (join: "round"))
  body
})

#test-case({
  import draw: *
  prism({ rect((-1, -1), (1, 1)) }, 1)
})

#test-case({
  import draw: *
  prism({
    circle((0,0))
  }, samples: 3, 1)
})

#test-case({
  import draw: *
  set-style(prism: (
    fill-back: blue,
    fill-front: red,
    fill-side: yellow,
  ))
  ortho(cull-face: "cw", {
    prism({
      line((-1, -1), (1, -1), (0, 1), close: true)
    }, -2)
    translate((3, 0, 0))
    rotate(y: 160deg)
    prism({
      line((-1, -1), (1, -1), (0, 0), close: true)
    }, -2)
  })
})

#test-case({
  import draw: *
  ortho(x: 10deg, y: 30deg, {
    prism({
      translate((1,0,0))
      rect((-1, -1), (1, 1))
    }, 2)
    prism({
      translate((-2,0,0))
      rect((-1, -1), (1, 1))
    }, 2)
    prism({
      translate((1,0,-3))
      rect((-1, -1), (1, 1))
    }, 2)
    prism({
      translate((-2,0,-3))
      rect((-1, -1), (1, 1))
    }, 2)
  })
})
