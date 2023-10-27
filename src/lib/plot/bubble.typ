#import "../../draw.typ"

#let _stroke(self, ctx) = {

    let (x,y) = (ctx.x, ctx.y)
    let plot-size = (10, 10)
    // Scale marks back to canvas scaling
    let (sx, sy) = plot-size
    sx = (x.max - x.min) / sx
    sy = (y.max - y.min) / sy

    for (idx, d) in self.data.enumerate() {
        // TO DO: Ignore points outside
        let size = (self.mark-size)(idx)
        draw.circle(d, radius: (size*sx, size*sy))
    }
}

#let add-bubble( data,
                 axes: ("x", "y"),
                 style: (:),
                 x-key: 0,
                 y-key: 1,
                 z-key: 2,
                 scale-factor: 1,
                 iterations: 0

) = {
    let pts = data.map(t=>{(t.at(x-key), t.at(y-key))})
    let sizes = array.at.with(data.map(t=>t.at(z-key)))
    
    // domains
    let calculate-domain(key) = {
        let min-most = calc.min(..data.map((it)=>{it.at(key) - (scale-factor*it.at(z-key)) }))
        let max-most = calc.max(..data.map((it)=>{it.at(key) + (scale-factor*it.at(z-key)) }))
        return (min-most, max-most)
    }

    let x-domain = calculate-domain(x-key)
    let y-domain = calculate-domain(y-key)

    // panic( (x-domain, y-domain))

    return ((
        type: "bubble",
        data: pts,
        axes: axes,
        style: style,
        mark-size: sizes,
        mark-style: style,
        x-domain: x-domain,
        y-domain: y-domain,
        x-key: x-key,
        y-key: y-key,
        z-key: z-key,
        scale-factor: scale-factor,
        plot-stroke: _stroke
    ),)

}