#import plugin("cetz_core.wasm"): double_it, scale, minimum

// #double_it(bytes("hello"))

#let point = (2, 2, 4)
#let encoded = cbor.encode(point)
#let scaled = scale(encoded)
#let decoded = cbor(scaled)
#decoded

#let points = (
  (1, 2, 4),
  (4, 5, 6),
  (7, 8, 9),
)

#let args = (points: points, point: point)
#let encoded = cbor.encode(args)
#let minimum = cbor(minimum(encoded))
#minimum