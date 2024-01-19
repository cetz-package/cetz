#set page(width: auto, height: auto)
#import "/src/lib.typ": *


#let display(body, ..args) = {
  import draw: *
  (body)(..args, name: "elem");
  get-ctx(ctx => {
    for-each-anchor(
      "elem",
      exclude: if args.named().at("mode", default: none) == "OPEN" {
        ("east", "north-east", "north", "south", "south-east")
      } else {()},
      o => {
        let n = "elem." + o

        group({
          rotate(45deg)
          set-style(stroke: blue)
          line((rel: (-.1, 0), to: n), (rel: (.2, 0)))
          line((rel: (0, -.1), to: n), (rel: (0, .2)))
        })

        let (_, nv) = coordinate.resolve(ctx, n)
        let (x, y, ..) = nv
        let anchor = (
          (if y < 0 { "north" } else if y > 0 { "south" },) + (if x < 0 { "east" } else if x > 0 { "west" },)
          ).filter(p => p != none).join("-")
        if anchor == none {
          anchor = "south"
        }

        content(n, text(8pt, o), anchor: anchor, padding: .2)
      }
    )
  })
}


#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  display(grid, (-1,-1), (1,1), step: 1)
}))