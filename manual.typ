#import "/docs/style.typ": show-type, show-module, setup, cetz
#import "/docs/typlodocus/extractor.typ"

#show: setup

#let modules = (
  [Canvas],
  "src/canvas.typ",

  [Shapes],
  "src/draw/shapes.typ",
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
#import "@preview/cetz:0.4.2"
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

/ type\:coordinate: A position on the canvas specified by any
  coordinate system. See Coordinate Systems.
/ type\:number: Any of type:float, type:int or type:length
/ type\:style: Represents options passed to draw functions that
  affect how elements are drawn. They are normally taken in the form of
  named arguments to the draw functions or sometimes can be a dictionary
  for a single argument.

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

== Styling <styling>
You can style draw elements by passing the relevant named arguments
to their draw functions. All elements that draw something have
stroke and fill styling unless said otherwise.

/ fill: type:color or type:none (default: `none`) \
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
