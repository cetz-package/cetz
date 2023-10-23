#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#let dendrogram-data = (
    (1, 2, 0.5000),
    (3, 4, 1.0000),
    (6, 7, 2.0616),
    (5, 8, 2.5000)
)

#canvas({
  chart.dendrogram(
    size: (10, 10),
    x-ticks: (
        (1,[S1]),
        (2,[S2]),
        (3,[B1]),
        (4,[B2]),
        (5,[Control])
    ),
    line-style: (idx)=>{
        if idx in (0,){ return (stroke: red + 1pt)}
        if idx in (1,){ return (stroke: green + 1pt)}
        //if idx in (2,){ return (stroke: blue + 1pt)}
    },
    dendrogram-data)
})