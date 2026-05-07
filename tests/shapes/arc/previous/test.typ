#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *

  arc((0,0), start: 0deg, stop: 180deg)
  point((), [Current Point])
})

#test-case({
  import draw: *

  arc((0,0), start: 180deg, stop: 0deg)
  point((), [Current Point])
})
