# Deploying the FAAV Build Manual to aura.mit.edu

Paste this file into Claude Code running in the **aura.mit.edu website repo**,
after copying the `faav-manual/` folder into the repo root.

---

## What this is

`faav-manual/` is a self-contained [Quarto](https://quarto.org) website project
(Markdown source + figures). Rendering it produces a folder of plain HTML that
GitHub Pages serves like any other static content. The lab website itself is
not involved and must not be modified.

The manual is **unlisted, not private**: it should not be linked from the main
site navigation and carries a `noindex` meta tag, but anyone with the URL can
read it. That is intentional.

## Target layout

```
<repo root>/
  index.html                          existing hand-written site (do not touch)
  faav-manual/                        Quarto source              (this folder)
  faav-manual/files/                  downloadables, incl. the generated PDF
  2.S986-robot/                       generated HTML             (built)
  .github/workflows/build-manual.yml  rebuilds both on push
```

Result: the manual is served at **https://aura.mit.edu/2.S986-robot/**

`faav-manual/_quarto.yml` already sets `output-dir: ../2.S986-robot`, so
rendering from inside `faav-manual/` puts the output in the right place
automatically.

---

## Tasks

### 1. Confirm the Pages setup before building

```bash
gh api repos/{owner}/{repo}/pages
ls -a          # look for .nojekyll, _config.yml
```

Report what you find. Two things matter:

- **The publishing source must include the repo root** (or wherever
  `2.S986-robot/` ends up), otherwise the manual will 404.
- **If the site is built by Jekyll** (no `.nojekyll` file), Jekyll will ignore
  any folder starting with `_`. Quarto's output contains `site_libs/`, which is
  fine, but add a `.nojekyll` file at the repo root if one is not there — it
  disables Jekyll processing and is the safe default for a hand-written site.

Do not proceed if the publishing source does not cover `2.S986-robot/`. Ask
instead.

### 2. Build

Normally you do not build by hand at all --- `.github/workflows/build-manual.yml`
rebuilds and commits both artefacts on any push touching `faav-manual/`. To
build locally anyway, **keep this order**:

```bash
quarto --version || winget install --id Posit.Quarto -e

# 1. PDF first, into files/
cd faav-manual
quarto render manual-pdf.qmd --to typst \
  -M title:"FAAV Build Manual" \
  -M subtitle:"MIT AURA Lab, 2026 v4.0 (printable edition)"
cp manual-pdf.pdf files/faav-build-manual.pdf

# 2. Then the website, which publishes files/ as a resource
cd .. && rm -rf 2.S986-robot && cd faav-manual && quarto render
```

The order is not cosmetic. `_quarto.yml` declares `resources: [files/]`, so the
**website** render is what copies `files/` into the output. Build the site
first and the PDF is not there to be copied, so the download link on the
landing page 404s.

The `rm -rf` matters too: `output-dir` points outside the project, and Quarto
refuses to clean an output directory it does not own. It warns and leaves
stale files behind, so deleted pages and superseded `site_libs` bundles pile
up until the directory is cleared by hand.

The PDF needs no TeX install --- Quarto's Typst backend is built in.

This creates `../2.S986-robot/` with `index.html` and `site_libs/`.

Verify before continuing:

- `2.S986-robot/index.html` exists
- `2.S986-robot/sessions/02-motor.html` exists
- Figures are present under `2.S986-robot/Fig/`
- `2.S986-robot/files/CNC-Stepcraft-D600-guide.pdf` exists
- `2.S986-robot/files/faav-build-manual.pdf` exists (the ordering check)

Open `2.S986-robot/index.html` in a browser and confirm the sidebar, search box, and
light/dark toggle work. Report the actual result — do not report success
without having rendered.

### 3. Commit

Commit **both** `faav-manual/` (source) and `2.S986-robot/` (output). GitHub
Pages does not run Quarto, so the rendered output has to be in the repo.

Do not add `2.S986-robot/` to `.gitignore`.

### 4. Verify it is live and unlisted

```bash
curl -sS -o /dev/null -w "%{http_code}\n" https://aura.mit.edu/2.S986-robot/
grep -r "noindex" 2.S986-robot/index.html
```

Expect `200` and a match on `noindex`.

Then confirm the manual is **not** linked from the main site: no new entry in
the lab site's navigation, header, or footer.

### 5. Do not

- Modify the existing site's HTML, CSS, or navigation
- Restyle the manual to match the lab site — it is stock Quarto on purpose
- Rename `2.S986-robot/` without also updating `output-dir` and `site-url` in
  `faav-manual/_quarto.yml`

---

## Updating later

Edit the `.qmd` files in `faav-manual/`, commit the source, and push:

```bash
git add faav-manual && git commit -m "manual: <what changed>" && git push
```

`.github/workflows/build-manual.yml` takes it from there: it renders the PDF,
renders the site, verifies both, and commits the regenerated
`2.S986-robot/` and `faav-manual/files/faav-build-manual.pdf` back to the
branch you pushed. Live a minute or two after that commit lands on `master`.

`quarto preview` gives live reload while writing, without committing anything.

## The build workflow

`.github/workflows/build-manual.yml`, triggered by any push touching
`faav-manual/`.

- **No TeX.** The PDF renders through Quarto's Typst backend, which ships
  inside Quarto. Nothing to install, a few seconds rather than the minutes a
  TinyTeX install costs.
- **PDF first, then site.** See the ordering note in step 2 above. The verify
  step checks `2.S986-robot/files/faav-build-manual.pdf` specifically, so
  getting the order wrong fails the build instead of shipping a dead link.
- **No trigger loop.** The workflow commits into `faav-manual/files/`, which
  is inside its own trigger path. Pushes made with the default `GITHUB_TOKEN`
  do not start another workflow run, so it terminates.

### Editing the printable PDF

`manual-pdf.qmd` aggregates every page via `{{< include >}}`. Two traps:

- Each include merges that file's YAML front matter into the document, last
  one winning --- a `title:` in `manual-pdf.qmd` silently loses to the last
  included page. Title and subtitle are passed with `-M`, which outranks
  front matter. Keep them in the render command.
- An include contributes no heading; the included file's `title:` is consumed
  as metadata and never rendered. The explicit `#` headings in
  `manual-pdf.qmd` are what separate the modules. Retitling a module means
  editing it in both places.

### The PDF design

The PDF uses the [orange-book](https://github.com/flavio20002/typst-orange-template)
Typst template, pinned at `0.7.1`, wired in through
`_typst/typst-template.typ`.

Quarto calls a function named `article(...)` with the document metadata; that
file defines it and forwards to orange-book's `book(...)`. Things to know
before editing it:

- **Only `typst-template.typ` is overridden.** Quarto's `definitions.typ`,
  which styles callouts, figures and tables, is left alone --- which is why
  callouts still look like Quarto callouts on top of the orange-book layout.
  Overriding that partial too would lose them.
- **`heading-style` means two different things.** Quarto's is a font style
  (`"normal"`/`"italic"`); orange-book's selects the chapter-opener layout
  (`0` = the boxed title). Forwarding one to the other compiles fine and
  produces the wrong design.
- **Authors must be strings.** orange-book passes the author into
  `set document(author:)`, which rejects content. Quarto supplies content, so
  `content-to-str` flattens it first. Without that the compile fails outright.
- **Figures are excluded from outlines.** orange-book unconditionally emits a
  list of figures and a list of tables after the contents; with no title they
  render as an unlabelled run of captions spilling out of the contents page.
  There is no flag to disable them, so `set figure(outlined: false)` is used
  instead. Cross-references still work.
- **Cross-page links are rewritten to internal jumps.** The pages link to each
  other by file path (`./reference/pcb.qmd`), which is correct for the website.
  Pandoc passes those through as link URLs, so in the PDF they come out styled
  and blue but pointing at a file that does not exist. A `show link` rule in the
  template maps them onto labels: an anchor if the target exists
  (`pcb.qmd#v2-waterproofing` → `<v2-waterproofing>`), otherwise the chapter
  (`pcb.qmd` → `<ch-pcb>`). Chapter labels are `ch-` plus the included file's
  basename, assigned by the `{#ch-...}` ids on the headings in `manual-pdf.qmd`
  --- keep those two conventions in step and new chapters need no template
  change. External URLs are untouched.
- **Parts come from raw Typst.** The `#part("...")` calls in `manual-pdf.qmd`
  are ```` ```{=typst} ```` blocks. `part()` is in scope because the template
  imports orange-book at document level.
- **The build needs network on first compile.** The package is fetched from the
  Typst registry rather than vendored, then cached. An offline runner cannot
  build the PDF.

Page size is A4, matching the reference design. Change `paper-size` in
`_typst/typst-template.typ` if US Letter suits the shop better.

Links and images throughout the manual use project-root-relative paths
(`/Fig/...`, `/sessions/...`). Document-relative `../Fig/...` works on the
website but escapes the Typst sandbox when the same file is included into the
PDF from the project root.
Only do this if asked — the commit-the-output approach is simpler and works
with the branch-based Pages setup the site already uses.
