#import "/src/lib.typ": *
#import "/tests/helper.typ": *
#set page(width: auto, height: auto)

#let register-face() = {
  import draw: *

  register-mark("face", style => {
    circle((0,0), radius: .5, fill: yellow)
    arc((0,0), start: 180deg + 30deg, delta: 180deg - 60deg, anchor: "origin", radius: .3)
    circle((-.15, +.15), radius: .1, fill: white)
    circle((-.10, +.10), radius: .025, fill: black)
    circle((+.15, +.15), radius: .1, fill: white)
    circle((+.20, +.10), radius: .025, fill: black)

    anchor("tip", (+.5, 0))
    anchor("base", (-.5, 0))
  }, mnemonic: ":)")
}

#test-case({
  import draw: *

  register-face()
  catmull((-3, 0), (-1,1), (1,-1), (3,0), mark: (end: "face", flip: true, start: (symbol: ":)", flip: false, reverse: true), ))
})

#test-case({
  import draw: *

  line((0,-1), (0,1), stroke: green)

  register-face()
  mark((0,0), (+1,0), symbol: ":)", slant: 50%, anchor: "center")
})

#test-case({
  import draw: *

  register-face()
  line((0,0), (3,0), mark: (end: (":)", ":)", ":)"), flip: true, sep: -.3))
})
