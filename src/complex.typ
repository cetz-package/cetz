// Real and imaginary part
#let re(V) = V.at(0)
#let im(V) = V.at(1)

// Complex multiplication
#let mul(V,W) = (re(V)*re(W) - im(V)*im(W),im(V)*re(W) + re(V)*im(W))

// Complex conjugate
#let conj(V) = (re(V),-im(V))

// Dot product of V and W as vectors in R^2
#let dot(V,W) = re(mul(V,conj(W)))

// Norm and norm-squared
#let normsq(V) = dot(V,V)
#let norm(V) = calc.sqrt(normsq(V))

// V*t
#let scale(V,t) = mul(V,(t,0))

// Unit vector in the direction of V
#let unit(V) = scale(V, 1/norm(V))

// V^(-1) as a complex number
#let inv(V) = scale(conj(V), 1/normsq(V))

// V / W
#let div(V,W) = mul(V,inv(W))

// V + W and V - W
#let add(V,W) = (re(V) + re(W),im(V) + im(W))
#let sub(V,W) = (re(V) - re(W),im(V) - im(W))

// Argument
#let arg(V) = calc.atan2(..V) / 1rad

// Signed angle from V to W
#let ang(V,W) = arg(div(W,V))

// exp(i*a)
#let expi(a) = (calc.cos(a),calc.sin(a))

// Rotate by angle a
#let rot(v,a) = mul(v,expi(a))
