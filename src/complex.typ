/// Returns the real part of a complex number.
/// - V (complex): A complex number.
/// -> float
#let re(V) = V.at(0)

/// Returns the imaginary part of a complex number.
/// - V (complex): A complex number.
/// -> float
#let im(V) = V.at(1)


/// Multiplies two complex numbers together and returns the result $V W$.
/// - V (complex): The complex number on the left hand side.
/// - W (complex): The complex number on the right hand side.
#let mul(V, W) = (re(V) * re(W) - im(V) * im(W), im(V) * re(W) + re(V) * im(W))

/// Calculates the conjugate of a complex number.
/// - V (complex): A complex number.
/// -> complex
#let conj(V) = (re(V),-im(V))

// TODO: check what "in R^2" means.
/// Calculates the dot product of two complex numbers in R^2 $V \cdot W$.
/// - V (complex): The complex number on the left hand side.
/// - W (complex): The complex number on the right hand side.
/// -> float
#let dot(V,W) = re(mul(V,conj(W)))

/// Calculates the squared normal of a complex number.
/// - V (complex): The complex number.
/// -> float
#let normsq(V) = dot(V,V)


/// Calculates the normal of a complex number
/// - V (complex): The complex number.
/// -> float
#let norm(V) = calc.sqrt(normsq(V))

/// Multiplies a complex number by a scale factor.
/// - V (complex): The complex number to scale.
/// - t (float): The scale factor.
/// -> complex
#let scale(V,t) = mul(V,(t,0))

/// Returns a unit vector in the direction of a complex number.
/// - V (complex): The complex number.
/// -> vector
#let unit(V) = scale(V, 1/norm(V))

/// Inverts a complex number.
/// - V (complex): The complex number
/// -> complex
#let inv(V) = scale(conj(V), 1/normsq(V))

/// Divides two complex numbers.
/// - V (complex): The complex number of the numerator.
/// - W (complex): The complex number of the denominator.
/// -> complex
#let div(V,W) = mul(V,inv(W))

/// Adds two complex numbers together.
/// - V (complex): The complex number on the left hand side.
/// - W (complex): The complex number on the right hand side.
/// -> complex
#let add(V,W) = (re(V) + re(W),im(V) + im(W))

/// Subtracts two complex numbers together.
/// - V (complex): The complex number on the left hand side.
/// - W (complex): The complex number on the right hand side.
/// -> complex
#let sub(V,W) = (re(V) - re(W),im(V) - im(W))

/// Calculates the argument of a complex number.
/// - V (complex): The complex number.
#let arg(V) = calc.atan2(..V) / 1rad

/// Get the signed angle of two complex numbers from V to W.
/// - V (complex): A complex number.
/// - W (complex): A complex number.
#let ang(V,W) = arg(div(W,V))

// exp(i*a)
#let expi(a) = (calc.cos(a),calc.sin(a))

// Rotate by angle a
#let rot(v,a) = mul(v,expi(a))
