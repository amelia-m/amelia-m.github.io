# CLAUDE.md

Guidance for AI assistants working in this repository.

## Attribution

On (Amelia, 2026-10-09). End commit messages with:

```
Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
```

Pull request text gets the harness's generated-with footer. The same rule
applies in the repository this site's content is exported from, so the
per-project question does not need asking again.

## Generated files

`_data/` and `files/` are written by an export from the source repository and
are overwritten on the next run. Fix content at its source, never here. Hand
edited: the pages, `likes.yml`, `links.yml`, `_quarto.yml`, the stylesheets,
`R/site.R`, blog posts, and images. See README.md.

## House style

- Never write an em dash (U+2014): use a spaced hyphen, a comma, or a colon.
- Local commit and push hooks check every file before it can reach this public
  repository. If one blocks a change, fix the content rather than bypassing the
  check; never use `--no-verify`.
- External links in the navbar must also appear in `links.yml`, which the
  render checks.
