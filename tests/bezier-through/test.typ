#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#let bezier-through(a, b, c, ..args) = {
  import cetz.draw: *
  line(a, b, c, stroke: gray)
  for pt in (a, b, c) {
    circle(pt, radius: .1cm, fill: gray, stroke: none)
  }

  cetz.draw.bezier-through(a, b, c, ..args)
}

#test-case(points => {
  bezier-through(..points)
}, args: (
  ((0,0), (0, 0), (2,0)),
  ((0,0), (2, 0), (2,0)),
  ((0,0), (1, 0), (2,0)),
  ((0,0), (1, 1), (2,0)),
  ((0,0), (1,-1), (2,0)),
  ((0,0), (1, 1), (2,2)),
  ((0,0), (1, 2), (2,2)),
  ((0,0), (1, 0), (2,2)),
  ((0,0), (3, 0), (1,0)),
  ((0,0), (-3,0), (1,0)),
))

#test-case({
  import draw: *

  merge-path(close: true, {
    bezier-through((-1, 0), (-calc.cos(45deg), calc.sin(45deg)), (0, 1))
    bezier-through((0, 1), (calc.cos(45deg), calc.sin(45deg)), (1, 0))
    bezier-through((1, 0), (calc.cos(45deg), -calc.sin(45deg)), (0, -1))
    bezier-through((0, -1), (-calc.cos(45deg), -calc.sin(45deg)), (-1, 0))
  })
})
