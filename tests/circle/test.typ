#set page(width: auto, height: auto)
#import "../../canvas.typ": *

#box(stroke: 2pt + red, canvas(length: .5cm, {
    import "../../draw.typ": *

    for r in range(0, 6) {
      group({
        rotate(r * 30deg)
        translate((4.5, 4.5))
        stroke(none); fill((red, green, blue, yellow).at(calc.rem(r, 4)))
        circle((0,0), radius: (4, .5))
      })
    }

    for x in range(0, 10) {
      for y in range(0, 10) {
        circle((x, y), radius: .45)
      }
    }
}))
