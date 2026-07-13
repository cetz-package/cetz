#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#set text(10pt)
#box(stroke: 2pt + red, canvas(length: 1em, {
  import draw: *

  content((0,0), [M])
  content((1,0), [M])
  content((0,1), [M])
}))

#set text(20pt)
#box(stroke: 2pt + red, canvas(length: 1em, {
  import draw: *

  content((0,0), [M])
  content((1,0), [M])
  content((0,1), [M])
}))
