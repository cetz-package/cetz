#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *

  stroke(gray + 0.5pt)
  line((-2, 0), (2, 0))
  line((0, -1), (0, 1))

  stroke(black)
  move-to((-1.5, -0.5))
  line((), (rel: (1, 1)), (rel: (1, -1)), (rel: (1, 1)))

  point((), [Current Point])
})

#test-case({
  import draw: *

  point((0, 0), $O_1$)
  rect((-1, -1), (1, 1), name: "r")
  set-origin("r.north-east")
  point((0, 0), $O_2$)
})
