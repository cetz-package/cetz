#import "@preview/cetz:0.2.0": canvas, draw, vector

#set page(width: auto, height: auto, margin: .5cm)

#let transform-rotate-dir(dir, up) = {
  dir = vector.norm(dir)
  up = vector.norm(up)

  let (dx, dy, dz) = dir
  let (ux, uy, uz) = up
  let (rx, ry, rz) = vector.norm(vector.cross(dir, up))

  ((rx, dx, ux, 0),
   (ry, dy, uy, 0),
   (rz, dz, uz, 0),
   (0,   0,  0, 1))
}

#canvas({
  import draw: *

  // Set up the transformation matrix
  set-transform(transform-rotate-dir((1, 1, -1.3), (0, 1, .3)))
  scale(x: 1.5, z: -1)

  grid((0,-2), (8,2), stroke: gray + .5pt)

  // Draw a sine wave on the xy plane
  let wave(amplitude: 1, fill: none, phases: 2, scale: 8, samples: 100) = {
    line(..(for x in range(0, samples + 1) {
      let x = x / samples
      let p = (2 * phases * calc.pi) * x
      ((x * scale, calc.sin(p) * amplitude),)
    }), fill: fill)

    let subdivs = 8
    for phase in range(0, phases) {
      let x = phase / phases
      for div in range(1, subdivs + 1) {
        let p = 2 * calc.pi * (div / subdivs)
        let y = calc.sin(p) * amplitude
        let x = x * scale + div / subdivs * scale / phases
        line((x, 0), (x, y), stroke: rgb(0, 0, 0, 150) + .5pt)
      }
    }
  }

  group({
    rotate(x: 90deg)
    wave(amplitude: 1.6, fill: rgb(0, 0, 255, 50))
  })
  wave(amplitude: 1, fill: rgb(255, 0, 0, 50))
})
