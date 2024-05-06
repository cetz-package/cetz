#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

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
  decorations.brace((-1,0), (1,0), ..args, pointiness: 100%, outer-pointiness: 0%)
}, args: (
  (amplitude: 1),
  (amplitude: 2),
  (amplitude: 3),
  (amplitude: 4),
))

#test-case(args => {
  decorations.brace((-1,0), (1,0), ..args, pointiness: 0%, outer-pointiness: 0%)
}, args: (
  (amplitude: 1),
  (amplitude: 2),
  (amplitude: 3),
  (amplitude: 4),
))
