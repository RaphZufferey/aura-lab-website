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
  index.html          existing hand-written site   (do not touch)
  faav-manual/        Quarto source                (this folder)
  2.S986-robot/       generated HTML               (created by the build)
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

```bash
quarto --version || winget install --id Posit.Quarto -e
cd faav-manual
quarto render
```

This creates `../2.S986-robot/` with `index.html` and `site_libs/`.

Verify before continuing:

- `2.S986-robot/index.html` exists
- `2.S986-robot/sessions/02-motor.html` exists
- Figures are present under `2.S986-robot/Fig/`
- `2.S986-robot/files/CNC-Stepcraft-D600-guide.pdf` exists

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

Edit the `.qmd` files in `faav-manual/`, then:

```bash
cd faav-manual && quarto render && cd ..
git add faav-manual 2.S986-robot && git commit -m "manual: <what changed>" && git push
```

Live within a minute or two of the push.

`quarto preview` gives live reload while writing, without committing anything.

## Optional: build in CI instead

If you would rather not commit generated HTML, replace steps 2–3 with a GitHub
Actions workflow using `quarto-dev/quarto-actions/setup@v2` that renders and
commits `2.S986-robot/`, or that switches the site to an Actions-based Pages
deploy.
Only do this if asked — the commit-the-output approach is simpler and works
with the branch-based Pages setup the site already uses.
