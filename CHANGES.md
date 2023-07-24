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
