# CLAUDE.md

Guidance for AI assistants working in this repository.

What agents may push and merge without asking is in the project profile, imported here so
every session reads it:

@.agents/project-profile.md

## Attribution

On (Amelia, 2026-10-09). End commit messages with a trailer naming the model
writing that commit:

```
Co-Authored-By: Claude <model name> <noreply@anthropic.com>
```

Always the model in use at the time of the commit (Amelia, 2026-10-21:
"Always make commit footers reflect the model currently in use"). Take the
name from the attribution line the harness gives in the current turn, which
changes when the model is switched mid-session; in a cloud session,
`get_session`'s `last_served_model` is the check. Never copy it from an
earlier commit or from this file: this file used to name a fixed model, and a
session switched from Opus 5 to Opus 5.5 went on signing its commits Opus 5.
A commit carrying more than one model's work, such as a squash, names each.
Keep the harness's `Claude-Session` line as well.

Pull request text gets the harness's generated-with footer. The same rule
applies in the repository this site's content is exported from, so the
per-project question does not need asking again.

## Generated files

`_data/` and `files/` are written by an export from the source repository and
are overwritten on the next run. Fix content at its source, never here.
Everything else is hand edited; README.md lists it.

## House style

- Never write an em dash (U+2014): use a spaced hyphen, a comma, or a colon.
- Local commit and push hooks check every file before it can reach this public
  repository. If one blocks a change, fix the content rather than bypassing the
  check; never use `--no-verify`.
- External links in the navbar must also appear in `links.yml`, which the
  render checks.
