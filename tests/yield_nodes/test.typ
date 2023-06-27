#set page(width: auto, height: auto)
#import "../../canvas.typ": *

// #{
//     import "../../draw.typ": * 
//     content((), name : "lab1")[This]
//     content("lab1.end", name : "tmp" )[ is ]
//     content("tmp.end", name : "lab1")[Sparta]
// }

#box(stroke: 2pt + red, inset: 5pt, canvas(
    // debug: true,
    {
    import "../../draw.typ": * 
    content((), name : "lab1")[This ]
    content("lab1.right", name : "tmp" )[#h(0.6em) is]    
    content("tmp.right", name : "lab1")[#h(0.6em) Sparta #h(0.6em)]    
}))