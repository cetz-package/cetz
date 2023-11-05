#set page(width: auto, height: auto)
#import "/src/lib.typ": *

// All Sides
#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  content((0,0), [This is a test.], padding: .5, frame: "rect")
}))

// Array Syntax
#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  // Y, X
  content((0,0), [This is a test.], padding: (.5, 0), frame: "rect")
  content((0,1), [This is a test.], padding: (0, .5), frame: "rect")
  // Top, Y, Bottom
  content((0,2), [This is a test.], padding: (.5, 0, 0), frame: "rect")
  content((0,3), [This is a test.], padding: (0, 0, .5), frame: "rect")
  // Top, Right, Bottom, Left
  content((0,4), [This is a test.], padding: (.5, 0, 0, 0), frame: "rect")
  content((0,5), [This is a test.], padding: (0, .5, 0, 0), frame: "rect")
  content((0,6), [This is a test.], padding: (0, 0, .5, 0), frame: "rect")
  content((0,7), [This is a test.], padding: (0, 0, 0, .5), frame: "rect")
}))

// Dictionary Syntax
#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  content((0,0), [This is a test.], padding: (left: .5), frame: "rect")
  content((0,1), [This is a test.], padding: (right: .5), frame: "rect")
  content((0,2), [This is a test.], padding: (top: .5), frame: "rect")
  content((0,3), [This is a test.], padding: (bottom: .5), frame: "rect")
  content((0,4), [This is a test.], padding: (:), frame: "rect")
}))
