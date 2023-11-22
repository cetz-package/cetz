#import "doc/util.typ": *
#import "doc/example.typ": example
#import "doc/style.typ" as doc-style

#import "src/lib.typ": *
#import "src/styles.typ"
#import "@preview/tidy:0.1.0"


// Usage:
//   ```example
//   /* canvas drawing code */
//   ```
#show raw.where(lang: "example"): text => {
  example(text.text)
}
#show raw.where(lang: "example-vertical"): text => {
  example(text.text, vertical: true)
}



#make-title()

#set terms(indent: 1em)
#set par(justify: true)
#set heading(numbering: (..num) => if num.pos().len() < 4 {
    numbering("1.1", ..num)
  })
#show link: set text(blue)


// Outline
#{
  show heading: none
  columns(2, outline(indent: true, depth: 3))
  pagebreak(weak: true)
}

#set page(numbering: "1/1", header: align(right)[CeTZ])

= Introduction

This package provides a way to draw stuff using a similar API to #link("https://processing.org/")[Processing] but with relative coordinates and anchors from #link("https://tikz.dev/")[Ti#[_k_]Z]. You also won't have to worry about accidentally drawing over other content as the canvas will automatically resize. And remember: up is positive!

The name CeTZ is a recursive acronym for "CeTZ, ein Typst Zeichenpacket" (german for "CeTZ, a Typst drawing package") and is pronounced like the word "Cats".

= Usage

This is the minimal starting point:
#pad(left: 1em)[```typ
#import "@preview/cetz:0.2.0"
#cetz.canvas({
  import cetz.draw: *
  ...
})
```]
Note that draw functions are imported inside the scope of the `canvas` block. This is recommended as draw functions override Typst's functions such as `line`.

#show raw.where(block: false): it => if it.text.starts-with("<") and it.text.ends-with(">") {
    set text(1.2em)
    doc-style.show-type(it.text.slice(1, -1))
  } else { 
    it 
  }

== CeTZ Unique Argument Types
Many CeTZ functions expect data in certain formats which we will call types. Note that these are actually made up of Typst primitives.
  / `<coordinate>`: Any coordinate system. See coordinate-systems.
  / `<number>`: Any of `<float>`, `<integer>` or `<length>`. 
  / `<style>`: Named arguments (or a dictionary if used for a single argument) of style key-values

== Anchors <anchors>
Anchors are named positions relative to named elements. To use an anchor of an element, you must give the element a name using the `name` argument. All elements with the `name` argument allow anchors.
```example
// Name the circle
circle((0,0), name: "circle")

// Draw a smaller red circle at "circle"'s east anchor
fill(red)
stroke(none)
circle("circle.east", radius: 0.3)
```

Elements can be placed relative to their own anchors if they have an
argument called `anchor`:
```example
// An element does not have to be named 
// in order to use its own anchors.
circle((0,0), anchor: "west")

// Draw a smaller red circle at the origin
fill(red)
stroke(none)
circle((0,0), radius: 0.3)
```

=== Compass Anchors
Some elements support compass anchors. TODO
#align(center, {
  canvas({
    import draw:*
    group({
      rect((-1, -1), (1, 1))
    }, name: "group")
    for-each-anchor("group", n => {
      if n != "center" {
        content(
          (rel: ("group.center", .75, "group." + n),
           to: "group." + n), n)
      } else {
        content((rel: (0, .5), to: "group.center"), n)
      }
      circle("group." + n, radius: .1, fill: black)
    })
  })
})

= Draw Function Reference

== Canvas
```typc
canvas(background: none, length: 1cm, debug: false, body)
```
#def-arg("background", `<color>`, default: "none", "A color to be used for the background of the canvas.")
#def-arg("length", `<length>`, default: "1cm", "Used to specify what 1 coordinate unit is.")
#def-arg("debug", `<bool>`, default: "false", "Shows the bounding boxes of each element when `true`.")
#def-arg("body", none, [A code block in which functions from `draw.typ` have been called.])

== Styling <styling>
You can style draw elements by passing the relevant named arguments to their draw functions. All elements that draw something have stroke and fill styling unless said otherwise.

#doc-style.show-parameter-block("fill", ("color", "none"), default: none, [How to fill the drawn element.])
#doc-style.show-parameter-block("stroke", ("none", "auto", "length", "color", "dictionary", "stroke"), default: black + 1pt, [How to stroke the border or the path of the draw element. See Typst's line documentation for more details: https://typst.app/docs/reference/visualize/line/#parameters-stroke])

```example
// Draws a red circle with a blue border
circle((0, 0), fill: red, stroke: blue)
// Draws a green line
line((0, 0), (1, 1), stroke: green)
```

Instead of having to specify the same styling for each time you want to draw an element, you can use the `set-style` function to change the style for all elements after it. You can still pass styling to a draw function to override what has been set with `set-style`. You can also use the `fill()` and `stroke()` functions as a shorthand to set the fill and stroke respectively.

```example
// Draws an empty square with a black border
rect((-1, -1), (1, 1))

// Sets the global style to have a fill of red and a stroke of blue
set-style(stroke: blue, fill: red)
circle((0,0))

// Draws a green line despite the global stroke is blue
line((), (1,1), stroke: green)
```

When using a dictionary for a style, it is important to note that they update each other instead of overriding the entire option like a non-dictionary value would do. For example, if the stroke is set to `(paint: red, thickness: 5pt)` and you pass `(paint: blue)`, the stroke would become `(paint: blue, thickness: 5pt)`.

```example
// Sets the stroke to red with a thickness of 5pt
set-style(stroke: (paint: red, thickness: 5pt))
// Draws a line with the global stroke
line((0,0), (1,0))
// Draws a blue line with a thickness of 5pt because dictionaries update the style
line((0,0), (1,1), stroke: (paint: blue))
// Draws a yellow line with a thickness of 1pt because other values override the style
line((0,0), (0,1), stroke: yellow)
```

You can also specify styling for each type of element. Note that dictionary values will still update with its global value, the full hierarchy is `function > element type > global`. When the value of a style is `auto`, it will become exactly its parent style.

```example
set-style(
  // Global fill and stroke
  fill: green,
  stroke: (thickness: 5pt),
  // Stroke and fill for only rectangles
  rect: (stroke: (dash: "dashed"), fill: blue), 
)
rect((0,0), (1,1))
circle((0.5, -1.5))
rect((0,-3), (1, -4), stroke: (thickness: 1pt))
```

```example
// Its a nice drawing okay
set-style(
  rect: (
    fill: red,
    stroke: none
  ),
  line: (
    fill: blue,
    stroke: (dash: "dashed")
  ),
)
rect((0,0), (1,1))

line((0, -1.5), (0.5, -0.5), (1, -1.5), close: true)

circle((0.5, -2.5), radius: 0.5, fill: green)
```

#pagebreak()
== Shapes
#doc-style.parse-show-module("/src/draw/shapes.typ")

#pagebreak()
== Grouping
#doc-style.parse-show-module("/src/draw/grouping.typ")

#pagebreak()
== Transformations
All transformation functions push a transformation matrix onto the current transform stack. To apply transformations scoped use a `group(...)` object.

Transformation matrices get multiplied in the following order:
$ M_"world" = M_"world" dot M_"local" $

#doc-style.parse-show-module("/src/draw/transformations.typ")

= Coordinate Systems <coordinate-systems>
A _coordinate_ is a position on the canvas on which the picture is drawn. They take the form of dictionaries and the following sub-sections define the key value pairs for each system. Some systems have a more implicit form as an array of values and `CeTZ` attempts to infer the system based on the element types.


== XYZ <coordinate-xyz>
Defines a point `x` units right, `y` units upward, and `z` units away.

#def-arg("x", [`<number>` or `<length>`], default: 0, [The number of units in the `x` direction.])
#def-arg("y", [`<number>` or `<length>`], default: 0, [The number of units in the `y` direction.])
#def-arg("z", [`<number>` or `<length>`], default: 0, [The number of units in the `z` direction.])

The implicit form can be given as an array of two or three `<number>` or `<length>`, as in `(x,y)` and `(x,y,z)`.

```example
line((0,0), (x: 1))
line((0,0), (y: 1))
line((0,0), (z: 1))

// Implicit form
line((0, -2), (1, -2))
line((0, -2), (0, -1, 0))
line((0, -2), (0, -2, 1))
```

== Previous <previous>
Use this to reference the position of the previous coordinate passed to a draw function. This will never reference the position of a coordinate used in to define another coordinate. It takes the form of an empty array `()`. The previous position initially will be `(0, 0, 0)`.

```example
line((0,0), (1, 1))

// Draws a circle at (1,1)
circle(())
```

== Relative <coordinate-relative>
Places the given coordinate relative to the previous coordinate. Or in other words, for the given coordinate, the previous coordinate will be used as the origin. Another coordinate can be given to act as the previous coordinate instead.

#def-arg("rel", `<coordinate>`, "The coordinate to be place relative to the previous coordinate.")
#def-arg("update", `<bool>`, default: true, "When false the previous position will not be updated.")
#def-arg("to", `<coordinate>`, default: (), "The coordinate to treat as the previous coordinate.")

In the example below, the red circle is placed one unit below the blue circle. If the blue circle was to be moved to a different position, the red circle will move with the blue circle to stay one unit below.

```example
circle((0, 0), stroke: blue)
circle((rel: (0, -1)), stroke: red)
```

== Polar
Defines a point a `radius` distance away from the origin at the given `angle`.

#def-arg("angle", `<angle>`, [The angle of the coordinate. An angle of `0deg` is to the right, a degree of `90deg` is upward. See https://typst.app/docs/reference/layout/angle/ for details.])
#def-arg("radius", `<number> or <length> or <array of length or number>`, [The distance from the origin. An array can be given, in the form `(x, y)` to define the `x` and `y` radii of an ellipse instead of a circle.])

```example
line((0,0), (angle: 30deg, radius: 1cm))
```

The implicit form is an array of the angle then the radius `(angle, radius)` or `(angle, (x, y))`. 

```example
line((0,0), (30deg, 1), (60deg, 1), 
     (90deg, 1), (120deg, 1), (150deg, 1), (180deg, 1))
```

== Barycentric
In the barycentric coordinate system a point is expressed as the linear combination of multiple vectors. The idea is that you specify vectors $v_1$, $v_2$ ..., $v_n$ and numbers $alpha_1$, $alpha_2$, ..., $alpha_n$. Then the barycentric coordinate specified by these vectors and numbers is $ (alpha_1 v_1 + alpha_2 v_1 + dots.c + alpha_n v_n)/(alpha_1 + alpha_2 + dots.c + alpha_n) $

#def-arg("bary", `<dictionary>`, [A dictionary where the key is a named element and the value is a `<float>`. The `center` anchor of the named element is used as $v$ and the value is used as $a$.])

```example
circle((90deg, 3), radius: 0, name: "content")
circle((210deg, 3), radius: 0, name: "structure")
circle((-30deg, 3), radius: 0, name: "form")

for (c, a) in (
  ("content", "south"),
  ("structure", "north-west"),
  ("form", "north-east")
) {
  content(c, box(c + " oriented", inset: 5pt), anchor: a)
}

stroke(gray + 1.2pt)
line("content", "structure", "form", close: true)

for (c, s, f, cont) in (
  (0.5, 0.1, 1, "PostScript"),
  (1, 0, 0.4, "DVI"),
  (0.5, 0.5, 1, "PDF"),
  (0, 0.25, 1, "CSS"),
  (0.5, 1, 0, "XML"),
  (0.5, 1, 0.4, "HTML"),
  (1, 0.2, 0.8, "LaTeX"),
  (1, 0.6, 0.8, "TeX"),
  (0.8, 0.8, 1, "Word"),
  (1, 0.05, 0.05, "ASCII")
) {
  content((bary: (content: c, structure: s, form: f)), cont)
}
```

== Anchor
Defines a point relative to a named element using anchors, see @anchors.

#def-arg("name", `<string>`, [The name of the element that you wish to use to specify a coordinate.])
#def-arg("anchor", `<string>`, [An anchor of the element. If one is not given a default anchor will be used. On most elements this is `center` but it can be different.])

You can also use implicit syntax of a dot separated string in the form `"name.anchor"`.

```example
line((0,0), (3,2), name: "line")
circle("line.end", name: "circle")
rect("line.start", "circle.east")
```

== Tangent
This system allows you to compute the point that lies tangent to a shape. In detail, consider an element and a point. Now draw a straight line from the point so that it "touches" the element (more formally, so that it is _tangent_ to this element). The point where the line touches the shape is the point referred to by this coordinate system.

#def-arg("element", `<string>`, [The name of the element on whose border the tangent should lie.])
#def-arg("point", `<coordinate>`, [The point through which the tangent should go.])
#def-arg("solution", `<integer>`, [Which solution should be used if there are more than one.])

A special algorithm is needed in order to compute the tangent for a given shape. Currently it does this by assuming the distance between the center and top anchor (See @anchors) is the radius of a circle. 

```example
grid((0,0), (3,2), help-lines: true)

circle((3,2), name: "a", radius: 2pt)
circle((1,1), name: "c", radius: 0.75)
content("c", $ c $, anchor: "north-east", padding: .1)

stroke(red)
line("a", (element: "c", point: "a", solution: 1),
     "c", (element: "c", point: "a", solution: 2),
     close: true)
```

== Perpendicular
Can be used to find the intersection of a vertical line going through a point $p$ and a horizontal line going through some other point $q$.

#def-arg("horizontal", `<coordinate>`, [The coordinate through which the horizontal line passes.])
#def-arg("vertical", `<coordinate>`, [The coordinate through which the vertical line passes.])

You can use the implicit syntax of `(horizontal, "-|", vertical)` or `(vertical, "|-", horizontal)`

```example
set-style(content: (padding: .05))
content((30deg, 1), $ p_1 $, name: "p1")
content((75deg, 1), $ p_2 $, name: "p2")

line((-0.2, 0), (1.2, 0), name: "xline")
content("xline.end", $ q_1 $, anchor: "west")
line((2, -0.2), (2, 1.2), name: "yline")
content("yline.end", $ q_2 $, anchor: "south")

line("p1.south-east", (horizontal: (), vertical: "xline.end"))
line("p2.south-east", ((), "|-", "xline.end")) // Short form
line("p1.south-east", (vertical: (), horizontal: "yline.end"))
line("p2.south-east", ((), "-|", "yline.end")) // Short form
```

== Interpolation <coordinate-lerp>
Use this to linearly interpolate between two coordinates `a` and `b` with a given factor `number`. If `number` is a `<length>` the position will be at the given distance away from `a` towards `b`. 
An angle can also be given for the general meaning: "First consider the line from `a` to `b`. Then rotate this line by `angle` around point `a`. Then the two endpoints of this line will be `a` and some point `c`. Use this point `c` for the subsequent computation."

#def-arg("a", `<coordinate>`, [The coordinate to interpolate from.])
#def-arg("b", `<coordinate>`, [The coordinate to interpolate to.])
#def-arg("number", [`<number>` or `<length>`], [
  The factor to interpolate by or the distance away from `a` towards `b`.
])
#def-arg("angle", `<angle>`, default: 0deg, "")
#def-arg("abs", `<bool>`, default: false, [
  Interpret `number` as absolute distance, instead of a factor.
])

Can be used implicitly as an array in the form `(a, number, b)` or `(a, number, angle, b)`.

```example
grid((0,0), (3,3), help-lines: true)

line((0,0), (2,2))
for i in (0, 0.2, 0.5, 0.8, 1, 1.5) { /* Relative distance */
  content(((0,0), i, (2,2)),
          box(fill: white, inset: 1pt, [#i]))
}

line((1,0), (3,2))
for i in (0, 0.5, 1, 2) { /* Absolute distance */
  content((a: (1,0), number: i, abs: true, b: (3,2)),
          box(fill: white, inset: 1pt, text(red, [#i])))
}
```

```example
grid((0,0), (3,3), help-lines: true)
line((1,0), (3,2))
line((1,0), ((1, 0), 1, 10deg, (3,2)))
fill(red)
stroke(none)
circle(((1, 0), 0.5, 10deg, (3, 2)), radius: 2pt)
```

```example
grid((0,0), (4,4), help-lines: true)

fill(black)
stroke(none)
let n = 16
for i in range(0, n+1) {
  circle(((2,2), i / 8, i * 22.5deg, (3,2)), radius: 2pt)
}
```

You can even chain them together!

```example
grid((0,0), (3, 2), help-lines: true)
line((0,0), (3,2))
stroke(red)
line(((0,0), 0.3, (3,2)), (3,0))
fill(red)
stroke(none)
circle(
  ( // a
    (((0, 0), 0.3, (3, 2))),
    0.7,
    (3,0)
  ),
  radius: 2pt
)
```

```example
grid((0,0), (3, 2), help-lines: true)
line((1,0), (3,2))
for (l, c) in ((0cm, "0cm"), (1cm, "1cm"), (15mm, "15mm")) {
  content(((1,0), l, (3,2)), box(fill: white, $ #c $))
}
```

== Function
An array where the first element is a function and the rest are coordinates will cause the function to be called with the resolved coordinates. The resolved coordinates have the same format as the implicit form of the 3-D XYZ coordinate system, @coordinate-xyz.

The example below shows how to use this system to create an offset from an anchor, however this could easily be replaced with a relative coordinate with the `to` argument set, @coordinate-relative.

```example
circle((0, 0), name: "c")
fill(red)
circle((v => cetz.vector.add(v, (0, -1)), "c.west"), radius: 0.3)
```

#pagebreak()

= Libraries

== Tree
The tree library allows the drawing diagrams with simple tree layout algorithms

#doc-style.parse-show-module("/src/lib/tree.typ")

=== Node <tree-node>

A tree node is an array of nodes. The first array item represents the
current node, all following items are direct children of that node.
The node itselfes can be of type `content` or `dictionary` with a key `content`.

== Plot

The library `plot` of CeTZ allows plotting 2D data.

=== Types

Types commonly used by function of the `plot` library:
/ `domain`: Tuple representing a functions domain as closed interval.
            Example domains are: `(0, 1)` for $[0, 1]$ or
            `(-calc.pi, calc.pi)` for $[-pi, pi]$.
/ `axes`: Tuple of axis names. Plotting functions taking an `axes` tuple
  will use those axes as their `x` and `y` axis for plotting.
  To rotate a plot, you can simply swap its axes, for example `("y", "x")`.

#doc-style.parse-show-module("/src/lib/plot.typ")
#doc-style.parse-show-module("/src/lib/plot/line.typ")
#doc-style.parse-show-module("/src/lib/plot/contour.typ")
#doc-style.parse-show-module("/src/lib/plot/boxwhisker.typ")
#doc-style.parse-show-module("/src/lib/plot/sample.typ")

=== Examples

```example
import cetz.plot
plot.plot(size: (3,2), x-tick-step: 180, y-tick-step: 1,
          x-unit: $degree$, {
  plot.add(domain: (0, 360), x => calc.sin(x * 1deg))
})
```

```example
import cetz.plot
plot.plot(size: (3,2), x-tick-step: 180, y-tick-step: 1,
          x-unit: $degree$, y-max: .5, {
  plot.add(domain: (0, 360), x => calc.sin(x * 1deg))
  plot.add(domain: (0, 360), x => calc.cos(x * 1deg),
           samples: 10, mark: "x", style: (mark: (stroke: blue)))
})
```

```example
import cetz.plot
import cetz.palette

// Axes can be styled!
// Set the tick length to .1:
set-style(axes: (tick: (length: .1)))

// Plot something
plot.plot(size: (3,3), x-tick-step: 1, axis-style: "left", {
  for i in range(0, 3) {
    plot.add(domain: (-4, 2),
      x => calc.exp(-(calc.pow(x + i, 2))),
      fill: true, style: palette.tango)
  }
})
```

```example
import cetz.plot
plot.plot(size: (3,2), x-tick-step: 1, y-tick-step: 1, {
  let z(x, y) = {
    (1 - x/2 + calc.pow(x,5) + calc.pow(y,3)) * calc.exp(-(x*x) - (y*y))
  }
  plot.add-contour(x-domain: (-2, 3), y-domain: (-3, 3),
                   z, z: (.1, .4, .7), fill: true)
})
```

=== Styling <plot.style>

The following style keys can be used (in addition to the standard keys)
to style plot axes. Individual axes can be styled differently by
using their axis name as key below the `axes` root.

```typc
set-style(axes: ( /* Style for all axes */ ))
set-style(axes: (bottom: ( /* Style axis "bottom" */)))
```

Axis names to be used for styling:
- School-Book and Left style:
  - `x`: X-Axis
  - `y`: Y-Axis
- Scientific style:
  - `left`: Y-Axis
  - `right`: Y2-Axis
  - `bottom`: X-Axis
  - `top`: X2-Axis

==== Default `scientific` Style
#raw(repr(axes.default-style))

==== Default `school-book` Style
#raw(repr(axes.default-style-schoolbook))

== Chart
#let chart-module = tidy.parse-module(read("src/lib/chart.typ"), name: "Chart")
#let chart-boxwhisker-module = tidy.parse-module(read("src/lib/chart/boxwhisker.typ"), name: "Chart - Boxwhisker")

With the `chart` library it is easy to draw charts.

Supported charts are:
- `barchart(..)` and `columnchart(..)`: A chart with horizontal/vertical growing bars
  - `mode: "basic"`: (default): One bar per data row
  - `mode: "clustered"`: Multiple grouped bars per data row
  - `mode: "stacked"`: Multiple stacked bars per data row
  - `mode: "stacked100"`: Multiple stacked bars relative to the sum of a data row
- `boxwhisker(..)`: A box-plot chart

#tidy.show-module(chart-module, show-module-name: false)

=== Examples -- Bar Chart <barchart-examples>

```example-vertical
import cetz.chart
// Left - Basic
let data = (("A", 10), ("B", 20), ("C", 13))
group(name: "a", {
  chart.barchart(size: (4, 3), data)
})
// Center - Clustered
let data = (("A", 10, 12, 22), ("B", 20, 1, 7), ("C", 13, 8, 9))
set-origin("a.south-east")
group(name: "b", anchor: "south-west", {
  anchor("center", (0,0))
  chart.barchart(size: (4, 3), mode: "clustered", value-key: (1,2,3), data)
})
// Right - Stacked
let data = (("A", 10, 12, 22), ("B", 20, 1, 7), ("C", 13, 8, 9))
set-origin("b.south-east")
group(name: "c", anchor: "south-west", {
  anchor("center", (0,0))
  chart.barchart(size: (4, 3), mode: "stacked", value-key: (1,2,3), data)
})
```

=== Examples -- Column Chart <columnchart-examples>

==== Basic, Clustered and Stacked
```example-vertical
import cetz.chart
// Left - Basic
let data = (("A", 10), ("B", 20), ("C", 13))
group(name: "a", {
  chart.columnchart(size: (4, 3), data)
})
// Center - Clustered
let data = (("A", 10, 12, 22), ("B", 20, 1, 7), ("C", 13, 8, 9))
set-origin("a.south-east")
group(name: "b", anchor: "south-west", {
  anchor("center", (0,0))
  chart.columnchart(size: (4, 3), mode: "clustered", value-key: (1,2,3), data)
})
// Right - Stacked
let data = (("A", 10, 12, 22), ("B", 20, 1, 7), ("C", 13, 8, 9))
set-origin("b.south-east")
group(name: "c", anchor: "south-west", {
  anchor("center", (0,0))
  chart.columnchart(size: (4, 3), mode: "stacked", value-key: (1,2,3), data)
})
```

#tidy.show-module(chart-boxwhisker-module, show-module-name: false)

=== Styling

Charts share their axis system with plots and therefore can be
styled the same way, see @plot.style.

==== Default `barchart` Style
#raw(repr(chart.barchart-default-style))

==== Default `columnchart` Style
#raw(repr(chart.columnchart-default-style))

==== Default `boxwhisker` Style
#raw(repr(chart.boxwhisker-default-style))

== Palette <palette>
#let palette-module = tidy.parse-module(read("src/lib/palette.typ"), name: "Palette")

A palette is a function that returns a style for an index.
The palette library provides some predefined palettes.

#tidy.show-module(palette-module, show-module-name: false)

#let show-palette(p) = {
  canvas({
    import draw: *
    for i in range(p("len")) {
      if calc.rem(i, 10) == 0 { move-to((rel: (0, -.5))) }
      rect((), (rel: (1,.5)), name: "r", ..p(i))
      move-to("r.south-west")
    }
  })
} 

=== List of predefined palettes
- `gray` #show-palette(palette.gray)
- `red` #show-palette(palette.red)
- `blue` #show-palette(palette.blue)
- `rainbow` #show-palette(palette.rainbow)
- `tango-light` #show-palette(palette.tango-light)
- `tango` #show-palette(palette.tango)
- `tango-dark` #show-palette(palette.tango-dark)

== Angle <angle>
#let angle-module = tidy.parse-module(read("src/lib/angle.typ"), name: "Angle")

The `angle` function of the angle module allows drawing angles with an optional label.

#tidy.show-module(angle-module, show-module-name: false)

```example
import cetz.angle: angle
let (a, b, c) = ((0,0), (-1,1), (1.5,0))
line(a, b)
line(a, c)
set-style(angle: (radius: 1, label-radius: .5), stroke: blue)
angle(a, c, b, label: $alpha$, mark: (end: ">"), stroke: blue)
set-style(stroke: red)
angle(a, b, c, label: n => $#{n/1deg} degree$,
  mark: (end: ">"), stroke: red, inner: false)
```

==== Default `angle` Style
#raw(repr(angle.default-style))
/*
== Decorations <decorations>
// #let decorations-module = tidy.parse-module(read("src/lib/decorations.typ"), name: "Decorations")

Various pre-made shapes and lines.

// #show-module-fn(decorations-module, "brace")
```example
import cetz.decorations: brace
let text = text.with(size: 12pt, font: "Linux Libertine")

brace((0, 0), (4, -.5), pointiness: 25deg, outer-pointiness: auto, amplitude: .8, debug: true)
brace((0, -.5), (0, -3.5), name: "brace")
content("brace.content", [$P_1$])

// styling can be passed to the underlying `merge-path` call
brace((1, -3), (4, -3), amplitude: 1, pointiness: .5, stroke: orange + 2pt, fill: maroon, close: true, name: "saloon")
content((rel: (0, -.15), to: "saloon.center"), text(fill: orange, smallcaps[*Saloon*]))

// as part of another path
set-origin((2, -5))
merge-path({
  brace((+1, .5), (+1, -.5), amplitude: .3, pointiness: .5)
  brace((-1, -.5), (-1, .5), amplitude: .3, pointiness: .5)
}, fill: white, close: true)
content((0, 0), text(size: 10pt)[Hello, World!])

brace((-1.5, -2.5), (2, -2.5), pointiness: 1, outer-pointiness: 1, stroke: olive, fill: green, name: "hill")
content((rel: (.3, .1), to: "hill.center"), text[*εїз*])
```

==== Styling

#def-arg("amplitude", `<number>`, default: .7, [Determines how much the brace rises above the base line.])
#def-arg("pointiness", `<number> or <angle>`, default: 15deg, [How pointy the spike should be. #0deg or `0` for maximum pointiness, #90deg or `1` for minimum.])
#def-arg("outer-pointiness", `<number> or <angle> or <auto>`, default: 0, [How pointy the outer edges should be. #0deg or `0` for maximum pointiness (allowing for a smooth transition to a straight line), #90deg or `1` for minimum. Setting this to #auto will use the value set for `pointiness`.])
#def-arg("content-offset", `<number>`, default: .3, [Offset of the `content` anchor from the spike.])
#def-arg("debug-text-size", `<length>`, default: 6pt, [Font size of displayed debug points when `debug` is #true.])

==== Default `brace` Style
#decorations.brace-default-style

#show-module-fn(decorations-module, "flat-brace")
```example
import cetz.decorations: flat-brace

flat-brace((), (x: 5))
flat-brace((0, 0), (5, 0), flip: true, aspect: .3)
flat-brace((), (rel: (-2, -1)), name: "a")
flat-brace((), (0, 0), amplitude: 1, curves: 1.5, outer-curves: .5)
content("a.content", [$P_2$])

flat-brace((0, -3), (5, -3), debug: true, amplitude: 1, aspect: .4, curves: (1.5, .9, 1, .1), outer-curves: (1, .3, .1, .7))

// triangle and square braces
flat-brace((0, -4), (2.4, -4), curves: (auto, 0, 0, 0))
flat-brace((2.6, -4), (5, -4), curves: 0)

merge-path(close: true, fill: white, {
  move-to((.5, -6))
  flat-brace((), (rel: (1, 1)))
  flat-brace((), (rel: (2, 0)), flip: true, name: "top")
  flat-brace((), (rel: (1, -1)))
  flat-brace((), (rel: (-1, -1)))
  flat-brace((), (rel: (-2, 0)), flip: true, name: "bottom")
  flat-brace((), (rel: (-1, 1)))
})
content(("top.spike", .5, "bottom.spike"), [Hello, World!])
```

==== Styling

#def-arg("amplitude", `<number>`, default: decorations.flat-brace-default-style.amplitude, [Determines how much the brace rises above the base line.])
#def-arg("aspect", `<number>`, default: decorations.flat-brace-default-style.aspect, [Determines the fraction of the total length where the spike will be placed.])
#block(breakable: false, def-arg("curves", `<array> or <number>`, default: decorations.flat-brace-default-style.curves, [
  Customizes the control points of the curved parts.
  Setting a single number is the same as setting ```typc (num, auto, auto, auto)```.
  Setting any item to #auto will use its default value.
  The first item specifies the curve widths as a fraction of the amplitude.
  The second item specifies the length of the green and blue debug lines as a fraction of the curve's width.
  The third item specifies the vertical offset of the red and purple debug lines as a fraction of the curve's height.
  The fourth item specifies the horizontal offset of the red and purple debug lines as a fraction of the curve's width.
]))
#def-arg("outer-curves", `<array> or <number> or <auto>`, default: decorations.flat-brace-default-style.outer-curves, [
  Customizes the control points of just the outer two curves (just the blue and purple debug lines).
  Overrides settings from `curves`.
  Setting the entire value or individual items to #auto uses the values from `curves` as fallbacks.
])
#def-arg("content-offset", `<number>`, default: decorations.flat-brace-default-style.content-offset, [Offset of the `content` anchor from the spike.])
#def-arg("debug-text-size", `<length>`, default: decorations.flat-brace-default-style.debug-text-size, [Font size of displayed debug points when `debug` is #true.])

==== Default `flat-brace` Style
#decorations.flat-brace-default-style

= Advanced Functions

== Coordinate

#let coord-module = tidy.parse-module(read("src/coordinate.typ"), name: "Coordinate")
#show-module-fn(coord-module, "resolve")

```example
line((0,0), (1,1), name: "l")
get-ctx(ctx => {
  // Get the vector of coordinate "l.start"
  content("l.start", [#cetz.coordinate.resolve(ctx, "l.start").at(1)], frame: "rect",
          stroke: none, fill: white)
})
```

== Styles

#let style-module = tidy.parse-module(read("src/styles.typ"), name: "Styles")
#show-module-fn(style-module, "resolve")

```example
get-ctx(ctx => {
  // Get the current line style
  content((0,0), [#cetz.styles.resolve(ctx.style, (:), root: "line")])
})
```

=== Default Style <default-style>

This is a dump of the style dictionary every canvas gets initialized with.
It contains all supported keys for all elements.

#[
  #set text(size: 8pt)
  #columns(raw(repr(styles.default), lang: "typc"))
]

= Creating Custom Elements <custom-elements>

The simplest way to create custom, reusable elements is to return them
as a group. In this example we will implement a function `my-star(center)`
that draws a star with `n` corners and a style specified inner and outer
radius.

```example
let my-star(center, name: none, ..style) = {
  group(name: name, ctx => {
    // Define a default style
    let def-style = (n: 5, inner-radius: .5, radius: 1)

    // Resolve the current style ("star")
    let style = cetz.styles.resolve(ctx.style, style.named(),
      base: def-style, root: "star")

    // Compute the corner coordinates
    let corners = range(0, style.n * 2).map(i => {
      let a = 90deg + i * 360deg / (style.n * 2)
      let r = if calc.rem(i, 2) == 0 { style.radius } else { style.inner-radius }

      // Output a center relative coordinate
      (rel: (calc.cos(a) * r, calc.sin(a) * r, 0), to: center)
    })

    line(..corners, ..style, close: true)
  })
}

// Call the element
my-star((0,0))
my-star((0,3), n: 10)

set-style(star: (fill: yellow)) // set-style works, too!
my-star((0,6), inner-radius: .3)
```

= Internals
== Context

The state of the canvas is encoded in its context object. Elements or other
draw calls may return a modified context element to the canvas to change its
state, e.g. modifying the transformating matrix, adding a group or setting a style.

```example
// Show the current context
get-ctx(ctx => {
  content((), raw(repr(ctx), lang: "typc"))
})
```

== Elements

Each CeTZ element (`line`, `bezier`, `circle`, ...) returns an array of
functions for drawing to the canvas. Such function takes the canvas'
context object and must return an dictionary of the following keys:
- `ctx` (required): The (modified) canvas context object
- `drawables`: List of drawables to render to the canvas
- `anchors`: A function of the form `(<anchor-identifier>) => <vector>`
- `name`: The elements name

An element that does only modify the context could be implemented like the
following:
```example
let my-element() = {
  (ctx => {
    // Do something with ctx ...
    (ctx: ctx)
  },)
}

// Call the element
my-element()
```

For drawing, elements must not use Typst native drawing functions, but
output CeTZ paths. The `drawable` module provides functions for path
creation (`path(..)`), the `path-util` module provides utilities for path
segment creation. For demonstration, we will recreate the custmom element
`my-star` from @custom-elements:
```example
import cetz.drawable: path
import cetz.vector

let my-star(center, ..style) = {
  (ctx => {
    // Define a default style
    let def-style = (n: 5, inner-radius: .5, radius: 1)

    // Resolve center to a vector
    let (ctx, center) = cetz.coordinate.resolve(ctx, center)

    // Resolve the current style ("star")
    let style = cetz.styles.resolve(ctx.style, style.named(),
      base: def-style, root: "star")

    // Compute the corner coordinates
    let corners = range(0, style.n * 2).map(i => {
      let a = 90deg + i * 360deg / (style.n * 2)
      let r = if calc.rem(i, 2) == 0 { style.radius } else { style.inner-radius }
      vector.add(center, (calc.cos(a) * r, calc.sin(a) * r, 0))
    })

    // Build a path through all three coordinates
    let path = cetz.drawable.path((cetz.path-util.line-segment(corners),),
      stroke: style.stroke, fill: style.fill, close: true)

    (ctx: ctx,
     drawables: cetz.drawable.apply-transform(ctx.transform, path),
    )
  },)
}

// Call the element
my-star((0,0))
my-star((0,3), n: 10)
my-star((0,6), inner-radius: .3, fill: yellow)
```

Using custom elements instead of groups (as in @custom-elements) makes sense
when doing advanced computations or even applying modifications to passed in
elements.
