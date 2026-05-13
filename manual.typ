#import "/docs/style.typ": show-type, show-module, setup, cetz
#import "/docs/typlodocus/extractor.typ"

#show: setup

#let modules = (
  [Canvas],
  "src/canvas.typ",

  [Shapes],
  "src/draw/shapes.typ",
  [Boolean Operations],
  "src/draw/boolean.typ",
  [Styling],
  "src/draw/styling.typ",
  [Grouping],
  "src/draw/grouping.typ",
  [Transformation],
  "src/draw/transformations.typ",
  [Projection],
  "src/draw/projection.typ",
  [Utility],
  "src/draw/util.typ",

  [Libraries], 1,
    [Angle],
    "src/lib/angle.typ",
    [Tree],
    "src/lib/tree.typ",
    [Decorations], 2,
      [Path],
      "src/lib/decorations/path.typ",
      [Brace],
      "src/lib/decorations/brace.typ",
    1,
    [Palette],
    "src/lib/palette.typ",
  0,

  [Internals], 1,
  [Complex],
  "src/complex.typ",
  [Vector],
  "src/vector.typ",
  [Matrix],
  "src/matrix.typ",
  [Coordinate],
  "src/coordinate.typ",
  [Styles],
  "src/styles.typ",
  [Process],
  "src/process.typ",
  [Drawable],
  "src/drawable.typ",
  [Anchor],
  "src/anchor.typ",
  [Mark],
  "src/mark.typ",
  [Bezier],
  "src/bezier.typ",
  [AABB],
  "src/aabb.typ",
  [Hobby],
  "src/hobby.typ",
  [Intersection],
  "src/intersection.typ",
  [Path Util],
  "src/path-util.typ",
  [Util],
  "src/util.typ",
  0,
)

#let docs = modules.filter(item => type(item) == str).map(filename => {
  (filename, extractor.extract-doc-comments(read(filename).split("\n")))
}).to-dict()

// Generate query metadata
#metadata(docs) <metadata>

// Outline
#columns(2, outline(depth: 4))
#pagebreak()

= Overview
CeTZ, ein Typst Zeichenpaket, is a drawing package for Typst.
Its API is similar to Processing but with relative coordinates
and anchors from TikZ. You also won't have to worry about
accidentally drawing over other content as the canvas will
automatically resize. And remember: up is positive!

= Getting Started
== Usage
This is the minimal starting point in a `.typ` file:
```typst
#import "@preview/cetz:0.5.3"
#cetz.canvas({
  import cetz.draw: *
  ...
})
```

Note that draw functions are imported inside the scope of the canvas block.
This is recommended as some draw functions override Typst's
functions such as @line[`line`].

== Examples
From this point on only the code inside the
canvas block will be shown in examples unless specified otherwise.

```example
// Draw a circle
circle((0, 0))

// Draw a line
line((1,-1), (2,1))
```

= Basics
The following chapters are about the basic and core concepts of CeTZ.
They are recommended reading for basic usage.

== Custom Types
Many CeTZ functions expect data in certain formats which we will call types.
Note that these are actually made up of Typst primitives.

/ type\:coordinate<type-coordinate>: A position on the canvas specified by any
  coordinate system. See Coordinate Systems.
/ type\:number<type-number>: Any of type:float, type:int or type:length
/ type\:style<type-style>: Represents options passed to draw functions that
  affect how elements are drawn. They are normally taken in the form of
  named arguments to the draw functions or sometimes can be a dictionary
  for a single argument.
/ type\:elements<type-elements>: One or more elements such as `line`, `rect`
  or `group`. To pass multiple elements, you can wrap them in curly braces `{}`,
  like a normal Typst scope.
/ type\:context<type-context>: CeTZ's internal context object that holds the
  canvas' state.
// NOTE: Add new types to the custom-types list in style.typ!

== The Canvas
The @canvas[canvas] function is what handles all of the logic and
processing in order to produce drawings. It's usually called with
a code block `{ ... }` as argument. The content of the curly braces is the
body of the canvas. Import all the draw functions you need at the top of
the body:
```typst
#cetz.canvas({
  import cetz.draw: *
})
```

You can now call the draw functions within the body and they'll
produce some graphics! Typst will evaluate the code block and pass the
result to the canvas function for rendering.

The canvas does not have typical width and height parameters.
Instead its size will grow and shrink to fit the drawn graphic.

By default $1$ coordinate unit is $1 "cm"$, this can be changed by setting the
`length:` parameter.

== Coordinates <coordinates>
=== XYZ
Specifies a point as a multiple of the $x$, $y$, and $z$ vectors of the current
canvas' transformation.

/ Syntax:
  - `(x type:number, y type:number, z type:number = 0)`
  - `(x: type:number = 0, y: type:number = 0, z: type:number = 0)`

```example
// Short form: (x, y, [z])
line((0, 0), (1, 0, 0))

// Dictionary form (x:, y:, z:)
line((x: 0cm, y: 0), (y: 1))
```

=== Polar
Specifies a point in polar coordinates.

/ Syntax:
  - `(α type:angle, r type:number or (type:number, type:number))`
  - `(angle: type:angle, radius: type:number or (type:number, type:number))`

```example
circle((0, 0))

// Draw a line from (0, 0) to 30deg on the unit circle
line((0, 0), (30deg, 1),
     mark: (start: ")>", end: ")>"))
```

=== Previous
You can access the previous coordinate by passing an empty array `()`. The initial
previous coordinate is at `(0, 0, 0)`.

```example
// Draw a line to (1, 0)
line((), (1, 0))

// A dot at the previous coordinate, (1, 0, 0)
circle((), radius: 1pt, fill: black)
```

=== Relative
You can add two coordinates using the relative coordinate syntax.

/ Syntax:
  - (rel: type:coordinate) specifies a coordinate relative to the previous coordinate `()`
  - (rel: type:coordinate, to: type:coordinat) specifies a coordinate relative to `to` by adding both vectors

```example
anchor("a", (1,3))

set-style(radius: 1pt, fill: black, content: (padding: 0.8em))
circle("a")
content((), [A], anchor: "north")

circle((rel: (2, 1), to: "a"))
content((), `(rel: (2, 1), to: "a")`, anchor: "south")
```

=== Barycentric
In the barycentric coordinate system a point is expressed as the linear combination
of multiple vectors. The idea is that you specify vectors $v_1, v_2, ..., v_n$
and numbers $alpha_1, alpha_2, ..., alpha_n$. Then the barycentric coordinate
specified by these vectors and numbers is
$(alpha_1 v_1 + alpha_2 v_2 + dots.c + alpha_n v_n)/(alpha_1 + alpha_2 + dots.c + alpha_n)$.

/ Syntax:
  - `(bary: (anchor: type:float or type:ratio, ...))`, where `anchor` is the name of an element or anchor.
  - `(bary: ((type:coordinate, type:float or type:ratio), ...))`

```example
anchor("a", (90deg, 2))
anchor("b", (210deg, 2))
anchor("c", (330deg, 2))

line("a", "b", "c", close: true)

// Place points as a combination of a, b and c
set-style(radius: 1pt, fill: black, content: (padding: 0.8em))
circle((bary: (a: 0, b: 0, c: 1)), name: "ca")
content("ca", [A], anchor: "west")

circle((bary: (a: 50%, b: 20%, c: 30%)), name: "cb")
content("cb", [B], anchor: "east")

circle((bary: (("a", 0.8), ("b", 0.8), ("c", 0.8))), name: "cc")
content("cc", [C], anchor: "east")
```

=== Anchor
Defines a point relative to a named element using anchors.

/ Syntax:
  - `element type:string` gives the `"default"` anchor of element `element`, `"center"` for most elements
  - `element.anchor type:string` gives the named anchor `anchor` of element `element`
  - `element.<angle> type:string` gives the border anchor of `element` at angle `angle`, that is the coordinate at which a ray with angle `angle` intersects the elements path
  - `element.<number or ratio> type:string` gives the path anchor of `element` at distance `number`, that is the coordinat traveled along the path by distance `number`
  - `(name: type:string, anchor: type:string or type:number or type:ratio or type:angle)` explicit, typed form

```example
hobby((0, 0), (1, 2), (2, 1), (3, 3), name: "l")

set-style(radius: 1pt, fill: black, content: (padding: 0.8em))
// Access a named anchor
circle("l.end")
content((), `l.end`, anchor: "south")

// Access a relative path anchor
circle("l.25%")
content((), `l.25%`, anchor: "south-east")

// Access an absolute path anchor
circle((name: "l", anchor: 0.5cm))
content((), `(name: "l", anchor: 0.5cm)`, anchor: "west")
```

```example
rect((0, 0), (2, 2), name: "r")

set-style(radius: 1pt, fill: black, content: (padding: 0.8em))
// Access the default anchor
circle("r")
content((), `r`, anchor: "south")

// Access a border anchor
circle("r.30deg")
content((), `r.30deg`, anchor: "west")
```

=== Perpendicular

=== Tangent

=== Projection

/ Syntax:
  - `(p type:coordinate, "⟂", a type:coordinate, b type:coordinate)`
  - `(p type:coordinate, "_|_", a type:coordinate, b type:coordinate)`
  - `(project: type:coordinate, onto: (a type:coordinate, b type:coordinate))`

```example
line((1, 1), (3, 2), name: "l")

anchor("pt", (1.5, 2))

// Project "pt" onto the line from "l.start" to "l.end"
anchor("x", (project: "pt", onto: ("l.start", "l.end")))

set-style(radius: 1pt, fill: black, content: (padding: 0.8em))
circle("pt")
content((), [pt], anchor: "south")
circle("x")
content((), [x], anchor: "north")

line("pt", "x")
```

=== Callback/Function
Specifies a coordinate by evaluating a callback function with resolved
coordinates passed as arguments.

/ Syntax:
  - `(type:function, type:coordinate, ...)` an array of a funciton and zero or more coordinates

Thet function gets called with $n$ vectors, where $n$ is the number of coordinates passed along with the function.

```example
anchor("a", (1.2, 3.7))

set-style(radius: 1pt, fill: black, content: (padding: 0.8em))
// Access the default anchor
circle("a")
content((), `A`, anchor: "north")

// Pass a custom function that rounds each component of "a"
circle((a => {
  a.map(calc.round)
}, "a"))
content((), `function`, anchor: "south")
```

== Styling <styling>
You can style draw elements by passing the relevant named arguments
to their draw functions. All elements that draw something have
stroke and fill styling unless said otherwise.

/ fill: type:none or type:auto or type:color or type:gradient or type:tiling (default: `none`) \
  How to fill the drawn element.
/ stroke: type:none or type:auto or type:length or type:color or type:dictionary or type:stroke (default: `black`) \
  How to stroke the border or the path of the draw element. #link("https://typst.app/docs/reference/visualize/line/#parameters-stroke")[See Typst's line documentation for more details.]

= API
#let heading-offset = 1
#for item in modules {
  if type(item) == int {
    heading-offset = 1 + item
  } else if type(item) != str {
    heading(item, offset: heading-offset)
  } else {
    show-module(docs, item, level: 2 + heading-offset)
  }
}
