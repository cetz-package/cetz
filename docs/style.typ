#import "/src/lib.typ" as cetz

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

#let show-docstring(comment, level) = {
  let text = comment.text
  let arguments = comment.arguments
  let result = comment.result

  set heading(outlined: false, offset: level)

  block([
    #eval(text, mode: "markup", scope: (
      cetz: cetz,
    ))
  ])

  if arguments != () {
    heading("Parameters")
    list(..arguments.map(arg => {
      let types = arg.types
      if types == none { types = ("any",) }
      block(
        strong(raw(arg.name)) + [ ]
        + types.map(show-type).join([ ]) + [\ ]
        + eval(arg.text, mode: "markup")
      )
    }))
  }

  if result.any(r => r.text != "") {
    heading("Result")

    let show-result(r) = if r.text != "" {
      let type = r.type
      if type == none { type = "any" }
      block(
        show-type(type) + [\ ] + eval(r.text, mode: "markup")
      )
    }

    if result.len() > 1 {
      list(..result.map(show-result))
    } else {
      show-result(result.first())
    }
  }
}

/// Show a function signature annoted with types from the docstring
#let show-annotated-signature(signature, comment) = block({
  set par(leading: 0.35em)

  let name = signature.name

  let arguments = signature.arguments.map(arg => {
    let comment-arg = comment.arguments.find(comment-arg => {
      comment-arg.name == arg.name
    })
    if comment-arg == none {
      comment-arg = (types: (), name: name)
    }

    let types = comment-arg.types
    if types == none { types = () }

    if arg.has-default {
      raw(arg.name + ":") + [ ] + types.map(show-type).join([ ])
    } else {
      raw(arg.name) + [ ] + types.map(show-type).join([ ])
    }
  })

  let result = if comment.result != () {
    [ #sym.arrow.r ] + comment.result.map(r => show-type(r.type)).join([ or ])
  } else {
    []
  }

  text(blue, raw(name)) + raw("(") + [\ ] + arguments.map(v => h(1em) + v).join([,\ ]) + [\ ] + raw(")") + result
})

/// Show a single module/file
#let show-module(docs, name, level: 3) = {
  for item in docs.at(name) {
    if item.at("signature", default: none) == none {
      continue
    }

    let function-name = item.signature.name
    if function-name.starts-with("_") {
      continue
    }

    [#heading(function-name, level: level) #label(function-name)]
    show-annotated-signature(item.signature, item.comment)
    show-docstring(item.comment, level)
  }
}

// Root show function for manual.typ
#let setup(body) = {
  set heading(numbering: (..nums) => {
    let nums = nums.pos()
    if nums.len() <= 2 {
      return nums.map(n => [#n]).join([.])
    }
  }, hanging-indent: 0cm)

  /// Render an example side-by-side with its source code.
  let render-example(code, vertical: false) = {
    let columns = if vertical {
      (1fr,)
    } else {
      (1fr, 2fr,)
    }

    let align = if vertical {
      (x, y) => (center + top, left + top).at(y)
    } else {
      (x, y) => (center + horizon, left + top).at(x)
    }

    let stroke = 1pt + gray
    let line = if vertical { table.hline } else { table.vline }

    block(radius: 2pt, stroke: stroke, breakable: false, {
      table(columns: columns, align: align, stroke: none,
        cetz.canvas({
          let preamble = "import cetz.draw: *\n"
          eval(preamble + code, mode: "code", scope: (
            cetz: cetz,
          ))
        }),
        line(stroke: (paint: gray, thickness: 1pt, dash: "dashed")),
        raw(code, lang: "typc"),
      )
    })
  }

  show raw.where(lang: "example"): it => render-example(it.text)
  show raw.where(lang: "example-vertical"): it => render-example(it.text, vertical: true)
  show regex("type:([\w-]+)"): it => show-type(it.text.replace("type:", ""))

  body
}
