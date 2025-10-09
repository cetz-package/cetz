#import "/src/lib.typ" as cetz

#import "/docs/typlodocus/extractor.typ"

#let modules = (
  "src/draw/shapes.typ",
  "src/lib/angle.typ",
  "src/lib/tree.typ",
)

#let docs = modules.map(filename => {
  (filename, extractor.extract-doc-comments(read(filename).split("\n")))
}).to-dict()

#let show-type(name) = {
  let colors = (
    int: yellow,
    float: yellow,
    string: red,
    array: purple,
    function: purple,
    any: gray.lighten(50%),
    rest: gray.lighten(50%),
  )

  box(raw(name), inset: 2pt, baseline: 2pt, radius: 2pt,
    fill: colors.at(name, default: colors.rest), stroke: none)
}

#let show-annotated-signature(signature, comment) = {
  let name = signature.name

  let arguments = signature.arguments.map(arg => {
    let comment-arg = comment.arguments.find(comment-arg => {
      comment-arg.name == arg.name
    })
    if comment-arg == none {
      comment-arg = (types: (), name: name)
    }

    if arg.has-default {
      raw(arg.name + ":") + comment-arg.types.map(show-type).join([ ])
    } else {
      raw(arg.name)
    }
  })

  let result = if comment.result != () {
    [#sym.arrow.r]
  } else {
    []
  }

  raw(name) + raw("(") + [\ ] + arguments.map(v => h(1em) + v).join([,\ ]) + [\ ] + raw(")") + result
}

/// Render an example side-by-side with its source code.
#let render-example(code) = {
  block(radius: 2pt, stroke: 1pt + gray, {
    table(columns: (1fr, 2fr), align: (x, y) => (center + horizon, left + top).at(x), stroke: none,
      cetz.canvas({
        let preamble = "import cetz.draw: *\n"
        eval(preamble + code, mode: "code", scope: (
          cetz: cetz,
        ))
      }),
      raw(code, lang: "typc"),
    )
  })
}

#let show-docstring(comment, level) = {
  let text = comment.text
  let arguments = comment.arguments

  show raw.where(lang: "example"): it => render-example(it.text)

  if arguments != () {
    heading("Parameters", level: level + 1)
    list(..arguments.map(arg => {
      block(
        strong(raw(arg.name)) + [ ]
        + arg.types.map(show-type).join([ ]) + [\ ]
        + eval(arg.text, mode: "markup")
      )
    }))
  }

  block([
    #eval(text, mode: "markup", scope: (
      cetz: cetz,
    ))
  ])
}

// Show a single module/file
#let show-module(name, level: 2) = {
  for item in docs.at(name) {
    let function-name = item.signature.name

    heading(function-name, level: level)

    show-docstring(item.comment, level)
    block(show-annotated-signature(item.signature, item.comment))
  }
}


#columns(2, outline())
#pagebreak()

= Shapes
//#show-module("src/draw/shapes.typ")

= Libraries
== Angle
#show-module("src/lib/angle.typ", level: 3)

== Tree
#show-module("src/lib/tree.typ", level: 3)
