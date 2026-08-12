#import "@preview/orange-book:0.7.1": book, part, chapter, appendices

#show: book.with(
$if(title)$
  title: [$title$],
$endif$
$if(subtitle)$
  subtitle: [$subtitle$],
$endif$
$if(by-author)$
  author: "$for(by-author)$$it.name.literal$$sep$, $endfor$",
$endif$
$if(date)$
  date: "$date$",
$endif$
$if(lang)$
  lang: "$lang$",
$endif$
  main-color: brand-color.at("primary", default: blue),
  logo: {
    let logo-info = brand-logo.at("medium", default: none)
    if logo-info != none { image(logo-info.path, alt: logo-info.at("alt", default: none)) }
  },
$if(toc-depth)$
  outline-depth: $toc-depth$,
$endif$
  // Local override. Each part divider page carries a miniature outline of the
  // part's own chapters, bottom-aligned on the same page as the giant part
  // number and title. orange-book defaults this to depth 2, and Quarto's stock
  // partial never passes it, so it is not reachable from _quarto-pdf.yml.
  //
  // Part I holds twelve modules with roughly five sections each, so at depth 2
  // that mini-outline is about seventy lines -- far taller than the page. It
  // overflowed and printed on top of the part title (page 9). Depth 1 lists
  // chapter titles only: twelve lines, which fits. Part II was always fine
  // because Reference has seven chapters, which is why this only ever showed
  // up on one page.
  outline-small-depth: 1,
$if(lof)$
$if(crossref.lof-title)$
  list-of-figure-title: "$crossref.lof-title$",
$else$
$if(quarto.language.crossref-lof-title)$
  list-of-figure-title: "$quarto.language.crossref-lof-title$",
$endif$
$endif$
$endif$
$if(lot)$
$if(crossref.lot-title)$
  list-of-table-title: "$crossref.lot-title$",
$else$
$if(quarto.language.crossref-lot-title)$
  list-of-table-title: "$quarto.language.crossref-lot-title$",
$endif$
$endif$
$endif$
$if(quarto.language.crossref-ch-prefix)$
  supplement-chapter: "$quarto.language.crossref-ch-prefix$",
$endif$
$if(margin-geometry)$
  padded-heading-number: false,
$endif$
)

// Horizontal rules between table rows.
//
// Quarto's stock typst template sets `stroke: none` on every table, and Pandoc
// drops an empty header row entirely rather than emitting `table.header`. The
// "Before you arrive" tables are headerless two-column pipe tables, so between
// those two rules they came out with no lines at all -- three rows of text
// floating in the page with nothing marking the cell boundaries.
//
// This must come after the `#show: book.with(...)` above so it wins over the
// template's own `#set table`. Rows get a hairline on top, skipped on the first
// row so the block does not open with a stray rule; header tables already carry
// Pandoc's own `table.hline()` at the same position.
#set table(
  inset: 6pt,
  stroke: (_, y) => if y > 0 { (top: 0.5pt + luma(170)) },
)

$if(margin-geometry)$
// Configure marginalia page geometry for book context
// Geometry computed by Quarto's meta.lua filter (typstGeometryFromPaperWidth)
// IMPORTANT: This must come AFTER book.with() to override the book format's margin settings
#import "@preview/marginalia:0.3.1" as marginalia

#show: marginalia.setup.with(
  inner: (
    far: $margin-geometry.inner.far$,
    width: $margin-geometry.inner.width$,
    sep: $margin-geometry.inner.separation$,
  ),
  outer: (
    far: $margin-geometry.outer.far$,
    width: $margin-geometry.outer.width$,
    sep: $margin-geometry.outer.separation$,
  ),
  top: $if(margin.top)$$margin.top$$else$1.25in$endif$,
  bottom: $if(margin.bottom)$$margin.bottom$$else$1.25in$endif$,
  // CRITICAL: Enable book mode for recto/verso awareness
  book: true,
  clearance: $margin-geometry.clearance$,
)
$endif$
