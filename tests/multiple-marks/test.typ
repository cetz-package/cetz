#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#let l = ("|", "o", ">")

#test-case({
  import draw: *

  line((-1, -1), (1, 1), mark: (start: l, end: l))
})

#test-case({
  import draw: *

  bezier((-1, -1), (1, 1), (-1, 1), (1, -1), mark: (start: l, end: l))
})

#test-case({
  import draw: *

  arc((0, 0), start: 0deg, stop: 180deg, anchor: "center", mark: (start: l, end: l))
})
