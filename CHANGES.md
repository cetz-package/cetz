* 0.0.2
** Content
- The `content` function now supports a second coordinate as `angle`, to
  compute the rotation angle between the origin
- *[!]* Anchors of the `content` function are now properly rotated

** Tree
- Added the `tree` module for laying out trees

** Canvas
- *[!]* Changed transformation matrix multiplication order from Local * World to
  World * Local.
- Added `set-viewport` function for setting up scaling and translation to draw
  insides a rectangular region
- *[!]* Rects now emit rotated anchors, before they did not set anchors
- New function `copy-anchors` to copy all or some anchors of an element

** Chart
- Added new library `chart` for drawing charts, currently only barcharts are supported

** Plot
- Added new library `plot` for drawing line charts (of functions), replacing `typst-plot`
