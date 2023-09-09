/// Define a new palette
///
/// A palette is a function in the form `index -> style` that takes an
/// index (int) and returns a canvas style dictionary. If passed the
/// string `"len"` it must return the length of its styles.
///
/// - stroke (stroke): Single stroke style.
/// - fills (array): List of fill styles.
/// -> function
#let new(stroke, fills) = {
  if type(fills) != array {fills = (fills,)}
  (index) => {
    if index == "len" {return fills.len()}
    return (stroke: stroke,
            fill: fills.at(calc.rem(index, fills.len())))
  }
}

// List of predefined palettes
#let gray = new(black, range(90, 40, step: -12).map(v => luma(v * 1%)))
#let red = new(black, (rgb("#FFCCCC"), rgb("#FF9999"), rgb("#FF6666"),
                       rgb("#FF3333"), rgb("#CC0000")))
#let blue = new(black, (rgb("#BABAFF"), rgb("#9999FF"), rgb("#6666FF"),
                        rgb("#3333FF"), rgb("#0000CC")))
#let rainbow = new(black, (rgb("#9400D4"), rgb("#4B0082"), rgb("#0000FF"),
                           rgb("#00FF00"), rgb("#FFFF00"), rgb("#FF7F00"),
                           rgb("#FF0000")))
#let tango-light = new(black, ("fce94f", "fcaf3e", "e9b96e",
                               "8ae234", "729fcf", "ad7fa8",
                               "ef2929", "eeeeec", "888a85").map(s => rgb(s)))
#let tango = new(black, ("edd400", "f57900", "c17d11",
                         "73d216", "3465a4", "75507b",
                         "cc0000", "d3d7cf", "555753").map(s => rgb(s)))
#let tango-dark = new(black, ("c4a000", "ce5c00", "8f5902",
                              "4e9a06", "204a87", "5c3566",
                              "a40000", "babdb6", "2e3436").map(s => rgb(s)))
