#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  decorations.brace((-1,0), (1,0), stroke: blue, amplitude: 1, thickness: 50%, pointiness: 25%, outer-thickness: .1)
})

#test-case(args => {
  decorations.brace((-1,-1), (1,1), ..args)
}, args: ((:), (flip: true)))

#test-case(args => {
  decorations.brace((-1,0), (1,0), ..args)
}, args: (
  (amplitude: .3),
  (pointiness: 0%),
  (pointiness: 50%),
  (pointiness: 100%),
))

#test-case(args => {
  decorations.flat-brace((-1,-1), (1,1), ..args)
}, args: ((:), (flip: true)))

#test-case(args => {
  decorations.flat-brace((-1,0), (1,0), ..args)
}, args: (
  (amplitude: .7),
  (curves: (.5, 0, 0, 0), outer-curves: 1),
  (aspect: .3),
))

// Bug #577
#test-case(args => {
  decorations.brace((-1,0), (1,0), ..args, pointiness: 100%)
}, args: (
  (amplitude: 0.5),
  (amplitude: 1),
))

#test-case(args => {
  decorations.brace((-1,0), (1,0), ..args, pointiness: 0%)
}, args: (
  (amplitude: 0.5),
  (amplitude: 1),
))

// Bug #687
#test-case(args => {
  decorations.flat-brace((-1,-1), (1,1), ..args, name: "brace")
  draw.circle("brace.content", radius: 0.1);
}, args: (
  (flip: false),
  (flip: true),
))

#test-case(args => {
  decorations.brace((-1,-1), (1,1), ..args, name: "brace")
  draw.circle("brace.content", radius: 0.1);
}, args: (
  (flip: false),
  (flip: true),
))

#test-case({
  decorations.flat-brace((0,0), (1,0), stroke: blue, fill: gray)
  decorations.brace((0,1), (1,1), stroke: blue, fill: gray, taper: false)
})
