#set page(width: auto, height: auto)
#import "../../canvas.typ": *

#let data = (
  `/`,
    `/bin`, `/dev`, `/etc`,
    (`/usr`,
      `/bin`, `/include`),
    `/mnt`, `/opt`
)

#box(stroke: 2pt + red, canvas({
  import "../../draw.typ": *
  import "../../tree.typ": *

  tree(data, direction: "bottom",
       spread: 2, grow: 2, draw-node: "rect",
       content: (padding: .1))
}))
