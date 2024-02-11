#import "/src/draw.typ": hide, get-ctx, set-ctx

// Function returning the context polylux library object
#let _polylux(ctx) = {
  assert(ctx.at("polylux-module", default: none) != none,
    message: "Polylux library not registered: call `init-polylux(...)` to enable it")
  return ctx.polylux-module
}

// Modified copy of Polylux _conditional-display function
// from logic.typ
#let _conditional-display(visible-subslides, remove-space, mode, body) = {
  get-ctx(ctx => {
    let pl = _polylux(ctx).logic

    let vs = visible-subslides
    set-ctx(ctx => {
      ctx.utility-content.push(() => {
        pl.repetitions.update(rep => {
          calc.max(rep, pl._last-required-subslide(vs))
        })
      })
      return ctx
    })
    if pl._check-visible(pl.subslide.at(ctx.typst-location).first(), vs) {
      body
    } else {
      hide(body, bounds: remove-space)
    }
  })
}

/// Initialize CeTZ Polylux bindings
///
/// - module (module): The Polylux module object
#let init-polylux(module) = set-ctx(ctx => {
  ctx.polylux-module = module
  return ctx
})

/// Polylux uncover binding
///
/// - visible-subslides (int, array, string, dictionary): Visible subslide specification, see Polylux documentation
/// - mode (string): Currently unsupported
/// - body (element): One or more elements
#let uncover(visible-subslides, mode: "invisible", body) = {
  assert.eq(mode, "invisible",
    message: "CeTZ Polylux integration only supports \"invisible\" mode")
  _conditional-display(visible-subslides, true, mode, body)
}

/// Polylux only binding
///
/// - visible-subslides (int, array, string, dictionary): Visible subslide specification, see Polylux documentation
/// - body (element): One or more elements
#let only(visible-subslides, body) = {
  _conditional-display(visible-subslides, false, "", body)
}
