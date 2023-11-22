// Geometry helper functions

/// Get the arc-len of a circle or arc
///
/// - radius (float): Circle or arc radius
/// - start (angle): Start angle
/// - stop (angle): Stop angle
/// -> float Arc length
#let circle-arclen(radius, angle: 360deg) = {
  calc.abs(angle / 360deg * 2 * calc.pi)
}
