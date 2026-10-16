# amelia-m.github.io

Personal academic website for Amelia Miramonti, built with [Quarto](https://quarto.org) and served by GitHub Pages at <https://amelia-m.github.io>.

## Where content comes from

Files in `_data/` and `files/` are generated from a separate source repository. Do not edit them by hand; changes are overwritten on the next export.

Edited by hand here: the home page, `research.qmd`, `teaching.qmd`, `contact.qmd`, `events.qmd`, `events.yml`, `posit-conf-2026.qmd`, `fun.qmd`, blog posts, and images.

Events live in `events.yml`, which feeds both `events.qmd` and the home page callout. One dated list covers the whole page: an entry moves from Upcoming to Past the day after it happens, filed under its year, so attending something leaves a record rather than deleting a line. The callout names the next event only within six weeks of it and falls back to the regulars otherwise. Nothing here is kept in sync by hand. A note written looking forward can carry a `past_note` to replace it afterwards.

`BIOS.md` lists every place a title, employer, or short biography is written down, here and on the external profiles, for when one of them changes. `WORDING.md` records why the words are the words, including the options that were rejected and the reasons they were.

## Build and publish

```bash
quarto render                  # needs R with knitr, rmarkdown, jsonlite
quarto publish gh-pages        # renders, then pushes _site to the gh-pages branch
```

Blog posts go in `blog/posts/<slug>/index.qmd`.

## Images

`images/headshot.jpg` and `images/banner.jpg` are web-sized copies. `images/qr-site.svg` encodes `https://amelia-m.github.io/`.
