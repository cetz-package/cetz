#set page(width: auto, height: auto)
#import "../../canvas.typ": *

#box(stroke: 2pt + red, canvas({
    import "../../draw.typ": *

    content((0,0), image("image.png", width: 2cm),
            anchor: "top-left", name: "i")

    set-style(radius: .1)
    for k in ("top-left", "top", "top-right", "left", "center", "right",
              "bottom-left", "bottom", "bottom-right") {
        fill(blue); circle("i." + k)
    }

    fill(red); 
    circle(("i.top-left", 0.75, "i.top-right"))
}))
