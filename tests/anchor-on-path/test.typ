#set page(width: auto, height: auto)
#import "../../canvas.typ": *

#box(stroke: 2pt + red, canvas({
    import "../../draw.typ": *

    let place-along = (path) => {
      let name = "obj"
      place-anchors(path, name: name,
        ..range(0, 11).map(x => (name: str(x), pos: x / 10)))

      for x in range(0, 11) {
        circle(name + "." + str(x), radius: .1)
      }
    }


    translate((0, 0))
    place-along(circle((0,0)))

    translate((0, 2))
    place-along(bezier((-1,0), (1,0), (-.5,1), (.5,-1)))

    translate((0, 2))
    place-along(line((-1,0), (-.5,1), (.5,-1), (1,0)))

    translate((0, 2))
    place-along(rect((-1,0), (1,1)))

    translate((0, 2))
    place-along(merge-path(close: true, {
      line((0,0), (1,0))
      bezier((), (0,1), (1,1))
      line((0, 1), (-.5,1))
      arc((), start: 90deg, delta: 180deg, radius: .5)
    }))
}))
