#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

// No Position
#test-case({
  import draw: *

  // Left
  mark((0,0), (-1,0), symbol: ">", scale: 3, fill: blue)

  // Up
  mark((0,0), (0,1), symbol: ">", scale: 3, fill: green)

  // Down
  mark((0,0), (0,-1), symbol: ">", scale: 3, fill: red)

  // Right
  mark((0,0), (1,0), symbol: ">", scale: 3, fill: yellow)
})

// Angle
#test-case({
  import draw: *

  mark((0,0),   0deg, symbol: ">", scale: 3, fill: blue)
  mark((0,0),  90deg, symbol: ">", scale: 3, fill: green)
  mark((0,0), 180deg, symbol: ">", scale: 3, fill: red)
  mark((0,0), 270deg, symbol: ">", scale: 3, fill: yellow)
})
