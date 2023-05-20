#import "vector.typ"

// http://paulbourke.net/geometry/pointlineplane/ Intersection point of two line segments in 2 dimensions
// http://jeffreythompson.org/collision-detection/poly-poly.php

// Returns the (x,y) coordinates of the intersection or none if the lines do not collide
#let line-line(x1, y1, x2, y2, x3, y3, x4, y4) = {
  let denominator = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1)
  if denominator == 0 {
    // lines are parallel or coincident
    return none
  }

  let uA = ((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) / denominator
  let uB = ((x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)) / denominator

  return if (uA >= 0 and uA <= 1 and uB >= 0 and uB <= 1) {
    (
      x1 + uA * (x2 - x1),
      y1 + uA * (y2 - y1)
    )
  }
}

// Returns the (x,y) coordinates of the intersections or none if the polygon and line do not collide
// Assumes the polygon is not closed. If the polygon is closed add the first vertex to the end of the vertex list
#let poly-line(vertices, x1, y1, x2, y2) = {
  for current in range(vertices.len() - 1) {
    let next = current + 1
    let (x3, y3, x4, y4) = (
      vertices.at(current).at(0),
      vertices.at(current).at(1),
      vertices.at(next).at(0),
      vertices.at(next).at(1),
    )

    let collision = line-line(x1, y1, x2, y2, x3, y3, x4, y4)
    if collision != none {
      collision
    }
  }
}

#let poly-poly(p1, p2) = {
  let intersections = ()
  for current in range(p1.len() - 1) {
    let next = current + 1
    let (x1, y1, x2, y2) = (
      p1.at(current).at(0),
      p1.at(current).at(1),
      p1.at(next).at(0),
      p1.at(next).at(1)
    )

    let collision = poly-line(p2, x1, y1, x2, y2)
    if collision != none and not collision in intersections {
      intersections.push(collision)
    }
  }
  return intersections
}