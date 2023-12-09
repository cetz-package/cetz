# 0.2.0
CeTZ 0.2.0 requires Typst 0.10.0

## Libs
### Draw
- **BREAKING** Default anchors are now using TikZ like compass names: north, south, east, west, north-west, north-east, south-west and south-east
- **BREAKING** Element anchors have changed! See the documentation for details.
- **BREAKING** Rotation direction changed to CCW
- **BREAKING** Removed the `shadow` function
- **BREAKING** Changed the behaviour of `mark`
- **BREAKING** Changed the behaviour of `translate` by changing the transformation order, changed arguments of `scale` and `translate`
- Content padding has been improved to be configurable per side
- Groups support same padding options as content
- Fixed mark offsetting
- Fixed and improved intersection calculation
- Fixed marks pointing to +/- z
- Fixed and improved the styling algorithm
- Catmull-Rom curves, Hobby curves and arcs now can have marks
- Line elements now use border intersection coordinates if first and/or last coordinate is an element name with a "default" anchor
- Added element `arc-through` to draw an arc through three points
- Added Hobby curves (`hobby`) in addition to catmull (thanks to @Enivex)
- Added `radius` style to `rect` for drawing rounded rects

### Plot
- Added `plot.add-contour(..)` for plotting contour plots
- Added `plot.add-hline(..)` and `plot.add-vline(..)` for plotting h/v lines
- Added `plot.add-between(..)` for filling the area between two line plots
- Added `plot.add-boxwhisker(..)` for displaying boxwhisker plots (thanks to @JamesxX)
- Added `fill-type` option to `plot.add(..)` for specifying a fill type (axis or shape)
- Changed default samples from 100 to 50!
- Fixed plot filling in some cases
- Axes can now be locked (equal) to keep aspect ratio
- Axes can be reversed by setting min > max
- Axis orientation can be changed, enabling rotation of plots
- Plots now support legends!

### Chart
- Added `piechart` for drawing pie- and donut charts
- Added `boxwhisker` for drawing boxwhisker charts

# 0.1.2
CeTZ requires Typst 0.8.0.

## Draw
- New `on-layer(layer, body)` function for drawing with a given layer/z-index
- New `catmull(..)` function for drawing catmull-rom curves
- Changed default anchors of circles and arcs to anchors on the elliptical path
- Added style option to specify triangle mark angle
- Fixed rect anchors if coordinates were swapped
- Fixed bezier extrema/aabb calculation
- Fixed bug with `content` and `intersections`
- Fixed automatic mark offset for lines
- Fixed problems with style inheritance

## Libs
### Plot
- Added `sample-at: (..)` option to `plot.add(..)` for specifying extra sample points
- Added `line: <linear|spline|vh|hv|vhv>` support
- The plot lib tries to linearize data to reduce draw calls
- Fixed custom tick plot formatting
- Allow plots without data

### Decorations
- New decoration library by @RubixDev for drawing braces

# 0.1.1
## Libs
### Angle
- New `angle` library for drawing angles

### Axes
- Support tick label rotation
- Support negative tick mark direction

## Draw
- Fixed `arc` with negative delta
- Fixed division by 0 error when calculating bezier extremas
- Added `mark: (..)` support for `bezier` and `bezier-through`
- Changed `content` to allow for a second coordinate to span content between
- Added `content: (frame: "rect"|"circle")` style for drawing a frame around content
- Default triangle mark angle changed. It can now be set via the style attribute `angle`.
- Arrowheads on lines are now offset so the tip of the triangle points exactly on the
  target position

# 0.1.0
## Plot
- Added arguments `plot-style` and `mark-style` to the `plot(..)` base function
  that allow providing a base style that gets inherited by all graphs.
  Plots now default to the color pattern (blue, red, green, yellow, black) for
  stroking & filling graphs.

## Axes
- Fixed axis label alignment.

## Draw
- Fixed issue #24, assert if line has fewer than two points.
- Fixed an issue with calculating bounding boxes for some transformed paths

## Chart
- Fixed barchart bars getting labeled in reversed order

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
