#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *

  spring.sine((0,0), (4,0))
  spring.sine((0,2), (4,2), N: 5, width: .5)
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *

  spring.sine((0,0), (0,4))
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *

  spring.sine((0,0), (4,4))
}))
