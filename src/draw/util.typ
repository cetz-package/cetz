/// Assert that the cetz version of the canvas matches the given version (range).
///
/// min (version): Minimum version (current >= min)
/// max (none, version): First unsupported version (current < max)
/// hint (string): Name of the function/module this assert is called from
#let assert-version(min, max: none, hint: "") = {
  if hint != "" { hint = " by " + hint }
  (ctx => {
    /* Default to 2.0.0, as this is the first version that had elements as single functions. */
    let v = ctx.at("version", default: version(0,2,0))
    assert(min <= v,
      message: "CeTZ canvas version is " + str(v) + ", but the minimum required version" + hint + " is " + str(min))
    if max != none {
      assert(max > v,
        message: "CeTZ canvas version is " + str(v) + ", but the maximum supported version" + hint + " is " + str(min))
    }

    return (ctx: ctx)
  },)
}

/// Push a custom coordinate resolve function to the list of coordinate
/// resolvers. This resolver is scoped to the current context scope!
///
/// A coordinate resolver must be a function of the format `(context, coordinate) => coordinate`. And must _always_ return a valid coordinate or panic, in case of an error.
///
/// If multiple resolvers are registered, coordinates get passed through all
/// resolvers in reverse registering order. All coordinates get paased to cetz'
/// default coordinate resolvers.
///
/// ```typc example
/// register-coordinate-resolver((ctx, c) => {
///   if type(c) == dictionary and "log" in c {
///     c = c.log.map(n => calc.log(n, base: 10))
///   }
///   return c
/// })
///
/// circle((log: (10, 1e-6)), radius: .25)
/// circle((log: (100, 1e-6)), radius: .25)
/// circle((log: (1000, 1e-6)), radius: .25)
/// ```
///
/// - resolver (function): The resolver function, taking a context and a single coordinate and returning a single coordinate
#let register-coordinate-resolver(resolver) = {
  assert.eq(type(resolver), function,
    message: "Coordinate resolver must be of type function (ctx, coordinate) => coordinate.")

  return (ctx => {
    if type(ctx.resolve-coordinate) == array {
      ctx.resolve-coordinate.push(resolver)
    } else {
      ctx.resolve-coordinate = (resolver,)
    }

    return (ctx: ctx)
  },)
}
