// Copied from https://github.com/janosh/tikz/blob/da1b4582/assets/periodic-table/periodic-table.typ

#import "@preview/cetz:0.3.1": canvas, draw

#set page(width: auto, height: auto, margin: 15pt)

// Element colors
#let colors = (
  alkali-metal: rgb("#8989ff"),
  alkaline-earth: rgb("#89a9ff"),
  metal: rgb("#89c9ff"),
  metalloid: rgb("#ffa959"),
  nonmetal: rgb("#59d9d9"),
  halogen: rgb("#ffff59"),
  noble-gas: rgb("#89ff89"),
  lanthanide: rgb("#ff8989"),
  synthetic: rgb("#525252"),
)

// Element data
#let elements = (
  // Period 1
  (
    ("1", "1.0079", "H", "Hydrogen"),
    none,
    none,
    none,
    none,
    none,
    none,
    none,
    none,
    none,
    none,
    none,
    none,
    none,
    none,
    none,
    none,
    none,
    none,
    ("2", "4.0025", "He", "Helium", colors.noble-gas),
  ),
  // Period 2
  (
    ("3", "6.941", "Li", "Lithium", colors.alkali-metal),
    ("4", "9.0122", "Be", "Beryllium", colors.alkaline-earth),
    none,
    none,
    none,
    none,
    none,
    none,
    none,
    none,
    none,
    none,
    ("5", "10.811", "B", "Boron", colors.metalloid),
    ("6", "12.011", "C", "Carbon", colors.nonmetal),
    ("7", "14.007", "N", "Nitrogen", colors.nonmetal),
    ("8", "15.999", "O", "Oxygen", colors.nonmetal),
    ("9", "18.998", "F", "Fluorine", colors.halogen),
    ("10", "20.180", "Ne", "Neon", colors.noble-gas),
  ),
  // Period 3
  (
    ("11", "22.990", "Na", "Sodium", colors.alkali-metal),
    ("12", "24.305", "Mg", "Magnesium", colors.alkaline-earth),
    none,
    none,
    none,
    none,
    none,
    none,
    none,
    none,
    none,
    none,
    ("13", "26.982", "Al", "Aluminium", colors.metal),
    ("14", "28.086", "Si", "Silicon", colors.metalloid),
    ("15", "30.974", "P", "Phosphorus", colors.nonmetal),
    ("16", "32.065", "S", "Sulphur", colors.nonmetal),
    ("17", "35.453", "Cl", "Chlorine", colors.halogen),
    ("18", "39.948", "Ar", "Argon", colors.noble-gas),
  ),
  // Period 4
  (
    ("19", "39.098", "K", "Potassium", colors.alkali-metal),
    ("20", "40.078", "Ca", "Calcium", colors.alkaline-earth),
    ("21", "44.956", "Sc", "Scandium", colors.metal),
    ("22", "47.867", "Ti", "Titanium", colors.metal),
    ("23", "50.942", "V", "Vanadium", colors.metal),
    ("24", "51.996", "Cr", "Chromium", colors.metal),
    ("25", "54.938", "Mn", "Manganese", colors.metal),
    ("26", "55.845", "Fe", "Iron", colors.metal),
    ("27", "58.933", "Co", "Cobalt", colors.metal),
    ("28", "58.693", "Ni", "Nickel", colors.metal),
    ("29", "63.546", "Cu", "Copper", colors.metal),
    ("30", "65.39", "Zn", "Zinc", colors.metal),
    ("31", "69.723", "Ga", "Gallium", colors.metal),
    ("32", "72.64", "Ge", "Germanium", colors.metalloid),
    ("33", "74.922", "As", "Arsenic", colors.metalloid),
    ("34", "78.96", "Se", "Selenium", colors.nonmetal),
    ("35", "79.904", "Br", "Bromine", colors.halogen),
    ("36", "83.8", "Kr", "Krypton", colors.noble-gas),
  ),
  // Period 5
  (
    ("37", "85.468", "Rb", "Rubidium", colors.alkali-metal),
    ("38", "87.62", "Sr", "Strontium", colors.alkaline-earth),
    ("39", "88.906", "Y", "Yttrium", colors.metal),
    ("40", "91.224", "Zr", "Zirconium", colors.metal),
    ("41", "92.906", "Nb", "Niobium", colors.metal),
    ("42", "95.94", "Mo", "Molybdenum", colors.metal),
    ("43", "96", "Tc", "Technetium", colors.metal),
    ("44", "101.07", "Ru", "Ruthenium", colors.metal),
    ("45", "102.91", "Rh", "Rhodium", colors.metal),
    ("46", "106.42", "Pd", "Palladium", colors.metal),
    ("47", "107.87", "Ag", "Silver", colors.metal),
    ("48", "112.41", "Cd", "Cadmium", colors.metal),
    ("49", "114.82", "In", "Indium", colors.metal),
    ("50", "118.71", "Sn", "Tin", colors.metal),
    ("51", "121.76", "Sb", "Antimony", colors.metalloid),
    ("52", "127.6", "Te", "Tellurium", colors.metalloid),
    ("53", "126.9", "I", "Iodine", colors.halogen),
    ("54", "131.29", "Xe", "Xenon", colors.noble-gas),
  ),
  // Period 6
  (
    ("55", "132.91", "Cs", "Caesium", colors.alkali-metal),
    ("56", "137.33", "Ba", "Barium", colors.alkaline-earth),
    ("57-71", "", text("La-Lu", size: 28pt), "Lanthanide", colors.lanthanide),
    ("72", "178.49", "Hf", "Hafnium", colors.metal),
    ("73", "180.95", "Ta", "Tantalum", colors.metal),
    ("74", "183.84", "W", "Tungsten", colors.metal),
    ("75", "186.21", "Re", "Rhenium", colors.metal),
    ("76", "190.23", "Os", "Osmium", colors.metal),
    ("77", "192.22", "Ir", "Iridium", colors.metal),
    ("78", "195.08", "Pt", "Platinum", colors.metal),
    ("79", "196.97", "Au", "Gold", colors.metal),
    ("80", "200.59", "Hg", "Mercury", colors.metal),
    ("81", "204.38", "Tl", "Thallium", colors.metal),
    ("82", "207.2", "Pb", "Lead", colors.metal),
    ("83", "208.98", "Bi", "Bismuth", colors.metal),
    ("84", "209", "Po", "Polonium", colors.metalloid),
    ("85", "210", "At", "Astatine", colors.halogen),
    ("86", "222", "Rn", "Radon", colors.noble-gas),
  ),
  // Period 7
  (
    ("87", "223", "Fr", "Francium", colors.alkali-metal),
    ("88", "226", "Ra", "Radium", colors.alkaline-earth),
    ("89-103", "", text("Ac-Lr", size: 28pt), "Actinide", colors.lanthanide),
    ("104", "261", "Rf", "Rutherfordium", colors.metal),
    ("105", "262", "Db", "Dubnium", colors.metal),
    ("106", "266", "Sg", "Seaborgium", colors.metal),
    ("107", "264", "Bh", "Bohrium", colors.metal),
    ("108", "277", "Hs", "Hassium", colors.metal),
    ("109", "268", "Mt", "Meitnerium", colors.metal),
    ("110", "281", "Ds", "Darmstadtium", colors.metal),
    ("111", "280", "Rg", "Roentgenium", colors.metal),
    ("112", "285", "Cn", "Copernicium", colors.metal),
    ("113", "284", "Nh", "Nihonium", colors.metal),
    ("114", "289", "Fl", "Flerovium", colors.metal),
    ("115", "288", "Mc", "Moscovium", colors.metal),
    ("116", "293", "Lv", "Livermorium", colors.metal),
    ("117", "294", "Ts", "Tennessine", colors.halogen),
    ("118", "294", "Og", "Oganesson", colors.noble-gas),
  ),
)

// Lanthanide data
#let lanthanides = (
  ("57", "138.91", "La", "Lanthanum"),
  ("58", "140.12", "Ce", "Cerium"),
  ("59", "140.91", "Pr", "Praseodymium"),
  ("60", "144.24", "Nd", "Neodymium"),
  ("61", "145", "Pm", "Promethium"),
  ("62", "150.36", "Sm", "Samarium"),
  ("63", "151.96", "Eu", "Europium"),
  ("64", "157.25", "Gd", "Gadolinium"),
  ("65", "158.93", "Tb", "Terbium"),
  ("66", "162.50", "Dy", "Dysprosium"),
  ("67", "164.93", "Ho", "Holmium"),
  ("68", "167.26", "Er", "Erbium"),
  ("69", "168.93", "Tm", "Thulium"),
  ("70", "173.04", "Yb", "Ytterbium"),
  ("71", "174.97", "Lu", "Lutetium"),
)

// Actinide data
#let actinides = (
  ("89", "227", "Ac", "Actinium"),
  ("90", "232.04", "Th", "Thorium"),
  ("91", "231.04", "Pa", "Protactinium"),
  ("92", "238.03", "U", "Uranium"),
  ("93", "237", "Np", "Neptunium"),
  ("94", "244", "Pu", "Plutonium"),
  ("95", "243", "Am", "Americium"),
  ("96", "247", "Cm", "Curium"),
  ("97", "247", "Bk", "Berkelium"),
  ("98", "251", "Cf", "Californium"),
  ("99", "252", "Es", "Einsteinium"),
  ("100", "257", "Fm", "Fermium"),
  ("101", "258", "Md", "Mendelevium"),
  ("102", "259", "No", "Nobelium"),
  ("103", "262", "Lr", "Lawrencium"),
)

// Helper function to create an element box
#let element(number, mass, symbol, name, fill: white, text-color: black) = {
  box(width: 3cm, height: 3cm, fill: fill, stroke: black, inset: 4pt)[
    #set align(center)
    #text(size: 18pt, weight: "bold")[#number #h(1fr) #mass]\
    #v(1fr)
    #text(size: 40pt, weight: "bold", fill: text-color)[#symbol]\
    #v(1fr)
    #text(size: 13pt)[#name]
  ]
}

// Helper function to create a synthetic element (gray text)
#let synthetic-element(number, mass, symbol, name, fill: white) = {
  element(number, mass, symbol, name, fill: fill, text-color: colors.synthetic)
}

#canvas({
  import draw: line, content, rect

  let cell-size = 3.25 // Increased cell size
  let start-x = 0
  let start-y = 0
  let lanthanide-gap = 2.5 // Gap before lanthanides/actinides

  // Function to calculate element position
  let pos(group, period) = {
    let y-offset = if period > 7 { lanthanide-gap } else { 0 }
    (
      start-x + (group - 1) * cell-size,
      start-y - (period - 1) * cell-size - y-offset,
    )
  }

  // Function to calculate lanthanide/actinide position
  let special-pos(num, is-actinide: false) = {
    let row = if is-actinide { 9 } else { 8 }
    let col = num - (if is-actinide { 89 } else { 57 }) + 3
    let y-offset = lanthanide-gap
    (
      start-x + (col - 1) * cell-size,
      start-y - (row - 1) * cell-size - y-offset,
    )
  }

  // Draw main table elements
  for period in range(1, elements.len() + 1) {
    for group in range(1, 19) {
      let data = elements.at(period - 1).at(group - 1)
      if data != none {
        if data.len() == 5 {
          content(pos(group, period), element(..data.slice(0, 4), fill: data.at(4)))
        } else {
          content(pos(group, period), element(..data))
        }
      }
    }
  }

  // Lanthanides
  for (idx, data) in lanthanides.enumerate() {
    content(special-pos(57 + idx), element(..data, fill: colors.lanthanide))
  }

  // Actinides
  for (idx, data) in actinides.enumerate() {
    content(
      special-pos(89 + idx, is-actinide: true),
      if idx <= 3 { element(..data, fill: colors.lanthanide) } else {
        synthetic-element(..data, fill: colors.lanthanide)
      },
    )
  }

  // Connect lanthanides and actinides to main table with dotted lines
  let la-pos = pos(3, 6)
  let ac-pos = pos(3, 7)
  let la-start = special-pos(57)
  let ac-start = special-pos(89, is-actinide: true)

  line(
    (la-pos.at(0), la-pos.at(1)),
    (la-start.at(0), la-start.at(1)),
    stroke: (dash: "dotted", thickness: 1.5pt),
  )
  line(
    (ac-pos.at(0), ac-pos.at(1)),
    (ac-start.at(0), ac-start.at(1)),
    stroke: (dash: "dotted", thickness: 1.5pt),
  )

  // Title
  content(
    (7 * cell-size, 0.2 * cell-size),
    text(size: 76pt, weight: "bold")[Periodic Table of Elements],
  )

  // Period labels
  for period in range(1, 8) {
    content(
      (start-x - cell-size * 0.6, start-y - (period - 1) * cell-size),
      text(size: 16pt, weight: "bold")[#period],
    )
  }

  // Group labels
  let groups = "IA IIA IIIB IVB VB VIB VIIB VIIIB VIIIB VIIIB IB IIB IIIA IVA VA VIA VIIA VIIIA".split(" ")

  // Find first element in each column
  for (num, label) in groups.enumerate(start: 1) {
    let first_period = if num == 1 { 1 } else if num == 2 { 2 } else if num <= 12 { 4 } else { 2 }
    let (x, y) = pos(num, first_period)
    content(
      (x, y + cell-size * 0.7),
      box(width: 3cm)[
        #set align(center)
        #text(size: 14pt, weight: "bold")[#num #h(1fr) #label]
      ],
    )
  }

  // Legend
  let legend-start = (start-x - 0.5 * cell-size, start-y - 6.8 * cell-size)
  let legend-items = (
    ("Alkali Metal", colors.alkali-metal),
    ("Alkaline Earth Metal", colors.alkaline-earth),
    ("Transition Metal", colors.metal),
    ("Metalloid", colors.metalloid),
    ("Nonmetal", colors.nonmetal),
    ("Halogen", colors.halogen),
    ("Noble Gas", colors.noble-gas),
    ("Lanthanide/Actinide", colors.lanthanide),
  )

  for (idx, (label, color)) in legend-items.enumerate() {
    let y-offset = idx
    rect(
      (legend-start.at(0), legend-start.at(1) - y-offset),
      (legend-start.at(0) + 0.8, legend-start.at(1) - y-offset - 0.8),
      fill: color,
      stroke: black,
    )
    content(
      (legend-start.at(0) + 1, legend-start.at(1) - y-offset - 0.4),
      text(size: 14pt)[#label],
      anchor: "west",
    )
  }

  // Element key
  content(
    (12, -4),
    element("Z", "mass", text("Symbol", size: 22pt), "Name"),
  )
  content(
    (legend-start.at(0) + 10, legend-start.at(1)),
    text(size: 12pt)[
      black: natural\
      #text(fill: colors.synthetic)[gray: man-made]
    ],
  )
})
