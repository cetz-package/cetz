#set page(width: auto, height: auto)
#import "../../canvas.typ": *

#box(stroke: 2pt + red, canvas({
    import "../../draw.typ": *

    let ring(start, end, radius) = merge-path({
      arc((0, 0), start, end, radius: radius,
          anchor: "origin", name: "outer")
      arc("outer.origin", start, end, radius: radius - .2,
          anchor: "origin", name: "inner")
      line("outer.end", "inner.end")
    }, close: true)

    stroke(black)
    fill(blue)
    for i in range(0, 6) {
      ring((i+1) * 40deg, (i+1) * 40deg + 120deg, 2 - i * .3)
    }
}))
