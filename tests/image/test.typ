#set page(width: auto, height: auto)
#import "../../canvas.typ": *

#box(stroke: 2pt + red, canvas({
    import "../../draw.typ": *

    let between(a, b, k) = {
      let (x, y, z) = a
      let (x2, y2, z2) = b
      return (x + (x2 - x) * k,
              y + (y2 - y) * k,
              z + (z2 - z) * k)
    }

    content((0,0), image("image.png", width: 2cm),
            anchor: "top-left", name: "i")

    for k in ("top-left", "top", "top-right", "left", "center", "right",
              "bottom-left", "bottom", "bottom-right") {
        fill(blue); circle("i." + k, radius: .1)
    }

    fill(red); circle((between, "i.top-left", "i.top-right", 0.75), radius: .1)
}))
