#import "../axes.typ"
#import "../palette.typ"
#import "../../draw.typ"

#let dendrogram-default-style = (
  axes: (:)
)

// Valid dendrogram modes
#let dendrogram-modes = (
  "basic",
)

// Functions for max value calculation
#let dendrogram-max-value-fn = (
  basic: (data, value-key) => {
    calc.max(0, ..data.map(t => t.at(value-key)))
  },
)

// Functions for min value calculation
#let dendrogram-min-value-fn = (
  basic: (data, value-key) => {
    calc.min(0, ..data.map(t => t.at(value-key)))
  },
)

// TODO:

#let dendrogram(data,
                 x1-key: 0,
                 x2-key: 1,
                 height-key: 2,
                 mode: "basic",
                 size: (auto, 1),
                 line-style: (stroke: black + 1pt),
                 x-label: none,
                 x-tick-step: none,
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
      size.at(0) = (data.len() + 1)
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
                              grid: none, step: x-tick-step,
                              minor-step: none,
                      ))
    let y = axes.axis(min: min-value, max: max-value,
                      label: y-label,
                      ticks: (grid: true, step: y-tick-step,
                              minor-step: none,
                              unit: y-unit, decimals: 1,
                              list: y-ticks))

    let basic-draw-dendrogram(data, ..style) = {

        let data_mut = data // Mutable
        let line-style = line-style;
        if type(line-style) != function { line-style = ((i) => line-style) }
        
        for (idx, entry) in data.enumerate() {

            let height = entry.at(height-key)
            let x1 = entry.at(x1-key)
            let x2 = entry.at(x2-key)

            let y1 = 0
            let y2 = 0

            if ( x1 > (data.len()+1) ){
                let child = data_mut.at(x1 - 2)
                x1 = child.at(x1-key)
                y1 = child.at(height-key)
            }

            if ( x2 > (data.len())+1){
                let child = data_mut.at(x2 - 2)
                x2 = child.at(x1-key)
                y2 = child.at(height-key)
            }

            merge-path(
              line((x1, y1),(x1, height),(x2, height),(x2, y2)),
              ..style, ..line-style(idx))

            data_mut.push((
                (x1 + x2)/2,
                (x1 + x2)/2,
                height
            ))

        }

    }

    let draw-data = (
      if mode == "basic" {basic-draw-dendrogram}
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