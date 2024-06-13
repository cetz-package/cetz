/// Assert that the cetz version of the canvas
/// matches the given version (range).
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
