#set page(width: 10cm, height: 20cm)
#import "/src/lib.typ": *

#box(stroke: 2pt + red, canvas(length: 100%, {
    import draw: *

    stroke(black)
    fill(blue)
    rect((0,0), (1, 1))
}))
