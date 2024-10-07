/** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
export default [
  "overview",
  "getting-started",
  {
    type: "category",
    label: "Basics",
    link: {
      type: "doc",
      id: "basics/basics",
    },
    items: [
      "basics/custom-types",
      "basics/canvas",
      "basics/styling",
      "basics/coordinate-systems",
      "basics/anchors",
      "basics/marks",
    ],
  },
  {
    type: "category",
    label: "Libraries",
    link: {
      type: "doc",
      id: "libraries/libraries",
    },
    items: ["libraries/tree"],
  },
  {
    type: "category",
    label: "Tutorials",
    link: {
      type: "generated-index",
      title: "Tutorials",
    },
    items: ["tutorials/karl"],
  },
  {
    type: "category",
    label: "Advanced",
    link: {
      type: "doc",
      id: "advanced/advanced",
    },
    items: ["advanced/custom-types"],
  },
];
