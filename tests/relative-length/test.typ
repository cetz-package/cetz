#set page(width: auto, height: auto)
#import "../../lib.typ": *

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

#box(stroke: 2pt + red, width: 1cm, height: 1cm, canvas(length: 100%, {
  import draw: *

  rect((0, 0), (1, 1))
}))

#box(stroke: 2pt + red, width: 2cm, height: 2cm, canvas(length: 100%, {
  import draw: *

  rect((0, 0), (1, 1))
}))
