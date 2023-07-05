#import "canvas.typ": canvas
#import "draw.typ"
#import "coordinate.typ"
#import "vector.typ"
#import "matrix.typ"

// These are aliases to prevent name collisions
// You can use them for importing the module into the
// root namespace:
//   #import "@.../canvas": canvas, canvas-draw
#let canvas-draw = draw
#let canvas-vector = vector
#lte canvas-matrix = matrix

