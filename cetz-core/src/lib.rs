use ciborium::de::from_reader;
use ciborium::ser::into_writer;
use serde::Deserialize;
use wasm_minimal_protocol::*;

initiate_protocol!();

type Point = Vec<f64>;

fn round(x: f64, digits: u32) -> f64 {
    let factor = 10.0_f64.powi(digits as i32);
    (x * factor).round() / factor
}

fn vector_add(a: Point, b: Point) -> Point {
    a.iter().zip(b.iter()).map(|(a, b)| a + b).collect()
}

fn vector_scale(a: Point, b: f64) -> Point {
    a.iter().map(|a| a * b).collect()
}

fn cubic_point(a: Point, b: Point, c1: Point, c2: Point, t: f64) -> Point {
    // (1-t)^3*a + 3*(1-t)^2*t*c1 + 3*(1-t)*t^2*c2 + t^3*b
    vector_add(
        vector_add(
            vector_scale(a, (1.0 - t).powi(3)),
            vector_scale(c1, 3.0 * (1.0 - t).powi(2) * t),
        ),
        vector_add(
            vector_scale(c2, 3.0 * (1.0 - t) * t.powi(2)),
            vector_scale(b, t.powi(3)),
        ),
    )
}

/// Compute roots of a single dimension (x, y, z) of the
/// curve by using the abc formula for finding roots of
/// the curves first derivative.
fn dim_extrema(a: f64, b: f64, c1: f64, c2: f64) -> Vec<f64> {
    let f0 = round(3.0 * (c1 - a), 8);
    let f1 = round(6.0 * (c2 - 2.0 * c1 + a), 8);
    let f2 = round(3.0 * (b - 3.0 * c2 + 3.0 * c1 - a), 8);

    if f1 == 0.0 && f2 == 0.0 {
        return vec![];
    }

    if f2 == 0.0 {
        return vec![-f0 / f1];
    }

    let d = f1 * f1 - 4.0 * f0 * f2;
    if d < 0.0 {
        return vec![];
    }

    if d == 0.0 {
        return vec![-f1 / (2.0 * f2)];
    }

    let sqrt_d = d.sqrt();
    let t1 = (-f1 - sqrt_d) / (2.0 * f2);
    let t2 = (-f1 + sqrt_d) / (2.0 * f2);
    vec![t1, t2]
}

fn cubic_extrema(s: Point, e: Point, c1: Point, c2: Point) -> Vec<Point> {
    let mut pts = Vec::new();
    let dims = std::cmp::max(s.len(), e.len());
    for dim in 0..dims {
        let ts = dim_extrema(s[dim], e[dim], c1[dim], c2[dim]);
        for t in ts {
            if t >= 0.0 && t <= 1.0 {
                let pt = cubic_point(s.clone(), e.clone(), c1.clone(), c2.clone(), t);
                pts.push(pt);
            }
        }
    }
    pts
}

#[derive(Deserialize)]
struct CubicExtremaArgs {
    s: Point,
    e: Point,
    c1: Point,
    c2: Point,
}

#[wasm_func]
pub fn cubic_extrema_func(input: &[u8]) -> Vec<u8> {
    match from_reader::<CubicExtremaArgs, _>(input) {
        Ok(input) => {
            let mut buf = Vec::new();
            let min = cubic_extrema(input.s, input.e, input.c1, input.c2);
            into_writer(&min, &mut buf).unwrap();
            buf
        }
        Err(e) => {
            println!("Error: {:?}", e);
            vec![]
        }
    }
}
