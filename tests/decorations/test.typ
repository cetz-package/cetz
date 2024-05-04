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
