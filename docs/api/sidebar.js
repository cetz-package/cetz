/** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
export default [
  "api/overview",
  {
    type: "category",
    label: "Draw Functions",
    link: {
      type: "doc",
      id: "api/draw-functions/draw-functions",
    },
    items: [
      {
        type: "category",
        label: "Shapes",
        link: {
          type: "doc",
          id: "api/draw-functions/shapes/shapes",
        },
        items: [
          "api/draw-functions/shapes/circle",
          "api/draw-functions/shapes/arc",
          "api/draw-functions/shapes/mark",
          "api/draw-functions/shapes/line",
          "api/draw-functions/shapes/polygon",
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
          id: "api/draw-functions/grouping/grouping",
        },
        items: [
          "api/draw-functions/grouping/hide",
          "api/draw-functions/grouping/intersections",
          "api/draw-functions/grouping/group",
          "api/draw-functions/grouping/anchor",
          "api/draw-functions/grouping/scope",
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
        label: "Styling",
        link: {
          type: "doc",
          id: "api/draw-functions/styling/styling",
        },
        items: [
          "api/draw-functions/styling/set-style",
          "api/draw-functions/styling/fill",
          "api/draw-functions/styling/stroke",
        ],
      },
      {
        type: "category",
        label: "Transformations",
        link: {
          type: "doc",
          id: "api/draw-functions/transformations/transformations",
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
          id: "api/draw-functions/projections/projections",
        },
        items: [
          "api/draw-functions/projections/ortho",
          "api/draw-functions/projections/on-xy",
          "api/draw-functions/projections/on-xz",
          "api/draw-functions/projections/on-yz",
        ],
      }
    ],
  },
  {
    type: "category",
    label: "Libraries",
    link: { type: "doc", id: "api/libraries/index" },
    items: [
      {
        type: "category",
        label: "Tree",
        link: { type: "doc", id: "api/libraries/tree/index" },
        items: ["api/libraries/tree/tree"],
      },
      {
        type: "category",
        label: "Palette",
        link: { type: "doc", id: "api/libraries/palette/index" },
        items: ["api/libraries/palette/new"],
      },
      {
        type: "category",
        label: "Angle",
        link: { type: "doc", id: "api/libraries/angle/index" },
        items: ["api/libraries/angle/angle", "api/libraries/angle/right-angle"],
      },
      {
        type: "category",
        label: "Decorations",
        link: { type: "doc", id: "api/libraries/decorations/index" },
        items: [
          {
            type: "category",
            label: "Braces",
            link: { type: "doc", id: "api/libraries/decorations/braces/index" },
            items: [
              "api/libraries/decorations/braces/brace",
              "api/libraries/decorations/braces/flat-brace",
            ],
          },
          {
            type: "category",
            label: "Paths",
            link: { type: "doc", id: "api/libraries/decorations/path/index" },
            items: [
              "api/libraries/decorations/path/zigzag",
              "api/libraries/decorations/path/coil",
              "api/libraries/decorations/path/wave",
            ],
          },
        ],
      },
    ],
  },
  {
    type: "category",
    label: "Internal",
    link: { type: "doc", id: "api/internal/internal" },
    items: [
      "api/internal/canvas",
      "api/internal/drawable",
      "api/internal/process",
      "api/internal/coordinate",
      "api/internal/anchor",
      "api/internal/mark",
      "api/internal/vector",
      "api/internal/matrix",
      "api/internal/bezier",
      "api/internal/aabb",
      "api/internal/complex",
      "api/internal/hobby",
      "api/internal/intersection",
      "api/internal/path-util",
      "api/internal/styles",
      "api/internal/util",
    ],
  },
];
