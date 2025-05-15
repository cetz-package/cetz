#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#import decorations: zigzag, coil, wave, square

#let all-fns = (zigzag, coil, wave, square)

#test-case(fn => {
  import draw: *

  fn(line((0,0), (4,0)))
  fn(line((0,1), (4,1)), amplitude: .5)
  fn(line((0,2), (4,2)), amplitude: t => { 1 - .5 * t / 50% })
  fn(line((0,3), (4,3)), amplitude: (0, .5, 1))
}, args: all-fns)

#test-case(fn => {
  import draw: *
  fn(hobby((0,0), (4,0), (6,2)))
}, args: all-fns)

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

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *

  set-style(radius: .9)
  square(circle((0,2)), amplitude: .2, segments: 20)
}))

#test-case(fn => {
  import draw: *

  fn(line((0,0), (3,0)), start: 10%, stop: 90%, amplitude: .5)
  fn(line((0,1), (3,1)), start: 1, stop: 2, amplitude: .5)
}, args: all-fns)

#test-case(fn => {
  import draw: *

  fn(line((0,0,-1), (0,0,1)), start: 10%, stop: 90%)
}, args: all-fns)

#test-case(factor => {
  import draw: *
  square(line((0,0), (3,0)), factor: factor)
}, args: (25%, 50%, 75%))

#test-case({
  import draw: *

  // Keep the fixed amplitude
  for i in range(0, 6) {
    wave(line((0,i), (3,i)), start: 10%, stop: 1 + i / 5,
      segment-length: .22, amplitude: .8)
  }
})

#test-case(fn => {
  import draw: *

  // Amplitudes of type length
  fn(line((0,0), (4,0)), amplitude: 0.25)
  fn(line((0,1), (4,1)), amplitude: 2.5mm)
  fn(line((0,2), (4,2)), amplitude: t => 1em*calc.sin(float(t)*calc.pi))
  fn(line((0,3), (4,3)), amplitude: (5mm, 0, 2mm, 0))
}, args: all-fns)

// Bug #736: Waves with a single segment
// have are sharp on the second peak.
#test-case({
  import draw: *

  wave(line((0,0), (4,0)), segments: 1)
})

// Bug #873: Some values of segment-length caused
// assertion failures due to floating point error.
#test-case(x => {
  import draw: *
  wave(line((0,0), (3,0)), segment-length: x)
}, args: (
  0.333,
  1.33,
  2.5777,
  0.077777,
  0.044488,
))
