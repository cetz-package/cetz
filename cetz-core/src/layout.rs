//! This module provides an algorithm to layout a tree so that the nodes of varying heights and
//! weights are laid out aesthetically without wasting space. It follows the algorithm of van der
//! Ploeg (2014) and its [accompanying public domain code](https://github.com/cwi-swat/non-layered-tidy-trees/tree/master)
//!
//! The nodes are laid out such that their anchor is at the middle top of the node.
//!
//! van der Ploeg, A. (2014). Drawing non-layered tidy trees in linear time. Software: Practice and Experience, 44(12), 1467–1484. https://doi.org/10.1002/spe.2213

use serde::{Deserialize, Serialize};

///A struct which points to specific nodes relative to [`LayoutTree`]. This way, we avoid using
///any references that might cause difficulties with the borrow checker.
#[derive(Debug, Clone, Copy, Eq, PartialEq)]
struct TreeIndex(usize);

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
            Some(TreeIndex(b - 1))
        } else {
            self.right_thread
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
struct NodeData {
    width: f64,
    height: f64,
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
    extreme_left: Option<TreeIndex>,
    extreme_right: Option<TreeIndex>,
    modifier_sum_left: f64,
    modifier_sum_right: f64,
}

impl NodeData {
    fn bottom(&self, tree: &LayoutTree) -> f64 {
        self.height + self.y.unwrap() + tree.vertical_margin
    }

    fn width(&self, tree: &LayoutTree) -> f64 {
        self.width + tree.horizontal_margin
    }
}

/// This struct holds all nodes.
/// The tree is arena-allocated to avoid issues with mutating references.
#[derive(Debug, Clone, PartialEq)]
struct LayoutTree {
    tree: Vec<NodeData>,
    vertical_margin: f64,
    horizontal_margin: f64,
}

impl LayoutTree {
    fn get(&self, i: TreeIndex) -> &NodeData {
        &self.tree[i.0]
    }

    fn get_mut(&mut self, i: TreeIndex) -> &mut NodeData {
        &mut self.tree[i.0]
    }

    fn first_child_mut(&mut self, i: TreeIndex) -> &mut NodeData {
        let (a, _) = self.get(i).children.unwrap();
        &mut self.tree[a]
    }

    fn first_child(&self, i: TreeIndex) -> &NodeData {
        let (a, _) = self.get(i).children.unwrap();
        &self.tree[a]
    }

    fn last_child(&self, i: TreeIndex) -> &NodeData {
        let (_, b) = self.get(i).children.unwrap();
        &self.tree[b - 1]
    }

    fn nth_child_id(&self, i: TreeIndex, n: usize) -> TreeIndex {
        let (a, _) = self.get(i).children.unwrap();
        TreeIndex(a + n)
    }

    fn nth_child(&self, i: TreeIndex, n: usize) -> &NodeData {
        let (a, _) = self.get(i).children.unwrap();
        &self.tree[a + n]
    }

    fn nth_child_mut(&mut self, i: TreeIndex, n: usize) -> &mut NodeData {
        let (a, _) = self.get(i).children.unwrap();
        &mut self.tree[a + n]
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
        if self.n_children(i) == 0 {
            let n = self.get_mut(i);
            n.extreme_right = Some(i);
            n.extreme_left = Some(i);
            n.modifier_sum_right = 0.0;
            n.modifier_sum_left = 0.0;
        } else {
            let e_l = self.first_child(i);
            let extreme_left = e_l.extreme_left;
            let modifier_sum_left = e_l.modifier_sum_left;

            let e_r = self.last_child(i);
            let extreme_right = e_r.extreme_right;
            let modifier_sum_right = e_r.modifier_sum_right;
            let n = self.get_mut(i);
            n.extreme_right = extreme_right;
            n.extreme_left = extreme_left;
            n.modifier_sum_right = modifier_sum_right;
            n.modifier_sum_left = modifier_sum_left;
        };
    }

    fn first_walk(&mut self, i: TreeIndex) {
        if self.n_children(i) == 0 {
            self.set_extremes(i);
            return;
        }
        self.first_walk(self.nth_child_id(i, 0));

        let left_bottom = self
            .get(self.get(self.nth_child_id(i, 0)).extreme_left.unwrap())
            .bottom(self);
        let mut ih = vec![(0, left_bottom)];

        for sib in 1..self.n_children(i) {
            let child_id = self.nth_child_id(i, sib);
            self.first_walk(child_id);
            let min_y = self
                .get(self.get(child_id).extreme_right.unwrap())
                .bottom(self);
            self.seperate(i, sib, &ih);
            while ih.last().is_some() && min_y >= ih.last().unwrap().1 {
                ih.pop();
            }
            ih.push((sib, min_y));
        }

        self.position_root(i);
        self.set_extremes(i);
    }

    fn second_walk(&mut self, i: TreeIndex, mut modsum: f64) -> f64 {
        modsum += self.get(i).modifier;
        self.get_mut(i).x = Some(self.get(i).prelim + modsum);
        let mut min_x = self.get(i).x.unwrap();
        self.add_child_spacing(i);
        for child in self.children_ids(i) {
            let c_min = self.second_walk(child, modsum);
            if c_min < min_x {
                min_x = c_min;
            }
        }
        min_x
    }

    fn third_walk(&mut self, i: TreeIndex, shift: f64) {
        *self.get_mut(i).x.as_mut().unwrap() += shift;
        for child in self.children_ids(i) {
            self.third_walk(child, shift);
        }
    }

    fn add_child_spacing(&mut self, i: TreeIndex) {
        let mut d = 0.0;
        let mut modsumdelta = 0.0;
        for child in self.children_ids(i) {
            d += self.get(child).shift;
            modsumdelta += d + self.get(child).change;
            self.get_mut(child).modifier += modsumdelta;
        }
    }

    fn position_root(&mut self, i: TreeIndex) {
        let first = self.first_child(i);
        let last = self.last_child(i);
        let prelim = (first.prelim + first.modifier - first.width(self) / 2.0
            + last.prelim
            + last.modifier
            + last.width(self) / 2.0)
            / 2.0;

        self.get_mut(i).prelim = prelim;
    }

    fn seperate(&mut self, i: TreeIndex, sib: usize, mut ih: &[(usize, f64)]) {
        let sr = self.nth_child(i, sib - 1);
        let cl = self.nth_child(i, sib);
        let mut mssr = sr.modifier;
        let mut mscl = cl.modifier;
        let mut first = true;

        let mut sr = Some(sr.own_index);
        let mut cl = Some(cl.own_index);

        while let (Some(r), Some(l)) = (sr, cl) {
            if self.get(r).bottom(self) > ih.last().unwrap().1 {
                ih = &ih[0..ih.len() - 1]
            }

            let r_n = self.get(r);
            let l_n = self.get(l);
            let dist = (mssr + r_n.prelim) - (mscl + l_n.prelim)
                + (r_n.width(self) + l_n.width(self)) / 2.0;

            if dist > 0.0 || (dist < 0.0 && first) {
                mscl += dist;
                self.move_subtree(i, sib, dist);
                self.distribute_extra(i, sib, ih.last().unwrap().0, dist);
            }
            first = false;
            let sy = self.get(r).bottom(self);
            let cy = self.get(l).bottom(self);

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
        }

        match (cl, sr) {
            (Some(cl), None) => self.set_left_thread(i, sib, cl, mscl),
            (None, Some(sr)) => self.set_right_thread(i, sib, sr, mssr),
            _ => (),
        }
        //  In this case, the left siblings must be taller than the current subtree.
    }

    fn set_right_thread(&mut self, i: TreeIndex, sib: usize, right: TreeIndex, modsumsr: f64) {
        let ri = self.nth_child(i, sib).extreme_right.unwrap();
        let diff =
            (modsumsr - self.get(right).modifier) - self.nth_child(i, sib).modifier_sum_right;

        let ri = self.get_mut(ri);
        ri.right_thread = Some(right);
        ri.modifier += diff;
        ri.prelim -= diff;
        self.nth_child_mut(i, sib).extreme_right = self.nth_child(i, sib - 1).extreme_right;

        self.nth_child_mut(i, sib).modifier_sum_right =
            self.nth_child(i, sib - 1).modifier_sum_right;
    }
    fn set_left_thread(&mut self, i: TreeIndex, sib: usize, left: TreeIndex, modsumcl: f64) {
        let li = self.first_child(i).extreme_left.unwrap();
        let diff = (modsumcl - self.get(left).modifier) - self.first_child(i).modifier_sum_left;

        let li = self.get_mut(li);
        li.left_thread = Some(left);
        li.modifier += diff;
        li.prelim -= diff;
        self.first_child_mut(i).extreme_left = self.nth_child(i, sib).extreme_left;

        self.first_child_mut(i).modifier_sum_left = self.nth_child(i, sib).modifier_sum_left;
    }

    fn move_subtree(&mut self, i: TreeIndex, sib: usize, dist: f64) {
        let c = self.nth_child_mut(i, sib);
        c.modifier += dist;
        c.modifier_sum_left += dist;
        c.modifier_sum_right += dist;
    }

    fn distribute_extra(&mut self, i: TreeIndex, sib: usize, ssib: usize, dist: f64) {
        if ssib != sib - 1 {
            let n = (sib - ssib) as f64;
            let c_si = self.nth_child_mut(i, ssib + 1);
            c_si.shift += dist / n;
            let c = self.nth_child_mut(i, sib);
            c.shift -= dist / n;
            c.change -= dist - dist / n;
        }
    }

    fn set_y(&mut self, i: TreeIndex, y: f64) {
        self.get_mut(i).y = Some(y);
        for child in self.children_ids(i) {
            self.set_y(child, y + self.get(i).height + self.vertical_margin);
        }
    }
}

///Enum for serialization of a layout tree, providing height and width of a tree
#[derive(Debug, Clone, PartialEq, Deserialize)]
pub struct InputTree {
    height: f64,
    width: f64,
    children: Vec<InputTree>,
}

///Enum for deserialization of a layout tree providing x, y values for nodes
#[derive(Debug, Clone, PartialEq, Serialize)]
pub struct OutputTree {
    x: f64,
    y: f64,
    height: f64,
    width: f64,
    children: Vec<OutputTree>,
}

impl InputTree {
    ///Takes an [`InputTree`] and returns an [`OutputTree`] which has been laid out.
    ///The two arguments add padding between nodes either vertically or horizontally (concretely,
    ///it amounts to increasing the width and height of all nodes by the relevant margin).
    pub fn layout(self, vertical_margin: f64, horizontal_margin: f64) -> OutputTree {
        let mut tree: LayoutTree = self.into();
        tree.horizontal_margin = horizontal_margin;
        tree.vertical_margin = vertical_margin;

        tree.set_y(TreeIndex(0), 0.0);

        tree.first_walk(TreeIndex(0));
        let min_x = tree.second_walk(TreeIndex(0), 0.0);
        if min_x != 0.0 {
            tree.third_walk(TreeIndex(0), -min_x)
        }
        tree.into()
    }
}

impl LayoutTree {
    fn to_output(&self, i: TreeIndex) -> OutputTree {
        let n = self.get(i);
        OutputTree {
            x: n.x.unwrap(),
            y: n.y.unwrap(),
            height: n.height,
            width: n.width,
            children: self.children_ids(i).map(|i| self.to_output(i)).collect(),
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
        //We initially use `Vec<Option<NodeData>>` as we need to progressively add nodes before we
        //have their children. We can thus add `None` and refer to its index, and latter fill it in.
        let mut tree = vec![None];

        let mut stack = vec![(None, TreeIndex(0), value)];
        while let Some((parent, position, node)) = stack.pop() {
            let InputTree {
                height,
                width,
                children,
            } = node;

            let n_children = children.len();
            let children_start = tree.len();

            stack.extend(
                children
                    .into_iter()
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
                children: if n_children != 0 {
                    Some((children_start, children_start + n_children))
                } else {
                    None
                },
                own_index: position,
                change: 0.0,
                left_thread: None,
                right_thread: None,
                extreme_left: None,
                extreme_right: None,
                modifier_sum_left: 0.0,
                modifier_sum_right: 0.0,
                prelim: 0.0,
                modifier: 0.0,
                shift: 0.0,
            });
        }
        LayoutTree {
            tree: tree
                .into_iter()
                .collect::<Option<Vec<_>>>()
                .expect("The tree cannot plan to have children that it does not make!"),
            vertical_margin: 0.0,
            horizontal_margin: 0.0,
        }
    }
}

#[cfg(test)]
mod test;
