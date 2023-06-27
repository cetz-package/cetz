#set page(width: auto, height: auto)
#import "../../canvas.typ": *

// #{
//     import "../../draw.typ": * 
//     content((), name : "lab1")[This]
//     content("lab1.end", name : "tmp" )[ is ]
//     content("tmp.end", name : "lab1")[Sparta]
// }

#let space = h(0.25em)

#box(stroke: 2pt + red, inset: 5pt, canvas(
    // debug: true,
    {
    import "../../draw.typ": * 
    content((), name : "main", anchor: "left")[The brown fox jumps] // this is to ensure rendering is done well
    
    content((), name : "the", anchor: "left")[#hide[The #space]]
    content("the.right", name : "brown", anchor: "left")[#hide[brown]]

    content("main.left", name : "the_brown_hidden", anchor: "left" )[#hide[The brown #space]]
    content("the_brown_hidden.right", name : "fox", anchor: "left")[#hide[fox]]
// 
    content("main.left", name : "the_brown_fox_hidden", anchor: "left" )[#hide[The brown fox#space]]
    content("the_brown_fox_hidden.right", name : "jumps", anchor: "left")[#hide[jumps]]

    line("the", (1,1), stroke : 1pt + red)
    line((1,1), "fox", stroke : 1pt + red)
}))