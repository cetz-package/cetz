#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import cetz.draw: *
  for i in range(0, 90 + 1) {
    rotate(22deg)
    translate((0,1))
    rotate(-25deg)
    translate((0,-1))
    scale(y: -1)
  }

  // With rounding errors, the line and decoration
  // won't be at the same location.
  line((-1,0), (1,0), stroke: red)

  cetz.decorations.wave(line((-1,0), (1,0), stroke: green))
})

// #580
#test-case({
  import cetz.draw: *
  for i in range(0, 360, step: 3) {
    let th = 1deg * i
    set-ctx(ctx => {
      ctx.transform = ((calc.cos(th), -calc.sin(th), 0, 0),
       (-calc.sin(th), -calc.cos(th), 0, 0),
       (0, 0, 1, 0),
       (0, 0, 0, 1),)
       return ctx
    })

    circle((0deg, 4), radius: 0.1, name: "X", fill: luma(200))
    line("X", (rel: (1,0)))
  }
})
