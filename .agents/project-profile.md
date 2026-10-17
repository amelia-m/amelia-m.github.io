# Project profile: amelia-m.github.io

How agents work in this repository, kept here so it survives sessions. `CLAUDE.md` imports
this file. Open items go in `TODO.md`, not here.

## Review, push and merge

Level 2: push after review; every merge still waits for Amelia. Amelia, 2026-10-17: "level 2,
push after review but ask before merging".

- Clean local review: the review chosen from the routing table in the global rules ran on the
  change (`/code-review` for a bug hunt on a branch), every finding is fixed or answered in the
  PR body, and `quarto render` completes. The review runs before anything is pushed, not after
  it reaches GitHub. Amelia, 2026-10-17: "it routinely runs out of tokens, so we should be
  dispatching codereview agents before any pushes/merges on github to try to identify &address
  as many issues as possible before they reach the remote" (said of Copilot's review).
- CI: none; `quarto render` output goes in the PR body. The render is the only automated
  check: it stops if an external navbar link is missing from `links.yml`. A warning that the
  blog listing matches no files is expected until the first post exists.
- Still Amelia's at every level: deleting branches or tags, force-pushing, rewriting history,
  repository settings.
- GitHub checked 2026-10-17: no rulesets on the repository; legacy branch protection could not
  be read from a cloud session (HTTP 403); `allow_auto_merge` false; `delete_branch_on_merge`
  false; no CI workflows. Nothing on GitHub enforces the review step, so it rests on agents
  following this section. Automatic Copilot review is an account setting
  (https://github.com/settings/copilot/code_review) and appears to be on, since it reviewed
  PR #1 here; the global rules want it off. Amelia's to change.
