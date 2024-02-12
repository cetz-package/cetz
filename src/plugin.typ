#let plugins = state("cetz-plugins", ())

/// Register a plug-in to CeTZ's plug-in list
///
/// - plugin (dictionary): Plug-In object. A plug-in in must be a dictionary
///   which can have the following callbacks:
///   / `init`: A function of the form `() => element` that can return any number of CeTZ elements that
///     get _prefixed_ to the canvas body. This can be used to set-up a default style by calling `set-style(...)` or
///     set custom context data using `set-ctx(...)`.
#let register(plugin) = {
  assert.eq(type(plugin), dictionary,
    message: "Expected plug-in dictionary, got " + repr(plugin))
  return plugins.update(l => {
    l.push(plugin)
    return l
  })
}
