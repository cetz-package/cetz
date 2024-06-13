#import "/src/lib.typ": *
#import "/tests/helper.typ": *
#set page(width: auto, height: auto)

#test-case({
  import draw: *
  content((0,0), (+1,+1), align(center + horizon)[tr], frame: "rect")
  content((0,0), (-1,-1), align(center + horizon)[bl], frame: "rect")
  content((0,0), (-1,+1), align(center + horizon)[tl], frame: "rect")
  content((0,0), (+1,-1), align(center + horizon)[br], frame: "rect")
})
