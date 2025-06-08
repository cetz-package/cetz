#[derive(Debug, Clone, Copy, Eq, PartialEq)]
struct TreeIndex(usize);

#[derive(Debug, Clone, Copy, PartialEq)]
struct Extremes {
    left: TreeIndex,
    right: TreeIndex,
    modifier_sum_left: f64,
    modifier_sum_right: f64,
}

impl NodeData {
    fn left_contour(&self) -> Option<TreeIndex> {
        if let Some((a, _)) = self.children {
            Some(TreeIndex(a))
        } else {
            self.left_thread
        }
    }
    fn right_contour(&self) -> Option<TreeIndex> {
        if let Some((_, b)) = self.children {
            Some(TreeIndex(b))
        } else {
            self.right_thread
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
struct NodeData {
    width: f64,
    height: f64,
    extremes: Option<Extremes>,
    left_thread: Option<TreeIndex>,
    right_thread: Option<TreeIndex>,
    x: Option<f64>,
    y: Option<f64>,
    parent: Option<TreeIndex>,
    own_index: TreeIndex,
    children: Option<(usize, usize)>,
    prelim: f64,
    modifier: f64,
    shift: f64,
    change: f64,
}

impl NodeData {
    fn bottom(&self) -> f64 {
        self.height + self.y.unwrap_or(0.0)
    }
}

#[derive(Debug, Clone, PartialEq)]
struct LayoutTree(Vec<NodeData>);

impl LayoutTree {
    fn get(&self, i: TreeIndex) -> &NodeData {
        &self.0[i.0]
    }

    fn get_mut(&mut self, i: TreeIndex) -> &mut NodeData {
        &mut self.0[i.0]
    }

    fn children(&self, i: TreeIndex) -> &[NodeData] {
        if let Some((a, b)) = self.get(i).children {
            &self.0[a..b]
        } else {
            &[]
        }
    }

    fn children_mut(&mut self, i: TreeIndex) -> &mut [NodeData] {
        if let Some((a, b)) = self.get(i).children {
            &mut self.0[a..b]
        } else {
            &mut []
        }
    }
    fn first_child_mut(&mut self, i: TreeIndex) -> &mut NodeData {
        let (a, _) = self.get(i).children.unwrap();
        &mut self.0[a]
    }

    fn last_child_mut(&mut self, i: TreeIndex) -> &mut NodeData {
        let (_, b) = self.get(i).children.unwrap();
        &mut self.0[b - 1]
    }

    fn first_child(&self, i: TreeIndex) -> &NodeData {
        let (a, _) = self.get(i).children.unwrap();
        &self.0[a]
    }

    fn last_child(&self, i: TreeIndex) -> &NodeData {
        let (_, b) = self.get(i).children.unwrap();
        &self.0[b - 1]
    }
    fn nth_child(&self, i: TreeIndex, n: usize) -> &NodeData {
        let (a, _) = self.get(i).children.unwrap();
        &self.0[a + n]
    }

    fn nth_child_mut(&mut self, i: TreeIndex, n: usize) -> &mut NodeData {
        let (a, _) = self.get(i).children.unwrap();
        &mut self.0[a + n]
    }

    fn children_ids(&self, i: TreeIndex) -> impl Iterator<Item = TreeIndex> {
        if let Some((a, b)) = self.get(i).children {
            a..b
        } else {
            0..0
        }
        .map(TreeIndex)
    }

    fn n_children(&self, i: TreeIndex) -> usize {
        match self.get(i).children {
            Some((a, b)) => b - a,
            None => 0,
        }
    }

    fn set_extremes(&mut self, i: TreeIndex) {
        let e = if self.n_children(i) == 0 {
            Extremes {
                left: i,
                right: i,
                modifier_sum_right: 0.0,
                modifier_sum_left: 0.0,
            }
        } else {
            let e_l = self.children(i).first().unwrap().extremes.unwrap();
            let e_r = self.children(i).last().unwrap().extremes.unwrap();
            Extremes {
                left: e_l.left,
                right: e_r.right,
                modifier_sum_right: e_l.modifier_sum_left,
                modifier_sum_left: e_r.modifier_sum_right,
            }
        };

        self.get_mut(i).extremes = Some(e);
    }

    fn first_walk(&mut self, i: TreeIndex) {
        if self.n_children(i) == 0 {
            self.set_extremes(i);
            return;
        }
        let mut children = self.children_ids(i);
        self.first_walk(children.next().unwrap());

        let mut ih = InnerYLeftSiblings::new(self.get(i).bottom(), 0);
        for (i, child) in children.enumerate().map(|(i, x)| (i + 1, x)) {
            self.first_walk(child);
            let min_y = self.get(self.get(child).extremes.unwrap().right).bottom();
            ih = ih.update(min_y, i);
        }

        self.position_root(i);
        self.set_extremes(i);
    }

    fn position_root(&mut self, i: TreeIndex) {
        let first = self.first_child(i);
        let last = self.last_child(i);
        let prelim = (first.prelim + first.modifier + last.prelim + last.modifier + last.width)
            / 2.0
            - self.get(i).width / 2.0;

        self.get_mut(i).prelim = prelim;
    }

    fn seperate(&mut self, i: TreeIndex, sib: usize, mut ih: InnerYLeftSiblings) {
        let sr = self.nth_child(i, sib - 1);
        let cl = self.nth_child(i, sib);
        let mut mssr = sr.modifier;
        let mut mscl = cl.modifier;
        //  Left contour node of current subtree and its sum of modfiers.
        let mut first = true;

        let mut sr = Some(sr.own_index);
        let mut cl = Some(cl.own_index);
        while let (Some(r), Some(l)) = (sr, cl) {
            if self.get(r).bottom() > ih.low_y().unwrap() {
                ih.become_next();
            }

            //  How far to the left of the right side of sr is the left side of cl?

            let r_n = self.get(r);
            let l_n = self.get(l);
            let dist = (mssr + r_n.prelim + r_n.width) - (mscl + l_n.prelim);
            if first && dist < 0.0 || dist > 0.0 {
                mscl += dist;
                self.move_subtree(i, sib, ih.id().unwrap(), dist);
                first = false;
            }
            let sy = self.get(r).bottom();
            let cy = self.get(l).bottom();

            if sy <= cy {
                sr = self.get(r).right_contour();
                if let Some(sr) = sr {
                    mssr += self.get(sr).modifier;
                }
            }
            if sy >= cy {
                cl = self.get(l).left_contour();
                if let Some(cl) = cl {
                    mscl += self.get(cl).modifier;
                }
            }
            /*
            //  Advance highest node(s) and sum(s) of modifiers
            if(sy <= cy){
               sr = nextRightContour(sr);
               if(sr!=null) mssr+=sr.mod;
            }
            if(sy >= cy){
               cl = nextLeftContour(cl);
               if(cl!=null) mscl+=cl.mod;
            }                                                              */
        }

        match (cl, sr) {
            (Some(cl), None) => self.set_left_thread(i, sib, cl, mscl),
            (None, Some(sr)) => self.set_right_thread(i, sib, sr, mssr),
            _ => (),
        }
        //  In this case, the left siblings must be taller than the current subtree.
    }

    fn set_right_thread(&mut self, i: TreeIndex, sib: usize, right: TreeIndex, modsumsr: f64) {
        let ri = self.nth_child(i, sib).extremes.unwrap().right;
        let diff = (modsumsr - self.get(right).modifier)
            - self.nth_child(i, sib).extremes.unwrap().modifier_sum_right;

        let ri = self.get_mut(ri);
        ri.right_thread = Some(right);
        ri.modifier += diff;
        ri.prelim -= diff;
        self.nth_child_mut(i, sib).extremes.unwrap().right =
            self.nth_child(i, sib - 1).extremes.unwrap().right;

        self.nth_child_mut(i, sib)
            .extremes
            .unwrap()
            .modifier_sum_right = self
            .nth_child(i, sib - 1)
            .extremes
            .unwrap()
            .modifier_sum_right;
    }
    fn set_left_thread(&mut self, i: TreeIndex, sib: usize, left: TreeIndex, modsumsr: f64) {
        let li = self.first_child(i).extremes.unwrap().left;
        let diff = (modsumsr - self.get(left).modifier)
            - self.first_child(i).extremes.unwrap().modifier_sum_right;

        let li = self.get_mut(li);
        li.left_thread = Some(left);
        li.modifier += diff;
        li.prelim -= diff;
        self.nth_child_mut(i, sib).extremes.unwrap().left =
            self.nth_child(i, sib).extremes.unwrap().left;

        self.first_child_mut(i).extremes.unwrap().modifier_sum_left =
            self.nth_child(i, sib).extremes.unwrap().modifier_sum_left;
    }

    fn move_subtree(&mut self, i: TreeIndex, sib: usize, ssib: usize, dist: f64) {
        let c = self.nth_child_mut(i, sib);
        c.modifier += dist;
        c.extremes.unwrap().modifier_sum_left += dist;
        c.extremes.unwrap().modifier_sum_right += dist;
        self.distribute_extra(i, sib, ssib, dist)
    }

    fn distribute_extra(&mut self, i: TreeIndex, sib: usize, ssib: usize, dist: f64) {
        if ssib != sib - 1 {
            let nr = (ssib - sib) as f64;
            let c_si = self.nth_child_mut(i, ssib + 1);
            c_si.shift += dist / nr;
            let c = self.nth_child_mut(i, sib);
            c.shift -= dist / nr;
            c.change -= dist - dist / nr;
        }
    }
}

struct InnerYLeftSiblings(Vec<(f64, usize)>);

impl InnerYLeftSiblings {
    fn new(min_y: f64, sibling_id: usize) -> Self {
        InnerYLeftSiblings(vec![(min_y, sibling_id)])
    }

    fn update(mut self, min_y: f64, sibling_id: usize) -> Self {
        while !self.is_null() && min_y > self.low_y().unwrap() {
            self.become_next();
        }
        self.0.push((min_y, sibling_id));
        self
    }

    fn low_y(&self) -> Option<f64> {
        self.0.last().map(|x| x.0)
    }
    fn id(&self) -> Option<usize> {
        self.0.last().map(|x| x.1)
    }

    fn is_null(&self) -> bool {
        self.0.is_empty()
    }

    fn next_peek(&self) -> Option<(f64, usize)> {
        self.0.get(self.0.len() - 2).copied()
    }

    fn become_next(&mut self) {
        self.0.pop();
    }
}

///Enum for serialization of a layout tree
#[derive(Debug, Clone, PartialEq)]
enum InputTree {
    Node { height: f64, width: f64 },
    Children(Vec<InputTree>),
}

///Enum for serialization of a layout tree
#[derive(Debug, Clone, PartialEq)]
enum OutputTree {
    Node { x: f64, y: f64 },
    Children(Vec<OutputTree>),
}

impl InputTree {
    pub fn layout(self) -> OutputTree {
        let mut tree: LayoutTree = self.into();
        tree.first_walk(TreeIndex(0));
        tree.into()
    }
}

impl LayoutTree {
    fn to_output(&self, i: TreeIndex) -> OutputTree {
        let node = self.get(i);
        let node = OutputTree::Node {
            x: node.x.unwrap(),
            y: node.y.unwrap(),
        };
        if self.n_children(i) == 0 {
            node
        } else {
            let mut v = vec![node];

            v.extend(self.children_ids(i).map(|i| self.to_output(i)));
            OutputTree::Children(v)
        }
    }
}

impl From<LayoutTree> for OutputTree {
    fn from(value: LayoutTree) -> Self {
        value.to_output(TreeIndex(0))
    }
}

impl From<InputTree> for LayoutTree {
    fn from(value: InputTree) -> Self {
        let mut tree = vec![None];
        let mut stack = vec![(None, TreeIndex(0), value)];
        while let Some((parent, position, node)) = stack.pop() {
            match node {
                InputTree::Node { height, width } => {
                    tree[position.0] = Some(NodeData {
                        width,
                        height,
                        x: None,
                        y: None,
                        parent,
                        own_index: position,
                        children: None,
                        extremes: None,
                        change: 0.0,
                        left_thread: None,
                        right_thread: None,
                        prelim: 0.0,
                        modifier: 0.0,
                        shift: 0.0,
                    });
                }
                InputTree::Children(children) => {
                    let n_children = children.len() - 1;
                    let mut children = children.into_iter();
                    let InputTree::Node { height, width } =
                        children.next().expect("Cannot have empty list as a child!")
                    else {
                        panic!("The first child must be  node!")
                    };

                    let children_start = tree.len();

                    stack.extend(
                        children
                            .enumerate()
                            .map(|(i, child)| (Some(position), TreeIndex(i + tree.len()), child)),
                    );
                    tree.extend(std::iter::repeat_n(None, n_children));
                    tree[position.0] = Some(NodeData {
                        width,
                        height,
                        x: None,
                        y: None,
                        parent,
                        extremes: None,
                        children: Some((children_start, children_start + n_children)),
                        own_index: position,
                        change: 0.0,
                        left_thread: None,
                        right_thread: None,
                        prelim: 0.0,
                        modifier: 0.0,
                        shift: 0.0,
                    });
                }
            }
        }
        dbg!(&tree);
        LayoutTree(
            tree.into_iter()
                .collect::<Option<Vec<_>>>()
                .expect("The tree cannot plan to have children that it does not make!"),
        )
    }
}

#[cfg(test)]
mod test {
    use crate::layout;

    use super::*;

    impl InputTree {
        fn empty_node() -> InputTree {
            InputTree::Node {
                height: 0.0,
                width: 0.0,
            }
        }
    }

    fn check_trees_are_same(tree: InputTree, layout_tree: LayoutTree) {
        let mut tree_stack = vec![tree];
        let mut layout_stack = vec![TreeIndex(0)];
        while let (Some(id), Some(input_tree)) = (layout_stack.pop(), tree_stack.pop()) {
            let x = layout_tree.get(id);
            layout_stack.extend(layout_tree.children(id).iter().map(|x| x.own_index));
            match input_tree {
                InputTree::Node { height, width } => {
                    assert_eq!(x.height, height);
                    assert_eq!(x.width, width);
                }
                InputTree::Children(input_trees) => {
                    tree_stack.extend(input_trees.into_iter().skip(1));
                }
            }
        }
        assert!(layout_stack.is_empty());
        assert!(tree_stack.is_empty());
    }

    #[test]
    fn from_cetz_style() {
        let tree = InputTree::Children(vec![
            InputTree::empty_node(),
            InputTree::Children(vec![
                InputTree::empty_node(),
                InputTree::Children(vec![InputTree::empty_node(), InputTree::empty_node()]),
                InputTree::empty_node(),
                InputTree::Children(vec![InputTree::empty_node(), InputTree::empty_node()]),
            ]),
            InputTree::empty_node(),
            InputTree::Children(vec![InputTree::empty_node(), InputTree::empty_node()]),
        ]);
        let layout_tree: LayoutTree = tree.clone().into();
        check_trees_are_same(tree, layout_tree);
    }

    #[test]
    fn layout_test() {
        let tree = InputTree::Children(vec![
            InputTree::empty_node(),
            InputTree::Children(vec![
                InputTree::empty_node(),
                InputTree::Children(vec![InputTree::empty_node(), InputTree::empty_node()]),
                InputTree::empty_node(),
                InputTree::Children(vec![InputTree::empty_node(), InputTree::empty_node()]),
            ]),
            InputTree::empty_node(),
            InputTree::Children(vec![InputTree::empty_node(), InputTree::empty_node()]),
        ]);
        let x = tree.layout();
    }
}
