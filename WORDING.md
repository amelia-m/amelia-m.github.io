# Wording decisions

Why the words are the words. Mostly so a decision is not relitigated from
scratch six months later, and so a rejected option is not cheerfully
regenerated as a fresh idea.

`bios.yml` holds what each bio currently says. `BIOS.md` is the list of places
to change when something changes. This file is the reasoning.

## Principles

These came out of actual edits, not from theory. They apply to anything written
about me anywhere.

**Purpose over tooling, but only when something has to give.** This is a
tie-breaker for a field with a hard character limit, not a general preference.
In one line, what the work is for beats what it was built with, and a stack is
also a fact that has to be maintained while a GitHub link answers the same
question and never goes stale.

Where there is room, name the tools. The site already does, and should:
`fun.qmd` labels a project "React, TypeScript, and Vite", `research.qmd` names
tidysynthesis and syntheval, `software.qmd` says R and Shiny outright. Specific
tools are searchable, they tell a collaborator what they would actually be
picking up, and on a CV or a LinkedIn profile they are often the thing being
filtered on. Dropping "R & Shiny" from a 120 character headline was a decision
about that headline, not a rule about the rest.

**Do not pigeonhole the subject matter.** "Administrative data" and "applied
research" both narrow the work to one of its halves. Name the specific project
where it is specific, as with the NSWERS synthetic data, and leave the general
description general.

**Do not let the tooling swallow the methods.** Several bios read as though
cleaning data is the whole job. Measurement, missing data, multilevel and
structural equation models are the other half and are easy to leave out,
because tooling is more concrete and writes itself more readily.

**A claim about regularity is a claim about me.** The Events page lists
Regulars, which asserts a habit. An event that runs monthly and that I have
never attended does not belong there. The dated entry is the honest version
until going is actually a pattern.

**Prefer durable to precise when the page is published by hand.** Lincoln AI
moved from Wednesdays to Tuesdays partway through the year, so the cadence does
not name a day. Link a group's home page rather than a dated event page, which
stops being useful the day after.

**Do not publish a URL that could not be checked.** Where a link had to go in
unverified, the data file says so next to it.

**No em dash.** From `CLAUDE.md`. A spaced hyphen, a comma, or a colon.

## AI Engineer Omaha headline

The field is labelled "what you build, in one line" and has a `maxlength` of
**120**, read off the input rather than counted off a screenshot. An estimate
from counting glyphs in a screenshot of deliberately overflowed text came out
at 115 to 120, which happened to be right and was still a guess.

Budget notes, because they bite:

- Spelling out "and" instead of "&" costs 2 characters and has twice been the
  difference between fitting and not.
- A trailing full stop is the cheapest character to sell. A headline is a
  fragment and does not need one.
- "raw" is the next cheapest, since "input" already implies unprocessed.

### Rejected, and why

| Wording | Why not |
| --- | --- |
| "R and Shiny tools that make messy **administrative** data trustworthy" | Narrows the work to one subject area. |
| "R and Shiny tools that make messy data trustworthy" (50 chars) | Tooling only, and under-answers a question everyone else in the room could answer the same way. Was recorded as approved when it was not. |
| "...to **publication**" | Narrows to the academic half, and reads as visiting in a room of engineers. Also 122, over. |
| "...to **deliverable**" | Project-management register against the concrete "raw input" and "model output", and breaks the modifier-plus-noun pattern of the other two. Also 122, over. |
| "**Statistical outputs** are only as good as..." | Says "output" twice, once in the claim and once in "model output". |
| "**Data quality limits output quality**" | Same echo, and drops the word that distinguishes statistical models from ML models. |
| "tools **for** raw input to model output" | "for" does not carry range meaning on its own. The intended sense was "for everything from", which is 15 characters more and does fit once the stack is dropped. |

### Settled

- "tools", not "R & Shiny tools". A budget decision for this field only. The
  card links to GitHub, so the stack is one click away, and the 11 characters
  bought "for everything from".
- "for everything from X to Y to Z", with the ellipsis spelled out.
- "reporting", not "report". Chosen twice over the noun.
- No trailing full stop.
- "model output" stated outright, because no other bio says anywhere that I
  fit models at all.

### Still open

The opening clause. The live headline is the 120 of 120 version from before
this discussion, so nothing here is on the profile yet.

## Adding to this file

A wording decision is worth an entry when it took more than one exchange, when
an option was rejected for a reason that is not obvious from the result, or
when a hard constraint was discovered. One line is fine. The rejected options
matter more than the chosen one, since those are what get suggested again.
