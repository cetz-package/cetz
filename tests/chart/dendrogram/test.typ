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

#let phylo = (
/* x1, x2, h */
  (1, 2,  1), // blue
  (3, 4,  1), // red
  (5, 6,  2), // green
  (7, 8,  2.5),
  (9, 10,  3),
  (11, 12, 4),
  (13, 16, 5),
  (15, 14, 6),
  (17, 18, 8),
)

#box(stroke: 2pt + red, canvas({
  chart.dendrogram(
    mode:"radial",
    phylo,
    ..settings)
}))

