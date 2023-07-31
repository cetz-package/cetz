# 0.0.3
## Plot
- Added arguments `plot-style` and `mark-style` to the `plot(..)` base function
  that allow providing a base style that gets inherited by all graphs.
  Plots now default to the color pattern (blue, red, green, yellow, black) for
  stroking & filling graphs.

## Axes
- Fixed axis label alignment.

## Draw
- Fixed issue #24, assert if line has fewer than two points.

# 0.0.2
## Content
- The `content` function now supports a second coordinate as `angle`, to
  compute the rotation angle between the origin.
- Anchors of the `content` function are now properly rotated.

## Tree
- Added the `tree` module for laying out trees.

## Canvas
- Changed transformation matrix multiplication order from `Local * World to`
  World * Local.
- Added `set-viewport` function for setting up scaling and translation to draw
  insides a rectangular region.
- The function `rect` now emits rotated anchors,
  before it did not set anchors but used the bounding box.
- New function `copy-anchors` to copy anchors of an element into a group.
- Arcs are now approximated using up to 4 bezier curves instead of using
  sampling with straight lines.
- New function `intersections` that emits anchors at all child element
  intersection points.

## Chart
- Added new library `chart` for drawing charts, currently only bar- and columncharts are supported.

## Plot
- Added new library `plot` for drawing line charts (of functions), replacing `typst-plot`.
