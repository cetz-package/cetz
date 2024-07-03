export default [
  "api/overview",
  {
    type: "category",
    label: "Draw Functions",
    link: {
      type: "doc",
      id: "api/draw-functions/index",
    },
    items: [
      {
        type: "category",
        label: "Shapes",
        link: {
          type: "doc",
          id: "api/draw-functions/shapes/index",
        },
        items: [
          "api/draw-functions/shapes/circle",
          "api/draw-functions/shapes/arc",
          "api/draw-functions/shapes/mark",
          "api/draw-functions/shapes/line",
          "api/draw-functions/shapes/grid",
          "api/draw-functions/shapes/content",
          "api/draw-functions/shapes/rect",
          "api/draw-functions/shapes/bezier",
          "api/draw-functions/shapes/hobby",
          "api/draw-functions/shapes/catmull",
          "api/draw-functions/shapes/merge-path",
        ],
      },
      {
        type: "category",
        label: "Grouping",
        link: {
          type: "doc",
          id: "api/draw-functions/grouping/index",
        },
        items: [
          "api/draw-functions/grouping/hide",
          "api/draw-functions/grouping/intersections",
          "api/draw-functions/grouping/group",
          "api/draw-functions/grouping/anchor",
          "api/draw-functions/grouping/copy-anchors",
          "api/draw-functions/grouping/set-ctx",
          "api/draw-functions/grouping/get-ctx",
          "api/draw-functions/grouping/for-each-anchor",
          "api/draw-functions/grouping/on-layer",
          "api/draw-functions/grouping/floating",
        ],
      },
      {
        type: "category",
        label: "Transformations",
        link: {
          type: "doc",
          id: "api/draw-functions/transformations/index",
        },
        items: [
          "api/draw-functions/transformations/set-transform",
          "api/draw-functions/transformations/rotate",
          "api/draw-functions/transformations/translate",
          "api/draw-functions/transformations/scale",
          "api/draw-functions/transformations/set-origin",
          "api/draw-functions/transformations/move-to",
          "api/draw-functions/transformations/set-viewport",
        ],
      },
      {
        type: "category",
        label: "Projections",
        link: {
          type: "doc",
          id: "api/draw-functions/projections/index",
        },
        items: [
          "api/draw-functions/projections/ortho",
          "api/draw-functions/projections/on-xy",
          "api/draw-functions/projections/on-xz",
          "api/draw-functions/projections/on-yz",
        ],
      },
    ],
  },
];
