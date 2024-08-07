#import "/src/vector.typ"
#import "/src/complex.typ"

// Implementation by @Enivex
//
// Notation comes from https://tug.org/TUGboat/tb34-2/tb107jackowski.pdf
//
// points = (P_0, P_1, ... , P_n)
//
// ta = (tau_(a,0),tau_(a,1), ... , tau_(a,n-1))
// ta(i) = tau_(a,i) is the outgoing tension at P_i on the curve from P_i to P_(i+1)
//
// tb = (tau_(b,0),tau(b,1), ..., tau_(b,n-1))
// tb(i) = tau_(b,i) is the incoming tension at P_(i+1) on the curve from P_i to P_(i+1)
//
// omega = (omega_0,omega_n)
// curl at the start and end of curve (size of mock curvature relative to nearest point)
//
// v(i) = P_(i+1) - P_i
// vector pointing from point i to point i + 1 (direction of ith chord)
//
// d(i) = |v(i)|
// length of the ith chord
//
// gamma(i) = signed angle from v(i - 1) to v(i) (change in angle at P_i)
// Note: gamma(0) = gamma(n) = 0
//
// ca(i) = first control point on chord i
// cb(i) = second control point on chord i
//
// alpha(i) = signed angle from v(i) to ca(i) - P(i)
// beta(i) = signed angle from P(i + 1) - cb(i) to v(i)

// Solve tridiagonal system
//
// - a,b,c,d have the same length, n + 1
// - a(0) and c(n) are not used
//
// Solves Ax=d
// where A=
// [ b_0 c_0
//   a_1 b_1 c_1
//       ......
//         a_(n-1) b_(n-1) c_(n-1)
//                 a_n     b_n     ]
#let thomas(a, b, c, d) = {
  let n = a.len() - 1

  for i in range(1,n + 1) {
    let w = a.at(i) / b.at(i - 1)
    b.at(i) = b.at(i) - w*c.at(i - 1)
    d.at(i) = d.at(i) - w*d.at(i - 1)
  }

  let x = (0,)*(n + 1)
  x.last() = d.last() / b.last()
  for i in range(n - 1, -1 , step: -1) {
    x.at(i) = (d.at(i) - c.at(i)*x.at(i + 1)) / b.at(i)
  }
  return x
}

// Solve cyclic tridiagonal system
//
// - a,b,c,d have the same length, n+1
//
// Solves Ax=d
// where A=
// [ b_0 c_0                         a_0
//   a_1 b_1 c_1
//           ......
//                   a_(n-1) b_(n-1) c_(n-1)
//   c_n                     a_n     b_n     ]
#let thomas-cyclic(a, b, c, d) = {
  let n = a.len() - 1

  let u = (a.first(),) + (0,)*(n - 1) + (c.last(),)
  let v = (1,) + (0,)*(n - 1) + (1,)

  let bp = array.zip(b,u).map(((s,t)) => s - t)
  let y =  thomas(a, bp, c, d)
  let z =  thomas(a, bp, c, u)

  // Sherman-Morrison formula
  return vector.sub(y, vector.scale(z, vector.dot(v,y) / (1 + vector.dot(v, z))))
}

/// Calculates a bezier spline for an open Hobby curve through a list of points. Returns an {{array}} of {{bezier}}s
///
/// - points (array): List of points
/// - ta (auto,array): Outgoing tension per point
/// - tb (auto,array): Incoming tension per point
/// - rho (auto,function): The rho function of the form `(float, float) => float`
/// - omega (auto,array): Tuple of the curl at the start end end of the curve `(start, end)` as floats
///
/// -> array
#let hobby-to-cubic-open(points, ta: auto, tb: auto, rho: auto, omega: auto) = {
  let n = points.len() - 1

  if ta == auto {
    ta = (1,)*n
  } else {
    assert.eq(type(ta), array, message: "ta must be an array")
    assert.eq(ta.len(), n, message: "ta must have length n for n + 1 points")
    assert(ta.all(x => x > 0), message: "ta must contain only positive numbers")
  }
  if tb == auto {
    tb = (1,)*n
  } else {
    assert.eq(type(tb), array, message: "tb must be an array")
    assert.eq(tb.len(), n, message: "tb must have length n for n + 1 points")
    assert(tb.all(x => x > 0), message: "tb must contain only positive numbers")
  }
  if rho == auto {
    rho = (a,b) => {
      (2 + calc.sqrt(2)*(calc.sin(a) - calc.sin(b)/16)*(calc.sin(b)-calc.sin(a)/16)*(calc.cos(a)-calc.cos(b)))/(1 + calc.cos(a)*(calc.sqrt(5)-1)/2 + calc.cos(b)*(3-calc.sqrt(5))/2)
    }
  } else {
    assert.eq(type(rho), function,
      message: "rho must be a function")
  }

  let v = range(n).map(i => complex.sub(points.at(i + 1),points.at(i)))
  let d = v.map(complex.norm)

  let gamma = (0,) + range(n - 1).map(i => complex.ang(v.at(i),v.at(i + 1))) + (0,)

  let ita = ta.map(x => 1/x)
  let itasq = ita.map(x => x*x)

  let itb = tb.map(x => 1/x)
  let itbsq = itb.map(x => x*x)

  let (omega0, omegan) = omega

  let A = (0,) * (n + 1); let B = A; let C = A; let D = A; let E = A

  C.at(0) = omega0 * ita.at(0) * itasq.at(0) / itbsq.at(0) + 3 - itb.at(0)
  D.at(0) = omega0 * itasq.at(0) / itbsq.at(0) * (3 - ita.at(0)) + itb.at(0)
  E.at(0) = - D.at(0) * gamma.at(1)

  for i in range(1, n) {
    A.at(i) = ita.at(i - 1) / (d.at(i - 1) * itbsq.at(i - 1))
    B.at(i) = (3 - ita.at(i - 1))/(d.at(i - 1) * itbsq.at(i - 1))
    C.at(i) = (3 - itb.at(i))/(d.at(i) * itasq.at(i))
    D.at(i) = itb.at(i) / (d.at(i) * itasq.at(i))
    E.at(i) = - B.at(i) * gamma.at(i) - D.at(i) * gamma.at(i + 1)
  }

  A.at(n) = omegan * itbsq.at(n - 1) / itasq.at(n - 1) * ( 3 - itb.at(n - 1)) + ita.at(n - 1)
  B.at(n) = omegan * itb.at(n - 1) * itbsq.at(n - 1) / itasq.at(n - 1) + 3 - ita.at(n - 1)

  let alpha = thomas(A,vector.add(B,C), D, E)
  let beta = vector.scale(vector.add(alpha,gamma).slice(1), -1)

  let ca = (0,)*n; let cb = ca
  for i in range(n) {
    let a = rho(alpha.at(i),beta.at(i)) * d.at(i) / 3
    let b = rho(beta.at(i),alpha.at(i)) * d.at(i) / 3
    ca.at(i) = complex.add(points.at(i), complex.scale(complex.unit(complex.rot(v.at(i),alpha.at(i))), a))
    cb.at(i) = complex.sub(points.at(i + 1), complex.scale(complex.unit(complex.rot(v.at(i),-beta.at(i))), b))
  }
  return range(n).map(i => (points.at(i), points.at(i+1), ca.at(i), cb.at(i)))
}

/// Calculates a bezier spline for a closed Hobby curve through a list of points. Returns an {{array}} of {{bezier}}s.
///
/// - points (array): List of points
/// - ta (auto,array): Outgoing tension per point
/// - tb (auto,array): Incoming tension per point
/// - rho (auto,array): The rho function of the form `(float, b) => float`
///
/// -> array
#let hobby-to-cubic-closed(points, ta: auto, tb: auto, rho: auto) = {
  if points.first() != points.last() {
    points.push(points.first())
  }

  let n = points.len() - 1
  points.push(points.at(1))

  if ta == auto {
    ta = (1,)*n
  } else {
    assert.eq(type(ta), array, message: "ta must be an array")
    assert.eq(ta.len(), n, message: "ta must have length n for n + 1 points")
    assert(ta.all(x => x > 0), message: "ta must contain only positive numbers")
  }
  if tb == auto {
    tb = (1,)*n
  } else {
    assert.eq(type(tb), array, message: "tb must be an array")
    assert.eq(tb.len(), n, message: "tb must have length n for n + 1 points")
    assert(tb.all(x => x > 0), message: "tb must contain only positive numbers")
  }
  if rho == auto {
    rho = (a,b) => {
      (2 + calc.sqrt(2)*(calc.sin(a) - calc.sin(b)/16)*(calc.sin(b)-calc.sin(a)/16)*(calc.cos(a)-calc.cos(b)))/(1 + calc.cos(a)*(calc.sqrt(5)-1)/2 + calc.cos(b)*(3-calc.sqrt(5))/2)
    }
  } else {
    assert.eq(type(rho), function,
      message: "rho must be a function")
  }

  let v = range(n + 1).map(i => complex.sub(points.at(i + 1),points.at(i)))
  let d = v.map(complex.norm)

  let gamma = range(n).map(i => complex.ang(v.at(i),v.at(i + 1)))
  gamma = (gamma.last(),..gamma)

  let ita = ta.map(x => 1/x)
  let itasq = ita.map(x => x*x)

  let itb = tb.map(x => 1/x)
  let itbsq = itb.map(x => x*x)

  let A = (0,) * n; let B = A; let C = A; let D = A; let E = A

  A.at(0) = ita.at(n - 1) / (d.at(n - 1) * itbsq.at(n - 1))
  B.at(0) = (3 - ita.at(n - 1))/(d.at(n - 1) * itbsq.at(n - 1))
  C.at(0) = (3 - itb.at(0))/(d.at(0) * itasq.at(0))
  D.at(0) = itb.at(0) / (d.at(0) * itasq.at(0))
  E.at(0) = - B.at(0) * gamma.at(0) - D.at(0) * gamma.at(1)

  for i in range(1, n) {
    A.at(i) = ita.at(i - 1) / (d.at(i - 1) * itbsq.at(i - 1))
    B.at(i) = (3 - ita.at(i - 1))/(d.at(i - 1) * itbsq.at(i - 1))
    C.at(i) = (3 - itb.at(i))/(d.at(i) * itasq.at(i))
    D.at(i) = itb.at(i) / (d.at(i) * itasq.at(i))
    E.at(i) = - B.at(i) * gamma.at(i) - D.at(i) * gamma.at(i + 1)
  }

  let alpha = thomas-cyclic(A,vector.add(B,C), D, E)
  alpha.push(alpha.at(0))
  let beta = vector.scale(vector.add(alpha,gamma), -1)
  beta = (..beta.slice(1),beta.at(0))

  let ca = (0,) * n; let cb = ca
  for i in range(n) {
    let a = rho(alpha.at(i),beta.at(i)) * d.at(i) / 3
    let b = rho(beta.at(i),alpha.at(i)) * d.at(i) / 3
    ca.at(i) = complex.add(points.at(i), complex.scale(complex.unit(complex.rot(v.at(i),alpha.at(i))), a))
    cb.at(i) = complex.sub(points.at(i + 1), complex.scale(complex.unit(complex.rot(v.at(i),-beta.at(i))), b))
  }

  return range(n).map(i => (points.at(i), points.at(i+1), ca.at(i), cb.at(i)))
}

/// Calculates a bezier spline for a Hobby curve through a list of points. Returns an {{array}} of {{bezier}}s.
///
/// - points (array): List of points
/// - ta (auto,array): Outgoing tension per point
/// - tb (auto,array): Incoming tension per point
/// - rho (auto,array): The rho function of the form `(float, float) => float`
/// - omega (auto,array): Tuple of the curl at the start end end of the curve `(start, end)` as floats
/// - close (bool): Close the curve
///
/// -> array
#let hobby-to-cubic(points, ta: auto, tb: auto, rho: auto, omega: auto, close: false) = {
  let omega = if omega == auto {
    (1, 1)
  } else if type(omega) == array {
    omega
  } else {
    (omega, omega)
  }
  assert.eq(type(omega), array,
    message: "Omega must be of type array")
  assert.eq(omega.len(), 2,
    message: "Omega must be of length 2")
  assert(omega.all(x => x >= 0),
    message: "Omega must contain positive values only")

  if not close and points.len() == 2 {
    let (a, b) = points
    return ((a, b, a, b),)
  }

  return if close {
    hobby-to-cubic-closed(points, ta: ta, tb: tb, rho: rho)
  } else {
    hobby-to-cubic-open(points, ta: ta, tb: tb, rho: rho, omega: omega)
  }
}
