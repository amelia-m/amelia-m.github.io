# Project profile: amelia-m.github.io

How agents work in this repository, kept here so it survives sessions. `CLAUDE.md` imports
this file. Open items go in `TODO.md`, not here.

## Review, push and merge

Level 2: push its own branch after a clean local review; every merge still waits for Amelia.
Amelia, 2026-10-17: "level 2, push after review but ask before merging".

- Own branch only. Never push to `main`: nothing on GitHub protects it, so a direct push there
  is a merge Amelia never made. Never push to `gh-pages` or run `quarto publish gh-pages`:
  that branch is what GitHub Pages serves, so pushing it publishes the live site at once.
- Clean local review, run before anything is pushed rather than after it reaches GitHub:
  - Before a push, review the commits being pushed. Before asking Amelia to merge, review the
    pull request's whole diff against `main`: this branch is reused, so a PR can carry commits
    no earlier review saw.
  - The review is the one "Which review skill for which job" in the global rules picks
    (agent-config `AGENTS.md`). A cloud session does not load those rules; for this repository
    the answer is normally `/code-review`, at higher effort for code than for prose.
  - Every finding is fixed, or answered in the PR body.
  - `quarto render` of the whole project completes, not a single page: the navbar link check
    runs from `index.qmd`, and `R/site.R` also stops the render on a duplicate or unknown
    `links.yml` id and on a bibliography it cannot find or convert. A warning that the blog
    listing matches no files is expected until the first post exists.
  - Then `grep -rlE '(&lt;|<|%3C)U\+[0-9A-Fa-f]{4}' _site`, which should find nothing. Under a
    non-UTF-8 locale, which is what a cloud session has, R writes non-ASCII characters as
    literal `<U+2013>` text and the render still succeeds. `R/site.R` switches the locale for
    every page that sources it and stops if it cannot, and the cloud session hook sets a UTF-8
    locale for everything else, so a hit means a page got past both.
  - Why first, not after: Amelia, 2026-10-17, of Copilot's review: "it routinely runs out of
    tokens, so we should be dispatching codereview agents before any pushes/merges on github
    to try to identify &address as many issues as possible before they reach the remote".
- CI: none; `quarto render` output goes in the PR body.
- Nothing scans what a cloud session pushes. The commit and push hooks `CLAUDE.md` mentions are
  agent-config's identifier scan, installed per machine; a cloud checkout has none
  (`.git/hooks` holds only samples, checked 2026-10-17). This repository is public, so read
  the diff before every push for anything about other people, private links, or personal
  details. Not rendering into `_site` is not the same as not being published.
- Still Amelia's at every level: deleting branches or tags, force-pushing, rewriting history,
  repository settings, and publishing the site.
- GitHub checked 2026-10-17: `main` unprotected (`protected: false`, no branch protection, no
  rulesets); `allow_auto_merge` false; `delete_branch_on_merge` false; no CI workflows. Agents
  act on GitHub as `amelia-m` (PRs #23 to #25 were opened and merged under her login within
  15 seconds), so GitHub cannot tell an agent's push or merge from hers, and no repository
  setting can enforce the review or the merge rule: they rest on this section. Copilot
  reviewed one pull request of the first 25, PR #1, at Amelia's request, so automatic Copilot
  review is off in practice.
