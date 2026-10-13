# Keeping the bios in step

`bios.yml` is the list: every place a bio is published, what each one currently
says, and the date that text was last checked. This file is the order to work
through them in.

## Reading them side by side

```r
source("R/site.R")
bio_report()
```

Prints each bio with its character count, how long ago it was checked, and
whether it is over a platform limit. Any entry naming a `file` is also checked
against that file, and says `DRIFTED` when the recorded text is no longer in
it. That is the one kind of staleness that catches itself; everything else
relies on the `updated` date, so set it whenever you change a `text`.

Seven profiles have no text recorded yet. Paste in what each currently says and
date it, or delete the entry if that profile is not worth keeping current.

## Two of these are the source

The rest are shortened from them, so change these first:

- **Long, first person**: `index.qmd`, the paragraph beginning "Hi, I'm Amelia!"
- **Short, third person**: `contact.qmd`, the "Amelia Miramonti, PhD, is a ..."
  paragraph. This is the one to send a conference or seminar organiser.

## Generated, so fix these elsewhere

Editing them in this repository is overwritten by the next export. Change them
in the source repository and re-run it.

| Where | What it feeds |
| --- | --- |
| `_data/positions.json` | The "Currently" block on the home page, and the positions list on the CV page |
| `files/Miramonti_CV.pdf` | The downloadable CV |

## Not tracked in `bios.yml`

These vary too much to list usefully, but are worth a look when something
changes:

- UNL department and NEAR Center staff pages, and any project or centre page
  that names the role.
- Email signature.
- Standing speaker or committee bios held by other people.

## Order to work through a job change

1. `index.qmd` and `contact.qmd`, since the rest is shortened from them.
2. `research.qmd` and the `description:` in `_quarto.yml`, if the affiliation
   named in them moved.
3. `positions.json` at its source, then re-export and re-render.
4. ORCID and Google Scholar, which other systems read automatically.
5. LinkedIn, then the remaining profiles.
6. The email address in `links.yml` last, once the new one works, so nothing
   points at a dead address in between.
7. `bio_report()` to confirm nothing says `DRIFTED` and every `updated` date is
   current.
