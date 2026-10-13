# amelia-m.github.io

Personal academic website for Amelia Miramonti, built with [Quarto](https://quarto.org) and served by GitHub Pages at <https://amelia-m.github.io>.

## Where content comes from

Files in `_data/` and `files/` are generated from a separate source repository. Do not edit them by hand; changes are overwritten on the next export.

Edited by hand here: the home page, `research.qmd`, `teaching.qmd`, `contact.qmd`, `events.qmd`, `posit-conf-2026.qmd`, `fun.qmd`, blog posts, and images.

The home page has a "Next up" callout for the next event on `events.qmd`. When that event passes, update or remove the callout in the same change that moves the event to Past.

## Build and publish

```bash
quarto render                  # needs R with knitr, rmarkdown, jsonlite
quarto publish gh-pages        # renders, then pushes _site to the gh-pages branch
```

Blog posts go in `blog/posts/<slug>/index.qmd`.

## Images

`images/headshot.jpg` and `images/banner.jpg` are web-sized copies. `images/qr-site.svg` encodes `https://amelia-m.github.io/`.
