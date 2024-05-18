/// Assert that the cetz version of the canvas
/// matches the given version (range).
///
/// min (version): Minimum version (current >= min)
/// max (none, version): First unsupported version (current < max)
/// hint (string): Name of the function/module this assert is called from
#let assert-version(min, max: none, hint: "") = {
  if hint != "" { hint = " by " + hint }
  (ctx => {
    assert(min <= ctx.version,
      message: "CeTZ canvas version is " + str(ctx.version) + ", but the minimum required version" + hint + " is " + str(min))
    if max != none {
      assert(max > ctx.version,
        message: "CeTZ canvas version is " + str(ctx.version) + ", but the maximum supported version" + hint + " is " + str(min))
    }

    return (ctx: ctx)
  },)
}
