#let version = (0,2,0)

#import "canvas.typ": canvas
#import "draw.typ"

// Expose utilities
#import "vector.typ"
#import "matrix.typ"
#import "styles.typ"
#import "coordinate.typ"
#import "drawable.typ"
#import "process.typ"
#import "util.typ"
#import "path-util.typ"

// Libraries
#import "lib/axes.typ"
#import "lib/plot.typ"
#import "lib/chart.typ"
#import "lib/palette.typ"
#import "lib/angle.typ"
#import "lib/tree.typ"
#import "lib/decorations.typ"

// // These are aliases to prevent name collisions
// // You can use them for importing the module into the
// // root namespace:
// //   #import "@.../cetz": canvas, cetz-draw
// #let cetz-draw = draw
// #let cetz-tree = tree
// #let cetz-vector = vector
// #let cetz-matrix = matrix
