#import "matrix.typ"

#let as-vec4(v) = {
  return (v.at(0), v.at(1), if v.len() >= 3 { v.at(2) } else {0}, 1)
}

#let vec4-to2(v) = {
  (v.at(0), v.at(1))
}

#let vec4-len(v) = {
  return calc.sqrt(v.fold(0, (n,  x) => n + calc.pow(x, 2)))
}

#let vec4-norm(v) = {
  let len = vec4-len(v)
  if len == 0 { v }
  v.map(x => x / len)
}

#let vec4-diff(a, b) = {
  let c = ()
  for i in range(0, a.len()) {
    c.push(a.at(i) - b.at(i))
  }
  c
}

#let vec4-add(a, b) = {
  for i in range(0, a.len()) {
    a.at(i) += b.at(i)
  }
  a
}

#let vec4-sub(a, b) = {
  for i in range(0, a.len()) {
    a.at(i) -= b.at(i)
  }
  a
}

#let vec4-mul(a, n) = {
  a.map(x => x * n)
}

#let vec4-cross(a, b) = {
  (  a.at(1) * b.at(2) - a.at(2) * b.at(1),
   -(a.at(0) * b.at(2) - a.at(2) * b.at(0)),
     a.at(0) * b.at(1) - a.at(1) * b.at(0), 0)
}

#let draw-content(ctx, pt, content, position: auto, handle-x: .5, handle-y: .5) = {
  let (x, y, z, _) = as-vec4(pt)

  if position == "bellow" { handle-y = 0 }
  if position == "above"  { handle-y = 1 }
  if position == "left"   { handle-x = 1 }
  if position == "right"  { handle-x = 0 }
  if position == "on"     { handle-x = .5; handle-y = .5 }    

  let bounds = measure(content, ctx.style)
  let w = bounds.width / ctx.length
  let h = bounds.height / ctx.length
  x -= w * handle-x
  y -= h * handle-y

  let tl = (x, y, z, 1)
  let tr = (x + w, y, z, 1)
  let bl = (x, y + h, z, 1)
  let br = (x + w, y + h, z, 1)
  
  ((cmd: "content", pos: ((x, y, z, 1),), content: content, bounds: (tl, tr, bl, br)), )
}

#let draw-mark(pt, dir, norm, mark, stroke, fill, size: .2) = {
  if mark == none { return }

  let (x, y, z, w) = (..pt)
  let pts = ()

  if mark.at(0) == ">" {
    pts.push(vec4-add(vec4-add(pt, vec4-mul(dir, -size)), vec4-mul(norm, size/2)))
    pts.push(pt)
    pts.push(vec4-add(vec4-add(pt, vec4-mul(dir, -size)), vec4-mul(norm, size/-2)))
  } else if mark.at(0) == "<" {
    pt = vec4-sub(pt, vec4-mul(dir, size))
    pts.push(vec4-add(vec4-add(pt, vec4-mul(dir, size)), vec4-mul(norm, size/2)))
    pts.push(pt)
    pts.push(vec4-add(vec4-add(pt, vec4-mul(dir, size)), vec4-mul(norm, size/-2)))
  } 

  ((cmd: "line", pos: pts, fill: fill, stroke: stroke, close: false, bounds: (pt,)), )
}

#let draw-line(..pt, stroke: auto, fill: auto, start-mark: none, end-mark: none, close: false) = {
  pt = (..pt.pos().map(as-vec4))

  ((cmd: "line", pos: (..pt), fill: fill, stroke: stroke, close: close, bounds: (..pt)), )

  if pt.len() >= 2 {
    let n = pt.len() - 1

    let start-dir = vec4-norm(vec4-diff(pt.at(0), pt.at(1)))
    let end-dir = vec4-norm(vec4-diff(pt.at(pt.len() - 1), pt.at(pt.len() - 2)))

    // HACK: This is a _very_ dumb for finding normals for z-lines
    let start-norm = (-start-dir.at(1) + start-dir.at(2), start-dir.at(0), start-dir.at(2), 0)
    let end-norm = (-end-dir.at(1) + end-dir.at(2), end-dir.at(0), end-dir.at(2), 0)
    
    draw-mark(pt.at(0), start-dir, start-norm, start-mark, stroke, fill)
    draw-mark(pt.at(pt.len() - 1), end-dir, end-norm, end-mark, stroke, fill)
  }
}

#let canvas(length: 1cm, fill: none,
  scale: (x: 1, y: 1, z: 1),
  rotate: (x: 0, z: 0), ..body) = {
  style(st => {

  let transform = (
    scale: matrix.transform-scale(scale),
    translate: none,
    rotate: matrix.transform-rotate-xz(rotate.x, rotate.z),
  )

  let apply-transform(queue, vec) = {
    for m in queue.values() {
      if m != none {
        vec = matrix.mul-vec(m, vec)
      }
    }
    return vec
  }

  let bounds = (l: 0cm, r: 0cm, t: 0cm, b: 0cm)

  let ctx = (style: st, length: length)
  
  let drawables = ()
  for b in body.pos() {
    let transform-stack = (transform, )
    let state-stack = ((stroke: 1pt + black, fill: none), )

    for element in b(ctx) {
      let cmd = element.cmd
      if cmd == "rotate-xz" {
        transform-stack.last().rotate = matrix.transform-rotate-xz(element.x, element.z)
      } else if cmd == "rotate-xyz" {
        transform-stack.last().rotate = matrix.transform-rotate-xyz(element.x, element.y, element.z)
      } else if cmd == "scale" {
        transform-stack.last().scale = matrix.transform-scale((x: element.x, y: element.y, z: element.z))
      } else if cmd == "translate" {
        transform-stack.last().translate = matrix.transform-translate(element.x, element.y, element.z)
      } else if cmd == "push" {
        transform-stack.push(transform-stack.last())
        state-stack.push(state-stack.last())
      } else if cmd == "pop" {
        if transform-stack.len() > 1 {let _ = transform-stack.pop()}
        if state-stack.len() > 1 {let _ = state-stack.pop()}
      } else if cmd == "reset" {
        transform-stack = (transform, )
        state-stack = ((stroke: 1pt + black, fill: none), )
      } else if cmd == "stroke" {
        state-stack.last().stroke = element.stroke
      } else if cmd == "fill" {
        state-stack.last().fill = element.fill
      }

      let cur-transform = transform-stack.last()
      let cur-state = state-stack.last()

      if "pos" in element {
        element.pos = element.pos.map(x => apply-transform(cur-transform, x))
        if "stroke" in element and element.stroke == auto { element.stroke = cur-state.stroke }
        if "fill" in element and element.fill == auto { element.fill = cur-state.fill }
        drawables.push(element)
      }

      if "bounds" in element {
        for pt in element.bounds.map(x => apply-transform(cur-transform, x).map(x => length * x)) {
          bounds.l = calc.min(bounds.l, pt.at(0))
          bounds.r = calc.max(bounds.r, pt.at(0))
          bounds.t = calc.min(bounds.t, pt.at(1))
          bounds.b = calc.max(bounds.b, pt.at(1))
        }
      }
    }
  }

  let width = calc.abs(bounds.r - bounds.l)
  let height = calc.abs(bounds.t - bounds.b)
  
  let offset = (
    x: 0cm - bounds.l,
    y: 0cm - bounds.t,
  )
  let translate = matrix.transform-translate(offset.x / length, offset.y / length, 0)

  let draw = (
    line: (self, ..pos) => {
      place(path(stroke: self.stroke, fill: self.fill, closed: self.close, ..pos))
    },
    content: (self, ..pos) => {
      let pt = pos.pos().at(0)
      let (xx, yy) = (..pt)
      place(dx: xx, dy: yy, self.content)
    }
  );
  
  box(width: width, height: height, fill: fill, {
    for d in drawables {
      draw.at(d.cmd)(d, ..d.pos.map(v =>
        apply-transform((translate: translate), v).slice(0, 2).map(x => length * x)))
    }
  })
})}

#canvas(fill: gray, length: 0.5cm, rotate: (x: 70, z: -30), ctx => {
  draw-line((-5, 0, 0), (5, 0, 0), end-mark: ">", start-mark: ">")
  draw-line((0,-5, 0),  (0, 5, 0), end-mark: ">", start-mark: ">")
  draw-line((0, 0, -6), (0, 0, 6), end-mark: ">", start-mark: ">")

  for i in range(-5, 5+1) {
    //draw-line((0, -.1, i), (0, .1, i))
    draw-line((i, -.1, 0), (i, .1, 0))
    draw-line((-.1, i, 0), (.1, i, 0))
  }

  for i in range(0, 360, step: 20) {
    let a = calc.pi/180*i
  draw-line((2*calc.cos(a), 2*calc.sin(a), 0), (3*calc.cos(a), 3*calc.sin(a), 0), end-mark: ">", start-mark: ">")
  }

  draw-line(stroke: red, ..range(1, 1000).map(t => {
    return (calc.cos(t/10), -3 + t/1000*6, calc.sin(t/10))
  }))
  
  draw-content(ctx, (0, 0, 3), [Z=5])
})

#canvas(fill: gray, length: 3cm, rotate: (x: 70, z: -30), ctx => {
  draw-line((0,0,0), (1,0,0), end-mark: ">")
  draw-line((0,0,0), (0,1,0), end-mark: ">")
  draw-line((0,0,0), (0,0,1), end-mark: ">")


  ((cmd: "translate", x: 0, y: 1, z: 0), )
  ((cmd: "push"), )

  ((cmd: "rotate-xz", x: 0, z: 0), )
  ((cmd: "stroke", stroke: blue), )
  ((cmd: "fill", fill: blue), )

  ((cmd: "translate", x: -2, y: -2, z: 1), )
  ((cmd: "scale", x: 2, y: 2, z: 2), )

  draw-line((0,0,0), (1,0,0), end-mark: ">", stroke: red)
  draw-line((0,0,0), (0,1,0), end-mark: ">", stroke: green)
  draw-line((0,0,0), (0,0,1), end-mark: ">")

  ((cmd: "pop"), )
  ((cmd: "reset"), )
  ((cmd: "scale", x: .5, y: 1, z: 0), )

  draw-line((0,0,0), (1,0,0), end-mark: ">", stroke: red)
  draw-line((0,0,0), (0,1,0), end-mark: ">", stroke: green)
  draw-line((0,0,0), (0,0,1), end-mark: ">")
})
