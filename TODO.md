# TODO

Open items for this repo, kept here so they survive chat sessions. Newest at the bottom of
each section. Delete a line when it is done.

Started 2026-10-17 from a session that had accumulated all of this in chat, which is what the
agent-config profile warns against: nothing should live only in one tool's memory. Items that
belong to another repository are marked as such rather than left out, because this is where
they were found.

## Publish

- [ ] Publish what has been merged since 2026-10-27: everything after #32. `gh-pages` was last
      published on 2026-10-27 at 11:34 CDT (`95a3715`), after #32 was merged at 10:19, and the
      live site was checked that day to show #32's Carpentries date. Needs `git pull` on `main`
      and then `quarto publish gh-pages`, which only Amelia can run. A `gh-pages` commit does not
      record the source commit it was built from, so compare the dates in
      `git log origin/gh-pages` and `git log origin/main` rather than trusting a hash written
      here; this item named an older publish for a week after it was replaced.

## Site copy

- [ ] The prose bios do not name the methods. SEM appears only in the X and GitLab bios (both
      since 2026-10-21) and `research.qmd`, which says "structural equation"; multilevel
      models only in the X and GitLab bios; logistic and multinomial regression only in the
      GitLab bio; measurement invariance in no bio at all. The site's own bios and the GitHub
      README are the ones that matter most here. The
      strongest evidence available is already recorded in `areas.yml` under WeCook: a latent
      physical activity model across child surveys, parent surveys and wearable tracker data,
      with invariance tested across the three.
- [ ] `software.qmd` says "the unglamorous middle of applied research: documenting,
      cleaning, linking, and reporting on administrative data", which narrows the work twice in
      one sentence: to one subject area, and to the cleaning half. The same sentence is the
      GitHub profile README's, recorded in `bios.yml` under `github-readme`. `index.qmd` has the
      same problem in different words: "R and Shiny tools that make messy administrative data
      easier to document, clean, and report on". The four areas in `areas.yml` are what a
      general version would draw on. Grep for "unglamorous" and "messy administrative".
- [ ] Neither the `index.qmd` paragraph nor the `software.qmd` opening line is tracked in
      `bios.yml`, so `bio_report()` cannot tell when they drift.
- [ ] Brown Bagger session 2 title, for 2026-11-11.
- [ ] Decide what happens to `investigate.yml`. The canonical look-into list is a Claude Doc
      kept elsewhere; this file was started before that was known about and now says so at the
      top. Either delete it or keep it strictly for verification results that belong with the
      repository.
- [ ] Missing data vanishes silently instead of being flagged. `md()` in `R/site.R` turns a
      missing value into an empty string, so a generated row with no `role` or `when` renders
      as "* · 2026*" and the render succeeds. That is right for an optional field and wrong for
      a required one; decide per field, and stop the render when a required one is missing.
      The post-render check cannot see this: an empty field leaves no symptom in the HTML.
      The same applies to a YAML field holding inline R, which `md()` escapes into literal
      text; the check catches the common form, but stopping on it where the field is read
      would be exact.

- [ ] The X bio chosen 2026-10-21 may change ("might want to change later"). The drafts not
      chosen, and why each was a contender, are in `WORDING.md` under "X bio".

## Generated: fix in the export repository, not here

- [ ] `_data/lab_skills.json` holds only physiology lab equipment (Biodex, EMG and MMG,
      metabolic carts, force plates) and no statistical methods at all.
- [ ] `_data/positions.json`, NSWERS entry: "to support public research initiatives" is an
      availability claim the synthetic data does not support. The same wording was removed from
      three files here on 2026-10-16.
- [ ] `_data/software_dev.json`, Table Relationship Explorer: the description says "(with a
      Python/Streamlit port)" without saying whose. It is Eugene Aiken's, and he carried it on
      as Cartographer at Common Gene Labs, which credits the original design. Replace the
      description with (agreed 2026-10-17; the evidence is in the `areas.yml` note):
      "Interactive tool for discovering and visualizing primary/foreign-key relationships
      across tabular data: multi-signal key inference with confidence scoring, interactive
      entity-relationship diagrams, and exportable reports across many file and database
      formats. Eugene Aiken contributed a Python and Streamlit port, which he carried on in
      early 2026 as Cartographer at Common Gene Labs, crediting the original concept and
      design. I contributed its data privacy guide and setup instructions."
      This feeds the CV PDF as well as the site.

## Outside this repository

- [ ] GitHub profile README: says "administrative data", contains em dashes against house
      style, and repeats the synthetic-data availability claim. Update the `github-readme`
      entry in `bios.yml` afterwards; it has no `file`, so drift there is not detected
      automatically.
- [ ] GitHub profile Bio field: "R/Shiny apps for data cleaning, documentation" is missing its
      conjunction. 146 of 160 characters, so there is room.
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
- [ ] The export repository's attribution rule may name a fixed model, as this one's did until
      2026-10-21. `CLAUDE.md` says the same rule applies there, so it should say the model in
      use at the time of the commit.
- [ ] agent-config `AGENTS.md`, "AI attribution in git and pull requests is decided per
      project": the "always the current model" rule belongs there too, for every project that
      allows a trailer. Draft handed to the agent-config session on 2026-10-23; delete this
      once it is in AGENTS.md there.

## Open questions

- [ ] AI Engineer Omaha, 2026-10-15: Amelia's look-into log calls the meetup "Jev and the
      Judgment Layer", while `events.yml` describes the Jev talk as the first of two. Those may
      be the meetup title and a talk title or the same thing; the entry was left as written
      rather than overwritten on a guess.
- [ ] `areas.yml` has `todo` fields, mostly on the older positions, and entries with no role
      recorded at all. `work_areas()` lists both.
- [ ] Make sure the look-into Claude Doc is not shared by link, and turn link sharing off if it is.
- [ ] The WiTH link is `http://witheartland.org/` as given. Does the site open as `https://`?
      The build environment cannot reach it to check.
- [ ] The UTF-8 locale switch sits at the top of `R/site.R`, so it covers only pages that source
      that file, plus cloud sessions through the session hook. A blog post with its own R chunks,
      rendered on a Linux machine under a POSIX locale, would still write `<U+2013>`; the
      post-render check stops that render rather than letting it through. A project-wide
      setting, such as `LANG` in a Quarto `_environment` file, would fix the cause for every
      page, but C.UTF-8 is not a locale every platform has, and it has not been tried on
      Amelia's Windows machine. Raised by the whole-branch review of 2026-10-21.
- [ ] The downstream-link association lives in two files: the ids and URLs in `links.yml`
      (`related:` group) and the software_dev-name-to-id mapping in `software.qmd`. A second
      downstream project means editing both. Putting the owning name on the links.yml entry
      would let `site_links()` validate it and remove the per-page special case.

- [ ] The GoatCounter script loads from the unversioned `https://gc.zgo.at/count.js` with no
      integrity hash, as GoatCounter's own snippet does, so whatever that host serves runs on
      every page. GoatCounter also publishes versioned files (`count.v4.js`) for use with an
      `integrity` attribute. Pinning one needs the hash read from a host this build environment
      can reach, which gc.zgo.at is not (checked 2026-10-27), and the pin has to be updated by
      hand when GoatCounter changes its script. Raised by the review of the port on 2026-10-27.

## To compare

- [ ] Compare this site with a guide to building an academic site in Quarto and its companion
      website-builder app, and list what might be worth adopting: page structure, Quarto
      features, how publications and the CV are handled, automation. Decide each item with
      Amelia before changing anything. Logged 2026-10-24 at her request.
      - <https://dsquintana.com/posts/quarto-academic-site/>
      - <https://dsquintana.shinyapps.io/website-builder/>

      Neither host resolves from the cloud build environment (checked 2026-10-24), so the
      comparison needs a session that can reach them, or their text pasted in. Nothing about
      their contents is recorded here yet, because none of it has been read.
- [ ] Decide which features of another personal site to adopt: <https://schloerke.com/>,
      reviewed 2026-10-27 at Amelia's request ("dispatch an agent to review features on this
      website and we might incorporate some of them") from its source, which she gave:
      <https://github.com/schloerke/schloerke.github.io> at `382b1c6`. The live site was not
      reachable. Candidates, most useful first, none decided:
      1. A page `description` on every page; none has one, and the home page has no
         `og:description` either.
      2. Follow the reader's system light or dark setting by default
         (`respect-user-color-scheme`).
      3. A build stamp in the footer: build date and source commit, linked to the source.
      4. Refuse an export whose data shrank by more than half, best done in the export.
      5. Links on talks (slides, posters, recordings) and on the 7 papers with no DOI.
      6. A render check on pull requests, which overlaps publishing from GitHub Actions.
      7. A print stylesheet; 8. showing work a publication list misses; 9. a custom domain.
      Not worth adopting, per the review: activity heatmaps, download sparklines, nightly data
      refreshes with a deploy key, hand-built HTML, and JavaScript email obfuscation.

## Repo setup not done here

- [ ] `_scratch/` is not in `.gitignore`. No such directory exists in this checkout yet, so
      this is only worth doing if one is going to be created.
- [ ] `main` has no protection at all. A ruleset on `main` that requires a pull request and
      blocks deletion and force-pushes would stop the one failure GitHub can see: something
      pushed straight to `main`. It cannot enforce the review or the merge rule in
      `.agents/project-profile.md`, because agents act on GitHub as Amelia. Settings are hers
      to change: repository Settings, Rules, Rulesets.
- [ ] Only Claude Code reads the profile, through the `@` import in `CLAUDE.md`. Copilot's coding
      agent has worked here (`copilot/review-code-base-issues`) and nothing points it at the
      push and merge rules. Whether to add a pointer it reads, such as an `AGENTS.md` or
      `.github/copilot-instructions.md`, is a question for how agent-config wants instruction
      files laid out, so it is not decided here.
