#import "/src/util.typ"
#import "/src/styles.typ"

/// Set current style
///
/// - ..style (style): Style key-value pairs
#let set-style(..style) = {
  assert.eq(
    style.pos().len(),
    0,
    message: "set-style takes no positional arguments",
  )
  
  (ctx => {
    ctx.style = styles.merge(ctx.style, style.named())

    return (ctx: ctx)
  },)
}

/// Set current fill style
///
/// Shorthand for `set-style(fill: <fill>)`
///
/// - fill (paint): Fill style
#let fill(fill) = set-style(fill: fill)

/// Set current stroke style
///
/// Shorthand for `set-style(stroke: <fill>)`
///
/// - stroke (stroke): Stroke style
#let stroke(stroke) = set-style(stroke: stroke)

/// Register a custom mark to the canvas
///
/// The mark should contain both anchors called **tip** and **base** that are used to determine the marks orientation. If unset both default to `(0, 0)`.
/// An anchor named **center** is used as center of the mark, if present. Otherwise the mid between **tip** and **base** is used.
///
/// ```typc example
/// register-mark(":)", style => {
///   circle((0,0), radius: .5, fill: yellow)
///   arc((0,0), start: 180deg + 30deg, delta: 180deg - 60deg, anchor: "origin", radius: .3)
///   circle((-0.15, 0.15), radius: .1, fill: white)
///   circle((-0.10, 0.10), radius: .025, fill: black)
///   circle(( 0.15, 0.15), radius: .1, fill: white)
///   circle(( 0.20, 0.10), radius: .025, fill: black)
///
///   anchor("tip",  ( 0.5, 0))
///   anchor("base", (-0.5, 0))
/// })
///
/// line((0,0), (3,0), mark: (end: ":)"))
/// ```
///
/// - symbol (str): Mark name
/// - mnemonic (none,str): Mark short name
/// - body (function): Mark drawing callback, receiving the mark style as argument and returning elements. Format `(styles) => elements`.
#let register-mark(symbol, body, mnemonic: none) = {
  assert(type(symbol) == str)
  assert(type(body) == function)

  (ctx => {
    ctx.marks.marks.insert(symbol, body)
    if type(mnemonic) == str and mnemonic.len() > 0 {
      ctx.marks.mnemonics.insert(mnemonic, symbol)
    }
    return (ctx: ctx)
  },)
}
