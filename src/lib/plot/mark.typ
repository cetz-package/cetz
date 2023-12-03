#import "../../draw.typ"

// Draw mark at point with size
#let draw-mark-shape(pt, size, mark, style) = {
  let (sx, sy) = if type(size) != array {
    (size, size)
  } else { size }

  let bl(pt) = (rel: (-sx/2, -sy/2), to: pt)
  let br(pt) = (rel: (sx/2, -sy/2), to: pt)
  let tl(pt) = (rel: (-sx/2, sy/2), to: pt)
  let tr(pt) = (rel: (sx/2, sy/2), to: pt)
  let ll(pt) = (rel: (-sx/2, 0), to: pt)
  let rr(pt) = (rel: (sx/2, 0), to: pt)
  let tt(pt) = (rel: (0, sy/2), to: pt)
  let bb(pt) = (rel: (0, -sy/2), to: pt)

  if mark == "o" {
    draw.circle(pt, radius: (sx/2, sy/2), ..style)
  } else if mark == "square" {
    draw.rect(bl(pt), tr(pt), ..style)
  } else if mark == "triangle" {
    draw.line(bl(pt), br(pt), tt(pt), close: true, ..style)
  } else if mark == "*" or mark == "x" {
    draw.line(bl(pt), tr(pt), ..style)
    draw.line(tl(pt), br(pt), ..style)
  } else if mark == "+" {
    draw.line(ll(pt), rr(pt), ..style);
    draw.line(tt(pt), bb(pt), ..style)
  } else if mark == "-" {
    draw.line(ll(pt), rr(pt), ..style)
  } else if mark == "|" {
    draw.line(tt(pt), bb(pt), ..style)
  }
}

#let draw-mark(pts, x, y, mark, mark-size, plot-size) = {
  // Scale marks back to canvas scaling
  let (sx, sy) = plot-size
  sx = (x.max - x.min) / sx
  sy = (y.max - y.min) / sy
  sx *= mark-size
  sy *= mark-size

  for pt in pts {
    let (px, py, ..) = pt
    if px >= x.min and px <= x.max and py >= y.min and py <= y.max {
      draw-mark-shape(pt, (sx, sy), mark, (:))
    }
  }
}
