// CeTZ Library for drawing charts

#import "axes.typ"
#import "palette.typ"
#import "../draw.typ"
#import "../util.typ"
#import "../styles.typ"

#import "chart/boxwhisker.typ": boxwhisker
#import "chart/barchart.typ": barchart
#import "chart/columnchart.typ": columnchart

// Styles


#let radarchart-default-style = (
  grid: (stroke: (paint: gray, dash: "dashed")),
  mark: (size: .075, stroke: none, fill: black),
  label-padding: .1,
)
