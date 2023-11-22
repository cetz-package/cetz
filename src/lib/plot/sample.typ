/// Sample the given one parameter function with `samples` values
/// evenly spaced within the range given by `domain` and return each
/// sampled `y` value in an array as `(x, y)` tuple.
///
/// If the functions first return value is a tuple `(x, y)`, then all return values
/// must be a tuple.
///
/// - fn (function): Function to sample of the form `(x) => y` or `(x) => (x, y)`.
/// - domain (domain): Domain of `fn` used as bounding interval for the sampling points.
/// - samples (int): Number of samples in domain.
/// - sample-at (array): List of x values the function gets sampled at in addition
///                      to the `samples` number of samples. Values outsides the
///                      specified domain are legal.
/// -> array: Array of (x, y) tuples
#let sample-fn(fn, domain, samples, sample-at: ()) = {
  assert(samples + sample-at.len() >= 2,
    message: "You must at least sample 2 values")
  assert(type(domain) == array and domain.len() == 2,
    message: "Domain must be a tuple")

  let (lo, hi) = domain

  let y0 = (fn)(lo)
  let is-vector = type(y0) == array
  if not is-vector {
    y0 = ((lo, y0), )
  } else {
    y0 = (y0, )
  }

  let pts = sample-at + range(0, samples).map(t => lo + t / (samples - 1) * (hi - lo))
  pts = pts.sorted()

  return pts.map(x => {
    if is-vector {
      (fn)(x)
    } else {
      (x, (fn)(x))
    }
  })
}

/// Samples the given two parameter function with `x-samples` and
/// `y-samples` values evenly spaced within the range given by
/// `x-domain` and `y-domain` and returns each sampled output in
/// an array.
///
/// - fn (function): Function of the form `(x, y) => z` with all values being numbers.
/// - x-domain (domain): Domain used as bounding interval for sampling point's x
///                      values.
/// - y-domain (domain): Domain used as bounding interval for sampling point's y
///                      values.
/// - x-samples (int): Number of samples in the x-domain.
/// - y-samples (int): Number of samples in the y-domain.
/// -> array: Array of z scalars
#let sample-fn2(fn, x-domain, y-domain, x-samples, y-samples) = {
  assert(x-samples >= 2,
    message: "You must at least sample 2 x-values")
  assert(y-samples >= 2,
    message: "You must at least sample 2 y-values")
  assert(type(x-domain) == array and x-domain.len() == 2,
    message: "X-Domain must be a tuple")
  assert(type(y-domain) == array and y-domain.len() == 2,
    message: "Y-Domain must be a tuple")

  let (x-min, x-max) = x-domain
  let (y-min, y-max) = y-domain
  let y-pts = range(0, y-samples)
  let x-pts = range(0, x-samples)

  return y-pts.map(y => {
    let y = y / (y-samples - 1) * (y-max - y-min) + y-min
    return x-pts.map(x => {
      let x = x / (x-samples - 1) * (x-max - x-min) + x-min
      return float((fn)(x, y))
    })
  })
}
