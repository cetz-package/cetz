#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#let data = (
/* x1, x2, h */
  (1,  2,  1), // blue
  (2,  4,  2), // red
  (3,  5,  3), // green
)

#let settings = (
  size: (auto, 6),
  line-style: (idx)=>{
    if idx == 0 { return (stroke: blue) }
    if idx == 1 { return (stroke: red) }
    if idx == 2 { return (stroke: green) }
    return (stroke: black)
  },
)

#box(stroke: 2pt + red, canvas({
  chart.dendrogram(
    mode: "vertical",
    data,
    ..settings)
}))

#box(stroke: 2pt + red, canvas({
  chart.dendrogram(
    mode:"horizontal",
    data,
    ..settings)
}))
