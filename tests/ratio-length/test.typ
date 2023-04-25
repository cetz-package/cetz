#set page(width: 10cm, height: 20cm)
#import "../../canvas.typ": *

#box(stroke: 2pt + red, canvas(length: 100%, {
    import "../../draw.typ": *

    stroke(black)
    fill(blue)
    rect((0,0), (1, 1))
}))
