#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#let dendrogram-data = (
    (1, 2, 0.5000),
    (3, 4, 1.0000),
    (6, 7, 2.0616),
    (5, 8, 2.5000)
)

#let settings = (
    size: (auto, 6),
    x-ticks: (
        (1,[S1]),
        (2,[S2]),
        (3,[B1]),
        (4,[B2]),
        (5,[Control])
    ),
    line-style: (idx)=>{
        if idx in (0,){ return (stroke: red)}
        if idx in (1,){ return (stroke: green)}
        return (stroke: black)
    },
)

#box(stroke: 2pt + red, canvas({
  chart.dendrogram(
    ..settings,
    dendrogram-data)
}))

#box(stroke: 2pt + red, canvas({
  chart.dendrogram(
    ..settings,
    dendrogram-data,
    mode:"horizontal")
}))