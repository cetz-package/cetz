#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/src/bezier.typ": shorten, cubic-point, cubic-arclen

#let test(d, curve: ((0,0), (3,0), (1,2), (2,-2))) = {
  import draw: *

  bezier(..curve, name: "o", stroke: 3pt)

  let short = shorten(..curve, d)
  bezier(..short, stroke: blue, name: "s")

  let o-len = cubic-arclen(..curve)
  let s-len = cubic-arclen(..short)
  content((-1,0), [#calc.round(o-len - s-len, digits: 2)])
}

#block(stroke: 2pt + red, canvas(length: .5cm, {
  test(-.1)
}))

#block(stroke: 2pt + red, canvas(length: .5cm, {
  test(.1)
}))

#block(stroke: 2pt + red, canvas(length: .5cm, {
  test(1)
}))

#block(stroke: 2pt + red, canvas(length: .5cm, {
  test(-1)
}))
