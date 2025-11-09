#let colors = (
  "any": rgb("#eff0f3"),
  "content": rgb("#a6ebe6"),
  "string": rgb("#d1ffe2"),
  "str": rgb("#d1ffe2"),
  "none": rgb("#ffcbc4"),
  "auto": rgb("#ffcbc4"),
  "bool": rgb("#ffedc1"),
  "boolean": rgb("#ffedc1"),
  "integer": rgb("#e7d9ff"),
  "int": rgb("#e7d9ff"),
  "float": rgb("#e7d9ff"),
  "ratio": rgb("#e7d9ff"),
  "length": rgb("#e7d9ff"),
  "angle": rgb("#e7d9ff"),
  "relative length": rgb("#e7d9ff"),
  "relative": rgb("#e7d9ff"),
  "fraction": rgb("#e7d9ff"),
  "function": rgb("#f9dfff"),
)

#let show-type(name) = {
  box(raw(name), inset: 2pt, baseline: 2pt, radius: 2pt,
    fill: colors.at(name, default: colors.at("any")), stroke: none)
}
