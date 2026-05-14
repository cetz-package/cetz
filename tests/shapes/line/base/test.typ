#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *
  line((0, 0), (3, 0), name: "l")
  show-path-anchors("l", center: none)
})

#test-case({
  import draw: *
  line((0, 0), (3, 0), name: "l")
  show-named-anchors("l", "start", "mid", "end", center: none)
})

#test-case({
  import draw: *
  line((0, 0), (3, 1), (rel: (1, -1)), name: "l")
  show-path-anchors("l", center: none)
})

#test-case({
  import draw: *
  line((0, 0), (3, 1), (rel: (1, -1)), name: "l")
  show-named-anchors("l", "start", "mid", "end", center: none)
})
