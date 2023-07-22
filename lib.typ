#import "canvas.typ": canvas
#import "draw.typ"
#import "coordinate.typ"
#import "vector.typ"
#import "matrix.typ"
#import "tree.typ"
#import "plot.typ"

// These are aliases to prevent name collisions
// You can use them for importing the module into the
// root namespace:
//   #import "@.../cetz": canvas, cetz-draw
#let cetz-draw = draw
#let cetz-tree = tree
#let cetz-plot = plot
#let cetz-vector = vector
#let cetz-matrix = matrix

