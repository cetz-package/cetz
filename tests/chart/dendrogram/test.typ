#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#let data = (
/* x1, x2, h */
  (4,  5,  1), // blue
  (1,  3,  1), // red
  (6,  7,  2), // green
  (2,  8,  2.5)
)

#let settings = (
  line-style: (idx)=>{(stroke: (blue, red, green).at(idx, default: black))},
  y-min: 0,
  size: (6, 6)
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
