#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#import decorations: zigzag, coil, wave

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *

  zigzag(line((0,0), (4,0)))
  zigzag(line((0,1), (4,1)), amplitude: .5)
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *

  wave(line((0,0), (4,0)))
  wave(line((0,1), (4,1)), amplitude: .5)
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *

  coil(line((0,0), (4,0)))
  coil(line((0,1), (4,1)), amplitude: .5)
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

  set-style(radius: .9)
  zigzag(circle((0,0)), amplitude: .2, segments: 20, factor: 0%)
  zigzag(circle((0,2)), amplitude: .2, segments: 20, factor: 50%, stroke: blue)
  zigzag(circle((0,4)), amplitude: .2, segments: 20, factor: 100%, stroke: red)
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *

  set-style(radius: .9)
  coil(circle((0,0)), amplitude: .2, segments: 30, factor: 100%)
  coil(circle((0,2)), amplitude: .2, segments: 30, factor: 120%, stroke: blue)
  coil(circle((0,4)), amplitude: .2, segments: 30, factor: 150%, stroke: red)
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *

  set-style(radius: .9)
  wave(circle((0,0)), amplitude: .2, segments: 20, tension: .3)
  wave(circle((0,2)), amplitude: .2, segments: 20, tension: .5, stroke: blue)
  wave(circle((0,4)), amplitude: .2, segments: 20, tension: 1, stroke: red)
}))


#test-case({
  import draw: *

  zigzag(line((0,0), (3,0)), start: 10%, stop: 90%)
  zigzag(line((0,2), (3,2)), start: 1, stop: 2)
})

#test-case({
  import draw: *

  coil(line((0,0), (3,0)), start: 10%, stop: 90%)
  coil(line((0,2), (3,2)), start: 1, stop: 2)
})

#test-case({
  import draw: *

  wave(line((0,0), (3,0)), start: 10%, stop: 90%)
  wave(line((0,2), (3,2)), start: 1, stop: 2)
})

#test-case({
  import draw: *

  wave(line((0,0,-1), (0,0,1)), start: 10%, stop: 90%)
})

#test-case({
  import draw: *

  // Keep the fixed amplitude
  for i in range(0, 6) {
    wave(line((0,i), (3,i)), start: 10%, stop: 1 + i / 5,
      segment-length: .22, amplitude: .8)
  }
})
