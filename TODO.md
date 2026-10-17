# TODO

Open items for this repo, kept here so they survive chat sessions. Newest at the bottom of
each section. Delete a line when it is done.

Started 2026-10-17 from a session that had accumulated all of this in chat, which is what the
agent-config profile warns against: nothing should live only in one tool's memory. Items that
belong to another repository are marked as such rather than left out, because this is where
they were found.

## Publish

- [ ] The published site is behind. `gh-pages` is at `f801be0` (2026-10-13) while `main` is at
      `2efcdf8` (2026-10-16), with further commits on
      `claude/website-review-message-removal-qref3z` on top of that
      (`git rev-list --count origin/main..HEAD`). Needs `git pull` on `main` and then
      `quarto publish gh-pages`, which only Amelia can run.

## Site copy

- [ ] No bio anywhere names the methods. SEM, multilevel models, measurement invariance, and
      logistic and multinomial regression appear in none of them; `research.qmd` names
      structural equation and item response models and is the only place that does. The
      strongest evidence available is already recorded in `areas.yml` under WeCook: a latent
      physical activity model across child surveys, parent surveys and wearable tracker data,
      with invariance tested across the three.
- [ ] `software.qmd:21` says "the unglamorous middle of applied research: documenting,
      cleaning, linking, and reporting on administrative data", which narrows the work twice in
      one sentence: to one subject area, and to the cleaning half. The same sentence is the
      GitHub profile README's, recorded at `bios.yml:91`. `index.qmd:55` has the same problem in
      different words: "R and Shiny tools that make messy administrative data easier to
      document, clean, and report on". The four areas in `areas.yml` are what a general version
      would draw on. Line numbers move; grep for "unglamorous" and "messy administrative".
- [ ] Neither the `index.qmd` paragraph nor the `software.qmd` opening line is tracked in
      `bios.yml`, so `bio_report()` cannot tell when they drift.
- [ ] Brown Bagger session 2 title, for 2026-11-11.
- [ ] Decide what happens to `investigate.yml`. The canonical look-into list is a Claude Doc
      kept elsewhere; this file was started before that was known about and now says so at the
      top. Either delete it or keep it strictly for verification results that belong with the
      repository.

## Generated: fix in the export repository, not here

- [ ] `_data/lab_skills.json` holds only physiology lab equipment (Biodex, EMG and MMG,
      metabolic carts, force plates) and no statistical methods at all.
- [ ] `_data/positions.json`, NSWERS entry: "to support public research initiatives" is an
      availability claim the synthetic data does not support. The same wording was removed from
      three files here on 2026-10-16.
- [ ] `_data/software_dev.json`, Table Relationship Explorer: the description says "(with a
      Python/Streamlit port)" without saying whose. It is Eugene Aiken's, and he carried it on
      as Cartographer at Common Gene Labs, which credits the original design. Drafted sentence
      and the evidence are in `areas.yml`. This feeds the CV PDF as well as the site.

## Outside this repository

- [ ] GitHub profile README: says "administrative data", contains em dashes against house
      style, and repeats the synthetic-data availability claim. Update the `github-readme`
      entry in `bios.yml` afterwards; it has no `file`, so drift there is not detected
      automatically.
- [ ] GitHub profile Bio field: "R/Shiny apps for data cleaning, documentation" is missing its
      conjunction. 146 of 160 characters, so there is room.
- [ ] `amelia-m/pleasantry`: tick "Use your GitHub Pages website" in the repository details now
      that Pages is live, rather than typing the URL.
- [ ] AI provenance on the `recode-studio`, `table-explorer` and `lspc-weather` descriptions.
      pleasantry now names both assistants and the others name none, which reads as though the
      joke package were the only one that had help. The verified split for the two work tools
      is in `areas.yml`; lspc-weather is almost entirely Claude Code, with two Codex commits
      and Copilot as reviewer.
- [ ] Repo topics: rOpenSci's development guide recommends "r", "r-package" and "rstats" for an
      R package, and `rpackage` and `r-packages` are not part of that convention. Source read
      from the repository rather than a search result: `ropensci/dev_guide`, commit `71e2a5c`,
      `maintenance_github_grooming.Rmd`. agent-config `docs/github-repo-settings.md` is the
      natural home for it.

## Open questions

- [ ] AI Engineer Omaha, 2026-10-15: Amelia's look-into log calls the meetup "Jev and the
      Judgment Layer", while `events.yml` describes the Jev talk as the first of two. Those may
      be the meetup title and a talk title or the same thing; the entry was left as written
      rather than overwritten on a guess.
- [ ] `areas.yml` carries twelve `todo` fields, mostly on the older positions, and five entries
      with no role recorded at all. `work_areas()` lists both, so read it rather than trusting
      this count.

## From the 2026-10-17 pre-merge review

- [ ] Confirm the look-into Claude Doc is not shared by link. Its URL sat in this repository for
      about two hours on 2026-10-16 to 17, and a link-shared artifact is readable by whoever
      holds the URL; a private one is not.
      Context: the branch was rebuilt from `main` and force-pushed on 2026-10-17 to remove
      content that did not belong in a public repository. GitHub still serves the old commits
      to anyone who already has a SHA until it garbage-collects them. Not pursued with GitHub
      Support (Amelia, 2026-10-17: "it's not that serious").
- [ ] The downstream-link association lives in two files: the ids and URLs in `links.yml`
      (`related:` group) and the software_dev-name-to-id mapping in `software.qmd`. A second
      downstream project means editing both. Putting the owning name on the links.yml entry
      would let `site_links()` validate it and remove the per-page special case.

## Repo setup not done here

- [ ] Nothing on GitHub enforces the review step in `.agents/project-profile.md`: no rulesets,
      no CI. A ruleset on `main` requiring pull requests and blocking deletion and force-pushes
      would back it up; settings are Amelia's to change. Path: repository Settings, Rules,
      Rulesets.
- [ ] Automatic Copilot review appears to be on for the account, against the global rules.
      Account setting, Amelia's to change: https://github.com/settings/copilot/code_review
- [ ] `_scratch/` is not in `.gitignore`. No such directory exists in this checkout yet, so
      this is only worth doing if one is going to be created.
