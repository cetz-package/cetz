#import "/src/draw.typ"
#import "/src/styles.typ"
#import "../axes.typ"
#import "../palette.typ"

#let default-style = (
  axes: (:)
)

// Valid dendrogram modes
#let dendrogram-modes = (
  "vertical",
  "horizontal"
)

/// Draw a dendrogram. A dendrogram is a chart that plots relative distances in 
/// higher dimensional spaces. It is often used by data scientists in clustering
/// analyses.
///
/// *Style root*: `dendrogram`.
///
/// - data (array): Array of data rows, with each entry representing a leaf on
///                 the dendrogram. A row can be of type array or dictionary,
///                 with `x1-key`, `x2-key`, and `height-key` being the keys
///                 used to axcess a row's links and heights.
///
///                 *Example*
///                 ```typc
///                 ((1, 2, 0.5), (3, 4, 1), (6, 7, 2), (5, 8, 2.5))
///                 ```
/// - x1-key (int,string): Key to access the first cluster of a data row. This 
///                        key is used as argument to the rows `.at(..)` 
///                        function.
/// - x2-key (int,string): Key to access the second cluster of a data row. 
///                        This key is used as argument to the rows `.at(..)` 
///                        function.
/// - height-key (int,string): Key to access height of a cluster.
///                           These keys are used as argument to the
///                           rows `.at(..)` function.
/// - mode (string): Chart mode:
///                  - `"vertical"` -- Vertically displayed dendrogram
///                  - `"horizontal"` -- Horizontally displayed dendrogram
/// - size (array): Chart size as width and height tuple in canvas units;
///                 height can be set to `auto`.
/// - line-style (style,function): Style or function (idx => style) to use for
///                               each leaf, accepts a palette function.
/// - x-label (content,none): X axis label
/// - y-tick-step (float): Step size of y axis ticks 
/// - x-ticks (array): List of tick values or value/label tuples
///
///                    *Example*
///                    
///                    `(1, 5, 10)` or `((1, [One]), (2, [Two]), (10, [Ten]))`
/// - y-ticks (array): List of tick values or value/label tuples
///
///                    *Example*
///                    
///                    `(1, 5, 10)` or `((1, [One]), (2, [Two]), (10, [Ten]))`
/// - y-unit (content,auto): Tick suffix added to each tick label
/// - y-label (content,none): Y axis label
/// - y-min (number,auto): Y axis minimum value
/// - y-max (number,auto): Y axis maximum value
#let dendrogram(data,
                x1-key: 0,
                x2-key: 1,
                height-key: 2,
                size: auto,
                mode: "vertical",
                line-style: (stroke: black + 1pt),
                x-label: none,
                y-tick-step: auto,
                x-ticks: auto,
                y-ticks: (),
                y-unit: none,
                y-label: none,
                y-min: auto,
                y-max: auto,
                ) = {
  import draw: *

  assert(mode in dendrogram-modes,
    message: "Invalid dendrogram mode. Use: " + repr(dendrogram-modes))
  assert(type(x1-key) in (int, str),
    message: "Invalid x1-key type. Must be a integer or a string")
  assert(type(x2-key) in (int, str),
    message: "Invalid x2-key type. Must be a integer or a string")
  assert(type(height-key) in (int, str),
    message: "Invalid height-key type. Must be a integer or a string")

  if size == auto {
    if mode == "vertical" {size = (auto, 1)} 
    if mode == "horizontal" {size = (1, auto)}
  }

  let size-node-axis-index = 0
  if ( mode == "horizontal" ){size-node-axis-index = 1}

  if size.at(size-node-axis-index) == auto {
    size.at(size-node-axis-index) = (data.len() + 2)
  }

  let max-value = (if y-max != auto {y-max} else {calc.max(..data.map(data => data.at(height-key)))})
  let min-value = (if y-min != auto {y-min} else {calc.min(0, ..data.map(data => data.at(height-key)))})

  if x-ticks == auto {
    // Pre-calculate order of leaf indices
    let x-counter = 0
    let ticks = ()

    for (idx, entry) in data.enumerate() {
      let x1 = entry.at(x1-key)
      let x2 = entry.at(x2-key)

      // Only check relevent entries
      if  x1 < (data.len() + 2) {
        x-counter += 1
        ticks.push( (x-counter, x1) )
      }

      if x2 < (data.len() + 2) {
        x-counter = x-counter + 1
        ticks.push( (x-counter, x2) )
      }
    }

    x-ticks = ticks
  }

  let x = axes.axis(min: 0,
                    max: data.len() + 2,
                    label: x-label,
                    ticks: (list: x-ticks,
                            grid: none, step: none,
                            minor-step: none,
                    ))
  let y = axes.axis(min: min-value, max: max-value,
                    label: y-label,
                    ticks: (grid: true, step: y-tick-step,
                            minor-step: none,
                            unit: y-unit, decimals: 1,
                            list: y-ticks))

  // Calculates the (x,y) position of a leaf
  let get-xy(x-key, entry, x-array, x-counter, data-mut) = {

    // What we assume to be the leaf's x-coordinate
    let x = entry.at(x-key)

    // If the leaf is actually a cluster...
    if x > (data.len() + 1){

      // It starts at the height of that cluster, in its center
      let child = data-mut.at(x - 2)
      let x = child.at(x-key) // Center of cluster, memoized further down
      let y = child.at(height-key)
      return (x, y, false) // Return positions, don't increment counter

    // Otherwise, if it a starting leaf
    } else {

      // Check if this is the first time we are seeing this leaf
      let possible-id = x-array.at(x, default: false)
      if not possible-id {

        // Memoize it and return position
        x-array.insert(x, x-counter + 1)
        x = x-counter + 1
        return (x, 0, true) // Return position on x-axis, increment counter

      // therefore, we've seen it before
      } else {
        x = possible-id // so return memoized position
        return (possible-id, 0, false)
      }
    }
  }

  let basic-draw-dendrogram(data, ..style) = {

    // Allow palletes as linestyle
    let line-style = line-style;
    if type(line-style) != function { line-style = ((i) => line-style) }

    // Mutable variables
    let data-mut = data
    let x-counter = 0
    let x-array = (false,) * (data.len() + 1)

    // Main loop
    for (idx, entry) in data.enumerate() {
      // Calculate all the needed positions
      let height = entry.at(height-key)

      let (x1, y1, increment-x ) = get-xy(x1-key, entry, x-array, x-counter, data)
      if increment-x  { x-counter += 1 }

      let (x2, y2, increment-x ) = get-xy(x2-key, entry, x-array, x-counter, data)
      if increment-x { x-counter += 1 }

      // Calculate line segments
      let line-path = ((x1, y1), (x1, height), (x2, height), (x2, y2))
      
      // Reflect coordinates for horizontal mode
      if mode == "horizontal" {
        line-path=line-path.map( it => (it.at(1), it.at(0)) )
      }

      // Render line segments
      line(..line-path, ..style, ..line-style(idx))

      data.push((
        (x1 + x2) / 2,
        (x1 + x2) / 2,
        height
      ))
    }
  }

  let draw-data = (
    if mode in ("vertical", "horizontal") {basic-draw-dendrogram}
  )

  group(ctx => {

    // Setup axes
    let style = styles.resolve(ctx.style, default-style, root: "dendrogram")

    // If horizontal mode, reflect coordinates about y=x.
    let (x, y) = ( if mode == "vertical" {(x, y)} else {(y, x)} )

    axes.scientific(size: size,
                    left: y,
                    right: none,
                    bottom: x,
                    top: none,
                    frame: "set",
                    ..style.axes)

    // Render
    if data.len() > 0 {
      axes.axis-viewport(size, x, y, {draw-data(data)})
    }
  })
}
