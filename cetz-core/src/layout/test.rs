use super::*;
use rand::{distr::weighted::WeightedIndex, prelude::*};
use rand_chacha::ChaCha8Rng;

fn random_tree(rng: &mut impl Rng) -> InputTree {
    let weights = [10.0, 5.0, 2.5, 1.25, 0.75, 0.375, 0.1875];
    let dist = WeightedIndex::new(weights).unwrap();
    fn random_tree_inner(dist: &WeightedIndex<f64>, rng: &mut impl Rng) -> InputTree {
        InputTree {
            height: rng.random::<f64>() * 100.0 + 0.5,
            width: rng.random::<f64>() * 100.0 + 0.5,
            children: (0..dist.sample(rng))
                .map(|_| random_tree_inner(dist, rng))
                .collect::<Vec<_>>(),
        }
    }
    random_tree_inner(&dist, rng)
}

impl InputTree {
    fn new(width: f64, height: f64) -> Self {
        InputTree {
            width,
            height,
            children: vec![],
        }
    }

    fn with_children(mut self, children: Vec<Self>) -> Self {
        self.children = children;
        self
    }
}

#[derive(Debug, Clone, Copy, PartialEq)]
struct BBox {
    xmin: f64,
    ymin: f64,
    xmax: f64,
    ymax: f64,
}
impl BBox {
    fn overlaps(&self, other: &BBox) -> bool {
        self.xmin < other.xmax
            && other.xmin < self.xmax
            && self.ymin < other.ymax
            && other.ymin < self.ymax
    }
}

#[derive(Debug, Clone, Copy, PartialEq)]
struct Line {
    origin: (f64, f64),
    dest: (f64, f64),
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Orientation {
    Collinear,
    Clockwise,
    Counterclockwise,
}
fn orientation(p: (f64, f64), q: (f64, f64), r: (f64, f64)) -> Orientation {
    let val = (q.1 - p.1) * (r.0 - q.0) - (q.0 - p.0) * (r.1 - q.1);
    if val.abs() < f64::EPSILON {
        Orientation::Collinear
    } else if val > 0.0 {
        Orientation::Clockwise
    } else {
        Orientation::Counterclockwise
    }
}
fn on_segment(p: (f64, f64), q: (f64, f64), r: (f64, f64)) -> bool {
    q.0 <= p.0.max(r.0) && q.0 >= p.0.min(r.0) && q.1 <= p.1.max(r.1) && q.1 >= p.1.min(r.1)
}

impl Line {
    fn intersects(&self, other: &Line) -> bool {
        let o1 = orientation(self.origin, self.dest, other.origin);
        let o2 = orientation(self.origin, self.dest, other.dest);
        let o3 = orientation(other.origin, other.dest, self.origin);
        let o4 = orientation(other.origin, other.dest, self.dest);

        if self.origin == other.origin && self.dest != other.dest && o2 != Orientation::Collinear {
            return false;
        }

        if o1 != o2 && o3 != o4 {
            return true;
        }

        if o1 == Orientation::Collinear && on_segment(self.origin, other.origin, self.dest) {
            return true;
        }
        if o2 == Orientation::Collinear && on_segment(self.origin, other.dest, self.dest) {
            return true;
        }
        if o3 == Orientation::Collinear && on_segment(other.origin, self.origin, other.dest) {
            return true;
        }
        if o4 == Orientation::Collinear && on_segment(other.origin, self.dest, other.dest) {
            return true;
        }

        false
    }
}

impl OutputTree {
    fn children_lines<'a>(&'a self) -> impl Iterator<Item = Line> + 'a {
        let origin = (self.x, self.y + self.height);
        self.children.iter().map(move |child| Line {
            origin,
            dest: (child.x, child.y),
        })
    }
}

fn no_aesthetic_problem(tree: &OutputTree) -> bool {
    let mut tree_stack = vec![tree];
    let mut boxes = vec![];
    let mut lines = vec![];
    while let Some(subtree) = tree_stack.pop() {
        lines.extend(subtree.children_lines());

        let OutputTree {
            height,
            width,
            x,
            y,
            children,
        } = subtree;

        boxes.push(BBox {
            xmin: x - width / 2.0,
            ymin: *y,
            xmax: x + width / 2.0,
            ymax: *height,
        });

        tree_stack.extend(children.iter());
    }

    while let Some(bbox) = boxes.pop() {
        for other in boxes.iter() {
            if bbox.overlaps(other) {
                println!("bad bbox: {bbox:?} and {other:?}");
                return false;
            }
        }
    }
    while let Some(line) = lines.pop() {
        for other in lines.iter() {
            if line.intersects(other) {
                println!("bad lines: {line:?} and {other:?}");
                return false;
            }
        }
    }

    true
}

impl OutputTree {
    fn to_typst(&self, rng: &mut ChaCha8Rng) -> String {
        let colors = [
            "green", "blue", "red", "yellow", "orange", "purple", "teal", "lime", "aqua",
        ];
        let s = format!(
            "block(height: {}pt, width: {}pt, fill: {}.transparentize(50%), [])",
            self.height,
            self.width,
            colors.choose(rng).unwrap()
        );

        if self.children.is_empty() {
            s
        } else {
            format!(
                "({s}, {})",
                self.children
                    .iter()
                    .map(|t| t.to_typst(rng))
                    .collect::<Vec<_>>()
                    .join(", ")
            )
        }
    }
}

#[test]
fn check_random_trees_are_good() {
    let mut rng = ChaCha8Rng::seed_from_u64(0);
    for _ in 0..100 {
        let tree = random_tree(&mut rng);
        let output_tree = tree.layout(1., 1.);
        if !no_aesthetic_problem(&output_tree) {
            panic!("This tree is bad: {}", output_tree.to_typst(&mut rng));
        }
    }
}

fn check_trees_are_same(tree: &InputTree, layout_tree: &LayoutTree) {
    let mut tree_stack = vec![tree];
    let mut layout_stack = vec![TreeIndex(0)];
    while let (Some(id), Some(input_tree)) = (layout_stack.pop(), tree_stack.pop()) {
        let InputTree {
            height,
            width,
            children,
        } = input_tree;
        let x = layout_tree.get(id);
        assert_eq!(x.height, *height);
        assert_eq!(x.width, *width);

        layout_stack.extend(layout_tree.children_ids(id));
        tree_stack.extend(children.iter());
    }
    assert!(layout_stack.is_empty());
    assert!(tree_stack.is_empty());
}

#[test]
fn check_importing() {
    let t = InputTree::new(30.0, 50.0).with_children(vec![
        InputTree::new(40.0, 70.0).with_children(vec![
            InputTree::new(50.0, 60.0),
            InputTree::new(50.0, 100.0),
        ]),
        InputTree::new(20.0, 140.0)
            .with_children(vec![InputTree::new(50.0, 60.0), InputTree::new(50.0, 60.0)]),
        InputTree::new(50.0, 60.0)
            .with_children(vec![InputTree::new(50.0, 60.0), InputTree::new(50.0, 60.0)]),
    ]);
    let layout_tree: LayoutTree = t.clone().into();
    dbg!(&layout_tree);
    check_trees_are_same(&t, &layout_tree);

    t.layout(0.0, 0.0);
}
