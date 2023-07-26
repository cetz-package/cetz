// Define a new palette
//
// A palette is a function that takes an index (int) and returns
// a CeTZ style dictionary
//
// - stroke (stroke): Stroke
// - fills   (array): List of fill colors
#let new(stroke, fills) = {
  if type(fills) != "array" {fills = (fills,)}
  (index) => {
    return (stroke: stroke,
            fill: fills.at(calc.rem(index, fills.len())))
  }
}

// List of predefined palettes
#let red = new(black, (rgb("#FFCCCC"), rgb("#FF9999"), rgb("#FF6666"),
                       rgb("#FF3333"), rgb("#CC0000")))
#let blue = new(black, (rgb("#BABAFF"), rgb("#9999FF"), rgb("#6666FF"),
                        rgb("#3333FF"), rgb("#0000CC")))
#let rainbow = new(black, (rgb("#9400D4"), rgb("#4B0082"), rgb("#0000FF"),
                           rgb("#00FF00"), rgb("#FFFF00"), rgb("#FF7F00"),
                           rgb("#FF0000")))
