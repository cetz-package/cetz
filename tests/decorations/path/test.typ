#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#import decorations: zigzag, coil, wave

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *

  zigzag(line((0,0), (4,0)))
  zigzag(line((0,1), (4,1)), width: .5)
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *

  wave(line((0,0), (4,0)))
  wave(line((0,1), (4,1)), width: .5)
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *

  coil(line((0,0), (4,0)))
  coil(line((0,1), (4,1)), width: .5)
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *

  zigzag(hobby((0,0), (4,0), (6,2)))
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *

  coil(hobby((0,0), (4,0), (6,2)))
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *

  wave(hobby((0,0), (4,0), (6,2)))
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *

  zigzag(circle((0,0)), width: .2, N: 20, factor: 0%)
  zigzag(circle((0,2)), width: .2, N: 20, factor: 50%, stroke: blue)
  zigzag(circle((0,4)), width: .2, N: 20, factor: 100%, stroke: red)
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *

  coil(circle((0,0)), width: .2, N: 30, factor: 1)
  coil(circle((0,2)), width: .2, N: 30, factor: 1.2, stroke: blue)
  coil(circle((0,4)), width: .2, N: 30, factor: 1.5, stroke: red)
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *

  wave(circle((0,0)), width: .2, N: 20, tension: .3)
  wave(circle((0,2)), width: .2, N: 20, tension: .5, stroke: blue)
  wave(circle((0,4)), width: .2, N: 20, tension: 1, stroke: red)
}))
