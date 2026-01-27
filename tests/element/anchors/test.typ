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
  display(line, (0,0), (2,1), (4,0))
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  display(circle, ())
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  display(circle-through, (-1,0), (0,1), (1,0))
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  display(arc, (0,0), start: 225deg, stop: 135deg, radius: 5, mode: "OPEN")
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  display(arc, (0,0), start: 225deg, stop: 135deg, radius: 5, mode: "PIE")
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  display(arc, (0,0), start: 225deg, stop: 135deg, radius: 5, mode: "CLOSE")
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  display(line, (-1,0), (0,1), (1,0))
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  display(grid, (-1,-1), (1,1), step: 1)
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  display(content, (), text(2cm)[Text])
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  display(rect, (-1,-1), (1,1))
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  display(rect, (-1,-1), (1,1), radius: .5)
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  display(bezier, (-2,0), (2,0), (-1,1), (1,-1))
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  display(bezier, (-1,-1), (1,-1), (0,2))
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  display(bezier-through, (-1,-1), (0,1), (1,-1))
}))

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  display(catmull, (-2,0), (-1,-1), (0,1), (1,-1), (2,0))
}))
