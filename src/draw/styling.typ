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
/// - symbol (string): Mark name
/// - mnemonic (none,string): Mark short name
/// - body (function): Mark drawing callback, receiving the mark style as
///   argument. Format (styles) => elements.
#let register-mark(symbol, body, mnemonic: none) = {
  assert(type(symbol) == str)
  assert(type(body) == function)

  (ctx => {
    ctx.marks.marks.insert(symbol, body)
    if type(mnemonic) == str and mnemonic.len() > 0 {
      ctx.marks.mnemonics.insert(symbol, mnemonic)
    }
    return (ctx: ctx)
  },)
}
