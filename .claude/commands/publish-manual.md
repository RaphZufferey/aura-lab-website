---
description: Rebuild the FAAV manual (HTML + PDF) and publish it to aura.mit.edu
---

Rebuild the FAAV build manual from the `.qmd` source and publish it. Run this
after editing anything under `faav-manual/`.

Work from the repo root (`c:\Code\personal`) using the Bash tool (Git Bash).
Do every step in order and report the actual results — never claim success
without having rendered.

## Why this is a local build

`.github/workflows/build-manual.yml` is supposed to do this on push, but as of
2026-09-03 it has not committed output for several pushes and the repo is
private, so its run status cannot be checked without a GitHub token. **Always
build locally.** If someone fixes CI later, this command still works — it just
means the workflow finds nothing to commit.

Quarto must be **1.10.18**, the version the workflow pins, so local and CI
output cannot diverge:

```bash
quarto --version    # expect 1.10.18
```

## 1. Preflight — catch source errors before rendering

Both of these have shipped broken to the live site before. Run them and fix
anything they report *before* building.

```bash
# Figures referenced from .qmd that do not exist on disk
grep -rhoE '\]\(/Fig/[^)]+\)' faav-manual --include=*.qmd \
  | sed -E 's|^\]\(/Fig/||; s|\)$||' | sort -u \
  | while read f; do [ -f "faav-manual/Fig/$f" ] || echo "MISSING FIGURE: $f"; done

# Cross-references used but never defined (a dropped {#tbl-...} label)
comm -23 \
  <(grep -rhoE '@(fig|tbl|eq|sec)-[A-Za-z0-9_-]+' faav-manual --include=*.qmd | sort -u) \
  <(grep -rhoE '\{#(fig|tbl|eq|sec)-[A-Za-z0-9_-]+' faav-manual --include=*.qmd | sed 's/{#/@/' | sort -u)
```

Both should print nothing. Watch for underscore-vs-hyphen filename mismatches
(`ESC_assembly.jpg` vs `ESC-assembly.jpg`) — that is what the figure check is
really for.

## 2. Build — the order is not cosmetic

```bash
cd faav-manual && quarto render --profile pdf
cd /c/Code/personal && cp manual-pdf/FAAV-Build-Manual.pdf faav-manual/files/faav-build-manual.pdf
rm -rf 2.S986-robot && cd faav-manual && quarto render
```

- **PDF first.** `_quarto.yml` declares `resources: [files/]`, so the *website*
  render is what copies `files/` into the output. Build the site first and the
  PDF is not there to copy, and the download link on the landing page 404s.
- **`rm -rf 2.S986-robot` matters.** `output-dir` points outside the project, so
  Quarto refuses to clean it — it warns and leaves stale files behind. Without
  this, deleted pages and superseded `site_libs` bundles accumulate.
- `manual-pdf/` is a gitignored intermediate. Never commit it.

## 3. Verify — the same checks CI would run

```bash
cd /c/Code/personal
for f in 2.S986-robot/index.html 2.S986-robot/sessions/02-motor.html \
         2.S986-robot/reference/parts-list.html 2.S986-robot/search.json \
         2.S986-robot/files/faav-build-manual.pdf \
         faav-manual/files/faav-build-manual.pdf; do
  [ -s "$f" ] && echo "ok      $f" || echo "MISSING $f"
done
stat -c%s 2.S986-robot/files/faav-build-manual.pdf   # expect > 1 MB
head -c 4 2.S986-robot/files/faav-build-manual.pdf   # expect %PDF
grep -c 'files/faav-build-manual.pdf' 2.S986-robot/index.html   # expect 1
grep -c 'noindex' 2.S986-robot/index.html                       # expect 1
pdfinfo 2.S986-robot/files/faav-build-manual.pdf | grep '^Pages:'
```

Page count should be roughly 65–75. Far above that means something is
inserting page breaks it should not; the CI build fails over 120 for that
reason. Stop and investigate rather than publishing.

Also check that figures newly referenced this round made it into
`2.S986-robot/Fig/`, and that any figure deletions are ones you expect —
Quarto only copies figures that are actually referenced, so removing a section
correctly drops its images.

## 4. Commit and push

Commit **both** the source and the generated output. GitHub Pages does not run
Quarto, so the rendered HTML has to be in the repo.

```bash
git add faav-manual 2.S986-robot
git commit -m "manual: <what changed>"
git push
```

If the push is rejected as behind, `git fetch origin` and inspect
`HEAD..origin/master` before merging or rebasing — the incoming commits may be
CI's generated output, which you should not duplicate.

## 5. Report

Tell me:

- What the preflight checks found, and what you fixed
- The PDF page count and size
- Which output files were added or deleted, and why
- Any new render warnings (see below for the ones that are already known)

The site is live at <https://aura.mit.edu/2.S986-robot/> a minute or two after
the commit lands on `master`.

## Known warnings — not regressions, do not "fix" silently

- **`Unable to resolve crossref @eq-bemf`** — [03-esc.qmd](../../faav-manual/sessions/03-esc.qmd)
  references an equation defined in `02-motor.qmd`. Quarto does not resolve
  equation cross-refs *across documents* in a website project, so it renders as
  a broken `?eq-bemf`. Long-standing. Flag it if you fix it properly.
- **`Refusing to remove directory .../manual-pdf/site_libs`** and *"Quarto did
  not expect the path configuration"* during the PDF render — expected, caused
  by `output-dir` pointing outside the project. Harmless.
- **`LF will be replaced by CRLF`** from git on Windows — expected, ignore.
- **The PDF always shows as modified, even with no source change.**
  `_quarto-pdf.yml` sets `date: last-modified`, so the cover page carries a
  fresh timestamp on every render and the binary differs each time. The HTML,
  by contrast, rebuilds byte-identically — so if `git status` shows *only* the
  two PDFs changed, nothing substantive happened and the rebuild can be
  discarded with `git checkout -- '*faav-build-manual.pdf'`.

## Do not

- Modify the existing lab site's HTML, CSS, or navigation
- Restyle the manual to match the lab site — it is stock Quarto on purpose
- Add `2.S986-robot/` to `.gitignore`
- Link the manual from the main site navigation — it is deliberately unlisted
  (`noindex`, reachable only by URL)
- Rename `2.S986-robot/` without also updating `output-dir` and `site-url` in
  `faav-manual/_quarto.yml`

Background and the original deployment procedure: [DEPLOY.md](../../faav-manual/DEPLOY.md).
