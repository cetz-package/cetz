#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#import draw: line

// Solid stroke (default)
#test-case({
  line((0,0), (1,0), mark: (end: ">"))
})

// Inherit stroke
#test-case({
  line((0,0), (1,0), stroke: blue, mark: (end: ">"))
})
#test-case({
  line((0,0), (1,0), stroke: blue + 2pt, mark: (end: ">"))
})
#test-case({
  line((0,0), (1,0), stroke: (paint: blue), mark: (end: ">"))
})

// Do not inherit dash pattern
#test-case({
  line((0,0), (1,0), stroke: (dash: "dotted"), mark: (end: ">"))
})
#test-case({
  line((0,0), (1,0), stroke: (dash: "dotted", paint: blue), mark: (end: ">"))
})
