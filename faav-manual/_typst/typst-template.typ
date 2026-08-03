// Quarto Typst template partial: the orange-book look for the printable manual.
//
// Quarto's own typst-show.typ calls `article(...)` with the document metadata,
// so this file must define a function by that name and with those parameter
// names. All it really does is translate Quarto's vocabulary into the
// `book(...)` call that orange-book expects.
//
// This is the ONLY partial overridden. Quarto's definitions.typ -- which
// defines callouts, figures, tables and the rest -- is left alone, so callouts
// keep their Quarto styling on top of the orange-book page design.
//
// The package is pulled from the Typst registry by version, rather than vendored
// into the repo, so the build needs network access on first compile. Typst
// caches it afterwards.

#import "@preview/orange-book:0.7.1": *

// orange-book feeds the author straight into `set document(author: ...)`, which
// accepts only strings. Quarto supplies author names as content, so it has to be
// flattened first or the compile fails.
#let content-to-str(c) = {
  if c == none { "" }
  else if type(c) == str { c }
  else if type(c) != content { str(c) }
  else if c.has("text") { c.text }
  else if c.has("children") { c.children.map(content-to-str).join("") }
  else if c.has("body") { content-to-str(c.body) }
  else { "" }
}

#let article(
  // --- Quarto's parameters. Several are accepted only so the call from
  // --- typst-show.typ type-checks; orange-book has its own handling.
  title: none,
  subtitle: none,
  authors: none,
  keywords: (),
  date: none,
  abstract-title: none,
  abstract: none,
  thanks: none,
  cols: 1,
  lang: "en",
  region: "US",
  font: none,
  fontsize: 10pt,
  title-size: 1.5em,
  subtitle-size: 1.25em,
  heading-family: none,
  heading-weight: "bold",
  // NOTE: Quarto's `heading-style` is a font style ("normal"/"italic"). It is
  // NOT orange-book's `heading-style`, which selects the chapter-opener layout.
  // Passing one to the other silently produces the wrong design.
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.65em,
  mathfont: none,
  codefont: none,
  linestretch: 1,
  sectionnumbering: none,
  linkcolor: none,
  citecolor: none,
  filecolor: none,
  toc: false,
  toc_title: none,
  toc_depth: 2,
  toc_indent: 1.5em,
  doc,
) = {
  // Quarto hands authors over as a list of dicts; orange-book wants one piece
  // of content for the title page.
  let author-line = if authors == none or authors == () {
    ""
  } else {
    authors.map(a => content-to-str(a.name)).join(", ", last: " & ")
  }

  // orange-book always emits a list of figures and a list of tables after the
  // table of contents. With no title set they render as an unlabelled run of
  // captions bleeding out of the contents page, which reads as a bug. There is
  // no flag to turn them off, so the figures are simply excluded from all
  // outlines. Cross-references (@fig-...) are unaffected.
  set figure(outlined: false)

  show: doc => book(
    title: title,
    subtitle: subtitle,
    author: author-line,

    // Design. `blue` is Typst's built-in, which is what the reference PDF used;
    // orange-book derives the cover band, part pages and heading colours from
    // it by lightening.
    main-color: blue,

    // 0 = the chapter title in a rounded box that runs off the right edge.
    heading-style: 0,
    // 0 = part pages with a large roman numeral and the part title.
    part-style: 0,

    paper-size: "a4",
    font-size: fontsize,
    lang: lang,

    // orange-book always emits its own table of contents, so Quarto's `toc`
    // flag is not forwarded -- only the depth is.
    outline-depth: toc_depth,

    // The per-part mini-contents on each part page. Kept to depth 1 so it lists
    // chapters only; at the default depth 2 it grows long enough to collide
    // with the part title above it.
    outline-small-depth: 1,

    doc,
  )

  doc
}

// Carried over from Quarto's default template: without it, tables pick up
// Typst's default full grid instead of the Quarto look.
#set table(
  inset: 6pt,
  stroke: none
)
