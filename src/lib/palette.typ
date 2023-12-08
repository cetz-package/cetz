#let base-style = (stroke: (paint: black), fill: none)

/// Create a new palette based on a base style
///
/// #example(```
/// let p = cetz.palette.new(colors: (red, blue, green))
/// for i in range(0, p("len")) {
///   set-style(..p(i))
///   circle((0,0), radius: .5)
///   set-origin((1.1,0))
/// }
/// ```)
///
/// The functions returned by this function have the following named arguments:
/// #show-parameter-block("fill", ("bool"), default: true, [
///   If true, the returned fill color is one of the colors
///   from the `colors` list, otherwise the base styles fill is used.
/// ])
/// #show-parameter-block("stroke", ("bool"), default: false, [
///   If true, the returned stroke color is one of the colors
///   from the `colors` list, otherwise the base styles stroke color is used.
/// ])
///
/// You can use a palette for stroking via: `red.with(stroke: true)`.
///
/// - base (style): Style dictionary to use as base style for the styles generated
///   per color
/// - colors (none, array): List of colors the returned palette should return styles with
/// - dash (none, array): List of stroke dash patterns the returned palette should return styles with
///
/// -> function Palette function of the form `index => style` that returns a style for an integer index
#let new(base: base-style, colors: (), dash: ()) = {
  if not "stroke" in base { base.stroke = (paint: black, thickness: 1pt, dash: "solid") }
  if not "fill" in base { base.fill = none }

  let color-n = colors.len()
  let pattern-n = dash.len()
  return (index, fill: true, stroke: false) => {
    if index == "len" { return calc.max(color-n, pattern-n, 1) }

    let style = base
    if pattern-n > 0 {
      style.stroke.dash = dash.at(calc.rem(index, pattern-n))
    }
    if color-n > 0 {
      if stroke {
        style.stroke.paint = colors.at(calc.rem(index, color-n))
      }
      if fill {
        style.fill = colors.at(calc.rem(index, color-n))
      }
    }
    return style
  }
}

// Predefined color themes
#let tango-colors = (
  "edd400", "f57900", "c17d11",
  "73d216", "3465a4", "75507b",
  "cc0000", "d3d7cf", "555753").map(rgb)
#let tango-light-colors = (
  "fce94f", "fcaf3e", "e9b96e",
  "8ae234", "729fcf", "ad7fa8",
  "ef2929", "eeeeec", "888a85").map(rgb)
#let tango-dark-colors = (
  "c4a000", "ce5c00", "8f5902",
  "4e9a06", "204a87", "5c3566",
  "a40000", "babdb6", "2e3436").map(rgb)
#let rainbow-colors = (
  "#9400D4", "#4B0082", "#0000FF",
  "#00FF00", "#FFFF00", "#FF7F00",
  "#FF0000").map(rgb)

#let red-colors = (
  "#FFCCCC", "#FF9999", "#FF6666",
  "#FF3333", "#CC0000").map(rgb)
#let orange-colors = (
  "#FFE5CC", "#FFCC99", "#FFB266",
  "#FF9933", "#FF8000").map(rgb)
#let light-green-colors = (
  "#E5FFCC", "#CCFF99", "#B2FF66",
  "#99FF33", "#72E300", "#66CC00",
  "#55A800", "#478F00", "#3A7300",
  "#326300").map(rgb)
#let dark-green-colors = (
  "#80E874", "#5DD45D", "#3CC23C",
  "#009900", "#006E00").map(rgb)
#let turquoise-colors = (
  "#C0FFD3", "#99FFCC", "#66FFB2",
  "#33FF99", "#4BD691").map(rgb)
#let cyan-colors = (
  "#CCFFFF", "#99FFFF", "#66FFFF",
  "#00F3F3", "#00DADA").map(rgb)
#let blue-colors = (
  "#BABAFF", "#9999FF", "#6666FF",
  "#3333FF", "#0000CC").map(rgb)
#let indigo-colors = (
  "#BABAFF", "#9999FF", "#6666FF",
  "#3333FF", "#0000CC").map(rgb)
#let purple-colors = (
  "#E0C2FF", "#CC99FF", "#B266FF",
  "#9933FF", "#7F00FF").map(rgb)
#let magenta-colors = (
  "#FFD4FF", "#FF99FF", "#FF66FF",
  "#F331F3", "#DA00DA").map(rgb)
#let pink-colors = (
  "#FFCCE5", "#FF99CC", "#FF66B2",
  "#FF3399", "#F20C7F", "#DB006B",
  "#C30061", "#99004C", "#800040",
  "#660033").map(rgb)


// Predefined palettes
#let gray        = new(colors: range(90, 40, step: -12).map(v => luma(v * 1%)))

#let red         = new(colors: red-colors)
#let orange      = new(colors: orange-colors)
#let light-green = new(colors: light-green-colors)
#let dark-green  = new(colors: dark-green-colors)
#let turquoise   = new(colors: turquoise-colors)
#let cyan        = new(colors: cyan-colors)
#let blue        = new(colors: blue-colors)
#let indigo      = new(colors: indigo-colors)
#let purple      = new(colors: purple-colors)
#let magenta     = new(colors: magenta-colors)
#let pink        = new(colors: pink-colors)

#let rainbow     = new(colors: rainbow-colors)

#let tango       = new(colors: tango-colors)
#let tango-light = new(colors: tango-light-colors)
#let tango-dark  = new(colors: tango-dark-colors)
