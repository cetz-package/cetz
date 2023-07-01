#import "canvas.typ": canvas
#import "draw.typ"

// This is an alias to prevent name collisions
// You can use it for importing the module into the
// root namespace:
//   #import "@.../canvas": canvas, canvas-draw
#let canvas-draw = draw

