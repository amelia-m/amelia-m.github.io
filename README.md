# amelia-m.github.io

Personal academic website for Amelia Miramonti, built with [Quarto](https://quarto.org) and served by GitHub Pages at <https://amelia-m.github.io>.

## Where content comes from

Files in `_data/` and `files/` are generated from a separate source repository. Do not edit them by hand; changes are overwritten on the next export.

Everything else is edited by hand here: the pages, the data files at the root (`events.yml`, `links.yml`, `likes.yml`, `bios.yml`, `areas.yml`, `contributions.yml`, `investigate.yml`), `_quarto.yml`, the stylesheets, `R/`, `js/`, `_includes/`, blog posts, and images. A new file outside `_data/` and `files/` is hand-edited too.

Events live in `events.yml`, which feeds both `events.qmd` and the home page callout. One dated list covers the whole page: an entry leaves Upcoming the day after it happens, and goes into Past, filed under its year, only once it is marked `attended: true`, since Past says Amelia was there. Until it is marked it is on neither list: a whole-site render at a terminal asks about it first (see Build and publish), and any render that includes the events page also lists it in the log, which covers renders no one is watching and any entry the prompt could not ask about. `attended: false` keeps it off for good. The callout names the next event only within six weeks of it and falls back to the regulars otherwise. A note written looking forward can carry a `past_note` to replace it afterwards.

The Upcoming split is made twice: by `R/site.R` when the site is built, and again in the reader's browser by `js/events.js`, so a passed event leaves Upcoming and the callout moves on without a republish. The two copies of the rule (an event is upcoming through its own day; the callout's six-week window, carried in the page as `data-from`) are kept in step by hand, so change them together. Republishing is still needed to add or change an event.

`BIOS.md` lists every place a title, employer, or short biography is written down, here and on the external profiles, for when one of them changes. `WORDING.md` records why the words are the words, including the options that were rejected and the reasons they were. `areas.yml` groups the work into research, public policy, public health, and education and lists the projects in each, including past ones that produced no publication; it renders nowhere and is read with `work_areas()`. `investigate.yml` holds verification notes on look-into items; the look-into list itself is kept outside this repository, and new items go there, not here. It renders nowhere either.

## Build and publish

```bash
quarto render                  # needs R with knitr, rmarkdown, jsonlite, yaml; prints
                               # "check-output: N files clean (whole project)" or fails
quarto publish gh-pages        # renders, then pushes _site to the gh-pages branch
```

Both start by asking, at a terminal, whether you went to each past event `events.yml` has not marked yet: `y` went, `n` did not, Enter to be asked again next time. Answers are written into `events.yml`, which then needs committing; `quarto render` first and commit before `quarto publish`, or the live site has marks `main` does not. `quarto preview` (and renders with no one at the keyboard) skip the questions and list the events in the log instead; `quarto preview --render all` renders the whole site, so it asks too.

Blog posts go in `blog/posts/<slug>/index.qmd`.

## Analytics

[GoatCounter](https://www.goatcounter.com), on the `amelia-m` account (dashboard: <https://amelia-m.goatcounter.com>). Chosen over Google Analytics because it sets no cookies and keeps no personal data, so the site needs no consent banner. The script is `_includes/analytics.html`, pulled into every page by `include-in-header` in `_quarto.yml`.

- `R/check-output.R` fails the render on any page without the script, or with it counting to any account but `amelia-m`. A page's own `include-in-header` is added alongside the project's, not in place of it (checked with Quarto 1.10.19), so a page cannot drop out by setting one.
- The script posts every page view to the subdomain it names, so that name must stay one this site owns. It shipped commented out until the account existed, rather than with a placeholder somebody else could register. A new account name means changing the check as well.
- Social apps often send no referrer, so visits from Bluesky or LinkedIn tend to be recorded as direct. Tag the link instead, for example `https://amelia-m.github.io/?utm_source=bluesky`. Campaign Parameters must be switched on in the GoatCounter site settings for the tag to be recorded.
- Ad blockers commonly block GoatCounter, so a test visit with one on does not show up.

## Images

`images/headshot.jpg` and `images/banner.jpg` are web-sized copies. `images/qr-site.svg` encodes `https://amelia-m.github.io/`.

`images/avatar.jpg` is an 800×800 crop of the headshot for profile pictures elsewhere, and is not used by the site. The source photo is 4:5 with the crown close to the top edge, so a platform's own square crop takes the top of the head off.

This one fills 66% of the frame with the head, putting the crown 7% down and the eyes 45.5%, which survives being masked to a circle and still reads at the ~44px most cards render an avatar at. A first version at 58% was better proportioned at full size and too small to make out as a thumbnail. 66% is about the limit: the photo has only ~45px above the crown, so filling more of the frame runs the head into the circle's edge. It needed 10px of margin above the photo, filled by repeating its top row of pixels, which is invisible against the plain background.
