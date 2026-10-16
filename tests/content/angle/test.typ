#import "/src/lib.typ": *
#import "/tests/helper.typ": *
#set page(width: auto, height: auto)

// #1032
#test-case({
  import draw: *
  set-style(padding: 5pt)

  line((0, 0), (5, 5), name: "line1")
  content("line1.50%", angle: "line1.end", anchor: "south", [Content])

  rotate(15deg)

  line((5, 0), (10, 5), name: "line2")
  content("line2.50%", angle: "line2.end", anchor: "south", [Content])
})
