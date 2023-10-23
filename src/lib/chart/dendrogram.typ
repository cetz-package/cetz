#import "../axes.typ"
#import "../palette.typ"
#import "../../draw.typ"

#let dendrogram-default-style = (
  axes: (:)
)

// Valid dendrogram modes
#let dendrogram-modes = (
  "vertical",
)

// Functions for max value calculation
#let dendrogram-max-value-fn = (
  vertical: (data, value-key) => {
    calc.max(0, ..data.map(t => t.at(value-key)))
  },
)

// Functions for min value calculation
#let dendrogram-min-value-fn = (
  vertical: (data, value-key) => {
    calc.min(0, ..data.map(t => t.at(value-key)))
  },
)

// TODO:

/// Draw a dendrogram. A dendrogram is a chat that relative distances higher
/// dimensional spaces. It if often used by data scientists in clustering
/// analyses.
///
/// *Style root*: `dendrogram`.
///
/// - data (array): Array of data rows, with each entry representing a leaf on
///                 the dendrogram.A row can be of type array or dictionary,
///                 with `x1-key`, `x2-key`, and `height-key` being the keys
///                 used to axcess a row's links and heights.
///
///                 *Example*
///                 ```typc
///                 ((1, 2, 0.5),(3, 4, 1),(6, 7, 2),(5, 8, 2.5))
///                 ```
/// - x1-key (int,string): Key to access the first cluster of a data row. This 
///                        key is used as argument to the rows `.at(..)` 
///                        function.
/// - x2-key (int,string): Key to access the second cluster of a data row. 
///                        This key is used as argument to the rows `.at(..)` 
///                        function.
/// - value-key (int,string): Key(s) to access value(s) of data row.
///                           These keys are used as argument to the
///                           rows `.at(..)` function.
/// - mode (string): Chart mode:
///                  - `"vertical"` -- Vertically displayed dendrogram
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
                 mode: "vertical",
                 size: (auto, 1),
                 line-style: (stroke: black + 1pt),
                 x-label: none,
                 y-tick-step: auto,
                 x-ticks: auto,
                 y-ticks: (),
                 y-unit: auto,
                 y-label: none,
                 y-min: auto,
                 y-max: auto,
                 ) = {
    import draw: *

    assert(mode in dendrogram-modes,message: "Invalid dendrogram mode")
    assert(type(x1-key) in (int, str))
    assert(type(x2-key) in (int, str))
    assert(type(height-key) in (int, str))

    if size.at(0) == auto {
      size.at(0) = (data.len() + 2)
    }

    let max-value = (dendrogram-max-value-fn.at(mode))(data, height-key)
    if y-max != auto {
      max-value = y-max
    }
    let min-value = (dendrogram-min-value-fn.at(mode))(data, height-key)
    if y-min != auto {
      min-value = y-min
    }

    let x-ticks = x-ticks
    if ( x-ticks == auto ){
        x-ticks = range(0, data.len()*2 - 1).map(it=>{
            (it, it)
        })
    }

    let y-unit = y-unit
    if y-unit == auto {
      y-unit = /*if mode == "stacked100" {[%]} else*/ []
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

    let vertical-draw-dendrogram(data, ..style) = {

        let data-mut = data // Mutable
        let line-style = line-style;
        if type(line-style) != function { line-style = ((i) => line-style) }
        
        for (idx, entry) in data.enumerate() {

            let height = entry.at(height-key)
            let x1 = entry.at(x1-key)
            let x2 = entry.at(x2-key)

            let y1 = 0
            let y2 = 0

            if ( x1 > (data.len()+1) ){
                let child = data-mut.at(x1 - 2)
                x1 = child.at(x1-key)
                y1 = child.at(height-key)
            }

            if ( x2 > (data.len())+1){
                let child = data-mut.at(x2 - 2)
                x2 = child.at(x1-key)
                y2 = child.at(height-key)
            }

            merge-path(
              line((x1, y1),(x1, height),(x2, height),(x2, y2)),
              ..style, ..line-style(idx))

            data-mut.push((
                (x1 + x2)/2,
                (x1 + x2)/2,
                height
            ))

        }

    }

    let draw-data = (
      if mode == "vertical" {vertical-draw-dendrogram}
    )

    group(ctx => {
      let style = util.merge-dictionary(dendrogram-default-style,
        styles.resolve(ctx.style, (:), root: "dendrogram"))

      axes.scientific(size: size,
                      left: y,
                      right: none,
                      bottom: x,
                      top: none,
                      frame: "set",
                      ..style.axes)
      if data.len() > 0 {

        axes.axis-viewport(size, x, y, {
            draw-data(data)
        })
      }
    })
}