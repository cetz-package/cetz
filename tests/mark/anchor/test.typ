#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case(args => {
  import draw: *

  line((0, -1), (0, 1))
  mark((0, 0), (args.dir,0), symbol: "stealth", anchor: args.anchor)
}, args: (
  (dir: +1, anchor: "tip"),
  (dir: +1, anchor: "center"),
  (dir: +1, anchor: "base"),
  (dir: -1, anchor: "tip"),
  (dir: -1, anchor: "center"),
  (dir: -1, anchor: "base"),
))

#test-case(args => {
  import draw: *

  line((0, -1), (0, 1), stroke: green)
  line((-1, 0), (0,0), mark: (end: "stealth", anchor: args.anchor))
}, args: (
  (anchor: "tip"),
  (anchor: "center"),
  (anchor: "base"),
))

#test-case(args => {
  import draw: *

  set-style(mark: (stroke: red))
  line((0,-1.2), (0,+1.2), stroke: green)
  mark((0,  0), (-1,  0), symbol: args.symbol, anchor: "tip")
  line((-1, 2), (3, 2), mark: (start: args.symbol, end: args.symbol, harpoon: true))
}, args: (
  (symbol: ">"),
  (symbol: "stealth"),
  (symbol: "|"),
  (symbol: "o"),
  (symbol: "]"),
  (symbol: "<>"),
  (symbol: "[]"),
  (symbol: "hook"),
  (symbol: "straight"),
  (symbol: "barbed"),
  (symbol: "+"),
  (symbol: "x"),
  (symbol: ">"),
))
