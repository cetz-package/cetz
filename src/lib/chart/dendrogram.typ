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
  "horizontal",
  "radial"
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
///                  - `"radial"` -- Radially displayed dendrogram
/// - size (array): Chart size as width and height tuple in canvas units;
///                 height can be set to `auto`.
/// - line-style (style,function): Style or function (idx => style) to use for
///                               each leaf, accepts a palette function.
/// - leaf-axis-label (content,none): Leaf axis label
/// - leaf-axis-ticks (array): List of tick values or value/label tuples
///
///                    *Example*
///                    
///                    `(1, 5, 10)` or `((1, [One]), (2, [Two]), (10, [Ten]))`
/// - height-axis-ticks (array): List of tick values or value/label tuples
///
///                    *Example*
///                    
///                    `(1, 5, 10)` or `((1, [One]), (2, [Two]), (10, [Ten]))`
/// - height-axis-unit (content,auto): Tick suffix added to each tick label
/// - height-axis-label (content,none): Height axis label
/// - height-axis-min (number,auto): Height-axis minimum value
/// - height-axis-max (number,auto): Height-axis maximum value
#let dendrogram(data,
                x1-key: 0,
                x2-key: 1,
                height-key: 2,
                size: auto,
                mode: "vertical",
                line-style: (stroke: black + 1pt),
                leaf-axis-label: none,
                leaf-axis-ticks: auto,
                height-axis-tick-step: auto,
                height-axis-ticks: (),
                height-axis-unit: none,
                height-axis-label: none,
                height-axis-min: auto,
                height-axis-max: auto,
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

  let max-value = (if height-axis-max != auto {height-axis-max} else {calc.max(..data.map(data => data.at(height-key)))})
  let min-value = (if height-axis-min != auto {height-axis-min} else {calc.min(0, ..data.map(data => data.at(height-key)))})

  if leaf-axis-ticks == auto {
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

    leaf-axis-ticks = ticks
  }

  let x = axes.axis(min: 0,
                    max: if mode == "radial" {max-value + 1} else {data.len() + 2},
                    label: leaf-axis-label,
                    ticks: (list: leaf-axis-ticks,
                            grid: none, step: none,
                            minor-step: none,
                    ))
  let y = axes.axis(min: min-value, max: max-value,
                    label: height-axis-label,
                    ticks: (grid: true, step: height-axis-tick-step,
                            minor-step: none,
                            unit: height-axis-unit, decimals: 1,
                            list: height-axis-ticks))

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

    let data-len = data.len()

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
      let x1 = entry.at(x1-key)
      let x2 = entry.at(x2-key)

      let (x1, y1, increment-x1) = get-xy(x1-key, entry, x-array, x-counter, data)
      if increment-x1  { x-counter += 1 }

      let (x2, y2, increment-x2) = get-xy(x2-key, entry, x-array, x-counter, data)
      if increment-x2 { x-counter += 1 }


      // Radialize coordinates for radial mode
      if mode == "radial" {
        let angle-scale =  ((calc.pi)) 

        // leaf-axis-ticks

        let draw-twig(x1, y1, height) = line(
          (angle: x1 / angle-scale, radius: max-value - y1),
          (angle: x1 / angle-scale, radius: max-value - height),
        )

        let draw-name(key, x) = {
          //if type(x) == int {
            let fgd = leaf-axis-ticks.filter(k=>{k.at(0)==x})
            if fgd.len() == 0 { return }
            content( 
              (angle: x / angle-scale, radius: max-value + 0.3),
              angle: (-x / angle-scale) * 1rad,
              anchor: "left",
              [#leaf-axis-ticks.filter(k=>{k.at(0)==x}).at(0).at(1)],
            )
        }

        merge-path({
          draw-twig(x1, y1, height)
          arc(
            (angle: x1 / angle-scale, radius: max-value - height),
            radius: max-value - height,
            start: (x1 / angle-scale) * 1rad,
            stop: (x2 / angle-scale) * 1rad,
          )
          draw-twig(x2, y2, height)
        }, ..style, ..line-style(idx))

        if increment-x1 {draw-name(x1-key, x1)}
        if increment-x2 {draw-name(x2-key, x2)}

      // Otherwise, for horizontal and vertical 
      } else {

        // Calculate line segments
        let line-path = ((x1, y1), (x1, height), (x2, height), (x2, y2))

        // Reflect coordinates for horizontal mode
        if mode == "horizontal" {
          line-path=line-path.map( it => (it.at(1), it.at(0)) )
        }

        // Render line segments
        line(..line-path, ..style, ..line-style(idx))

      }
    

      data.push((
        (x1 + x2) / 2,
        (x1 + x2) / 2,
        height
      ))
    }
  }

  group(ctx => {

    // Setup axes
    let style = styles.resolve(ctx.style, default-style, root: "dendrogram")

    // If horizontal mode, reflect coordinates about y=x.
    let (x, y) = ( if mode == "vertical" {(x, y)} else {(y, x)} )

    //if mode in ("vertical", "horizontal") {
      axes.scientific(
        size: size,
        left: y,
        right: none,
        bottom: x,
        top: none,
        frame: "set",
        ..style.axes)
    //}

    // Render
    if data.len() > 0 {
      axes.axis-viewport(size, x, y, {basic-draw-dendrogram(data)})
    }
  })
}
