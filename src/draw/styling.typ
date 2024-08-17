#import "/src/util.typ"

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
    ctx.style = util.merge-dictionary(ctx.style, style.named())
    
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
/// - symbol (string): Mark name
/// - mnemonic (none,string): Mark short name
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
