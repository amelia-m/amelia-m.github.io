# amelia-m.github.io

Personal academic website for Amelia Miramonti, built with [Quarto](https://quarto.org) and served by GitHub Pages at <https://amelia-m.github.io>.

## Where content comes from

Files in `_data/` and `files/` are generated from a separate source repository. Do not edit them by hand; changes are overwritten on the next export.

Edited by hand here: the home page, `research.qmd`, `teaching.qmd`, `contact.qmd`, `events.qmd`, `events.yml`, `posit-conf-2026.qmd`, `fun.qmd`, blog posts, and images.

Events live in `events.yml`, which feeds both `events.qmd` and the home page callout. One dated list covers the whole page: an entry moves from Upcoming to Past the day after it happens, filed under its year, so attending something leaves a record rather than deleting a line. The callout names the next event only within six weeks of it and falls back to the regulars otherwise. Nothing here is kept in sync by hand. A note written looking forward can carry a `past_note` to replace it afterwards.

`BIOS.md` lists every place a title, employer, or short biography is written down, here and on the external profiles, for when one of them changes. `WORDING.md` records why the words are the words, including the options that were rejected and the reasons they were. `areas.yml` groups the work into research, public policy, public health, and education and lists the projects in each, including past ones that produced no publication; it renders nowhere and is read with `work_areas()`. `investigate.yml` holds verification notes on look-into items; the look-into list itself is kept outside this repository, and new items go there, not here. It renders nowhere either.

## Build and publish

```bash
quarto render                  # needs R with knitr, rmarkdown, jsonlite, yaml; prints
                               # "check-output: N files clean (whole project)" or fails
quarto publish gh-pages        # renders, then pushes _site to the gh-pages branch
```

Blog posts go in `blog/posts/<slug>/index.qmd`.

## Images

`images/headshot.jpg` and `images/banner.jpg` are web-sized copies. `images/qr-site.svg` encodes `https://amelia-m.github.io/`.

`images/avatar.jpg` is an 800×800 crop of the headshot for profile pictures elsewhere, and is not used by the site. The source photo is 4:5 with the crown close to the top edge, so a platform's own square crop takes the top of the head off.

This one fills 66% of the frame with the head, putting the crown 7% down and the eyes 45.5%, which survives being masked to a circle and still reads at the ~44px most cards render an avatar at. A first version at 58% was better proportioned at full size and too small to make out as a thumbnail. 66% is about the limit: the photo has only ~45px above the crown, so filling more of the frame runs the head into the circle's edge. It needed 10px of margin above the photo, filled by repeating its top row of pixels, which is invisible against the plain background.
