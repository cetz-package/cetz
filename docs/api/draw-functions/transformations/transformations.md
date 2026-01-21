# Transformations

All transformation functions but `set-transform` push a transformation matrix onto the current transform stack. To apply transformations scoped use the [`group`](../grouping/group.mdx) or [`scope`](../grouping/scope.mdx') draw function.

Transformation matrices get multiplied in the following order:

$$
M_{\text{world}} = M_\text{world} \cdot M_\text{local}
$$
