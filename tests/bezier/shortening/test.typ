#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/src/bezier.typ": cubic-shorten, cubic-point, cubic-arclen

#let test(d, curve: ((0,0), (3,0), (1,2), (2,-8))) = {
  import draw: *

  bezier(..curve, name: "o", stroke: 3pt + blue)

  let short = cubic-shorten(..curve, d, samples: 505)
  bezier(..short, stroke: 3pt + black, name: "s")

  let o-len = cubic-arclen(..curve)
  let s-len = cubic-arclen(..short)
  content((4,0), [#calc.round(o-len - s-len, digits: 2)])
}

#for d in (0, .1, .25, .5, 1, 2, 3) {
  block(stroke: 2pt + red, canvas(length: .5cm, {
    test(-d)
  }))
  block(stroke: 2pt + red, canvas(length: .5cm, {
    test(+d)
  }))
}
