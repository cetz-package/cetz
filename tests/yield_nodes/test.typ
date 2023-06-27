#set page(width: auto, height: auto)
#import "../../canvas.typ": *

#{
    import "../../draw.typ": * 
    let x = content(())[This #node()[is] a #node(name : "brown")[*_brown_*] fox]
    
    [#hide_nodes(x.at(0).ct) \ \ ]

    [#get_nodes(x.at(0).ct)]
}