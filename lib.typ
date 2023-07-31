#let version = (0,0,3)

#import "canvas.typ": canvas
#import "draw.typ"
#import "coordinate.typ"
#import "vector.typ"
#import "matrix.typ"
#import "tree.typ"

// Libraries
#import "lib/axes.typ"
#import "lib/plot.typ"
#import "lib/chart.typ"
#import "lib/palette.typ"

// These are aliases to prevent name collisions
// You can use them for importing the module into the
// root namespace:
//   #import "@.../cetz": canvas, cetz-draw
#let cetz-draw = draw
#let cetz-tree = tree
#let cetz-vector = vector
#let cetz-matrix = matrix

