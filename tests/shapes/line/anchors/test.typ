#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *

  line((0, 0), (rel: (1, 0)), (1, 1), name: "line")
  point("line.start", [start])
  point("line.mid", [mid])
  point("line.end", [end], placement: "north")
})

#test-case({
  import draw: *

  line((0, 0), (rel: (1, 0)), (1, 1), name: "line", close: true)
  point("line.start", [start])
  point("line.mid", [mid])
  point("line.end", [end], placement: "north")
  point("line.centroid", [centroid])
})

#test-case({
  import draw: *

  line((0, 0), (rel: (1, 0)), (1, 1), name: "line")
  point("line.0%", [0%])
  point("line.30%", [30%])
  point("line.90%", [90%])
})

#test-case({
  import draw: *

  line((0, 0), (rel: (1, 0)), (1, 1), name: "line")
  point("line.-2", [-2 (oob)], placement: "north")
  point("line.0", [0])
  point("line.0.5", [0.5])
  point("line.1.25", [1.25])
  point("line.4", [4 (oob)], placement: "north")
})
