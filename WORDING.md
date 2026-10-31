# Wording decisions

Why the words are the words. Mostly so a decision is not relitigated from
scratch six months later, and so a rejected option is not cheerfully
regenerated as a fresh idea.

`bios.yml` holds what each bio currently says. `BIOS.md` is the list of places
to change when something changes. `areas.yml` holds the areas the work falls
in and the projects in each, which is where the subject-matter wording comes
from. This file is the reasoning.

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
description general. `areas.yml` is what the general version is drawn from.

An example can narrow it without naming anything. Recode Studio was described
as exporting rules so "next quarter's data gets the same treatment as last
quarter's", which says administrative reporting cycles without using the word:
research data does not arrive quarterly. The app is dataset-agnostic, so the
example chosen to sell it should be too. Watch for cadence words generally,
since they smuggle in a kind of data.

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
stops being useful the day after, unless the event page outlives the event:
Meetup keeps a past meetup's page, so a Meetup event link serves first as the
place to sign up and then as the record.

**Do not publish a URL nobody has opened.** Check it from here where the
build environment can reach the host. Where it cannot, a URL Amelia gave from
her own browser counts as opened by her, and the data file says so next to it;
one she has not given stays out until she does.

**Say which AI, and which part.** "AI-assisted" covers everything from one
completion to the whole thing, so it tells a reader nothing. pleasantry was
written in the workshop with Positron's Posit Assistant and reworked
afterwards with Claude, and `fun.qmd` says exactly that. The same question
will come up for every other project here, and the answer is the split, not
the label. A workshop title that happens to contain the word AI is not a
disclosure.

**No em dash.** From `CLAUDE.md`. A spaced hyphen, a comma, or a colon.

**R package names stay plain.** pleasantry, tidysynthesis, syntheval, not
`{pleasantry}`: the braces were suggested for the Fun page and turned down
(Amelia, 2026-10-24: "Skip the curly braces"). A package named in passing as
code, such as `compliment` on that page, keeps its code font.

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
| "**everything** from raw data to..." | Too strong a completeness claim. "anything" was the softer version, before the whole clause went. |
| Any version built on "**models are only as good as their inputs**" | True, and obvious. Everyone in that room could write the same sentence about their own work, so it spent a third of the field distinguishing nothing. |

### Settled

The headline, entered October 16, 2026, at 112 of 120:

> I build tools for problems I come across in my own work in research, public
> policy, public health, and education

- **The build leads, not the reasoning.** Earlier drafts opened with a claim
  and arrived at the building afterwards. The field asks what you build.
- **Provenance beats justification.** Naming where the problems come from says
  something nobody else can copy. The data-quality truism it replaced did not.
- **The four areas**, which are the ones in `areas.yml`. They were worth the
  53 characters they cost: with the rationale clause gone there was room, and
  no other short bio says what subject matter any of this is about.
- No trailing full stop. A headline is a fragment.

Dropped along the way, and worth revisiting elsewhere rather than here:

- "R & Shiny". A budget decision for this field only, twice over. The card
  links to GitHub, so the stack is one click away.
- "from raw data to model output to reporting", and with it "model output",
  which was the only phrase in any bio saying I fit models at all. The X bio
  closed that gap on 2026-10-21 by naming SEM and multilevel models; the prose
  bios still have it, and are where it belongs rather than in a 120 character
  field.
- "reporting" over "report", chosen twice, if that clause ever comes back.

## X bio

The field allows **160** characters. X weights some characters double; by its published
counting rules nothing below is one of them, so its count and a plain count should agree.
That is inferred from the rules, not checked against X's own counter. The site goes in X's separate Website field rather
than spending the bio on it.

Live, chosen 2026-10-21, 159 of 160, and possibly temporary:

> Postdoc at UNL: measurement, SEM, multilevel models, missing data, synthetic data. I build
> R & Shiny tools for research, policy, health, and education. #rstats

Chosen for discoverability: `#rstats` is how R users find each other on X, and it is the only
draft that keeps synthetic data. This deliberately overrides the purpose-over-tooling
tie-breaker in the principles above: on X, "R & Shiny" and `#rstats` are what people search
for, so they stay and the purpose words are shortened instead. The cost is "policy" and
"health" for "public policy" and "public health", and bare "policy" can read as
organisational policy. "Adjunct faculty" is left out for space; see the last row below.

### Not chosen, kept for when it changes

| Wording | Its case |
| --- | --- |
| "Postdoc at UNL. I build R & Shiny tools for problems I hit in research, public policy, public health, and education. Measurement, SEM, multilevel models." (153) | Same provenance framing as the AI Engineer Omaha headline, so the two read as one person, with the areas written in full. Loses `#rstats` and synthetic data. |
| "Measurement, SEM, multilevel models, and missing data, applied to research, public policy, public health, and education. R & Shiny tools. Postdoc at UNL." (153) | Leads with the methods, the strongest answer to bios that read as though cleaning data is the whole job. Tooling last. |
| "Postdoc and adjunct at UNL. SEM, multilevel models, measurement, missing data. I build R & Shiny tools for problems I hit in research, policy, health, and education." (165) | Over the limit. Naming both roles costs the methods or the areas. |
| "Postdoc and adjunct faculty at UNL. Measurement, SEM, multilevel models, missing data, synthetic data. I build R and Shiny tools for the problems I hit along the way." (166) | Over the limit, and "along the way" says less than naming the areas. |

## GitLab bio

The personal account's Bio field allows **250** characters. Job title, Organization, Location
and Website are separate fields shown beside it, so the bio leaves out the role and the
university: Amelia, of an earlier round, "postdoc and adjunct are already covered by the job
title box". The same round changed "hit" to "find".

Live, chosen 2026-10-21, 227 of 250:

> I build R and Shiny tools for problems I find in my work in research, public policy, public
> health, and education. Methods: measurement, SEM, multilevel models, logistic and
> multinomial regression, missing data, synthetic data.

The areas are written in full, as in the AI Engineer Omaha headline, and the space the role
used to take goes to logistic and multinomial regression. "In my work" matters once the verb
is "find": without it, "problems I find in research" can read as faults spotted in the field
rather than problems met in her own work.

### Not chosen

| Wording | Its case |
| --- | --- |
| "Measurement, SEM, multilevel models, logistic and multinomial regression, missing data, and synthetic data. I build R and Shiny tools for problems I find in research, public policy, public health, and education." (211) | Recommended at the time: methods first, with the job title already sitting above the bio. Has the "find" ambiguity above. |
| "Measurement, SEM, multilevel models, missing data, and synthetic data. I build R and Shiny tools for problems I find in research, public policy, public health, and education." (174) | Shortest. Leaves out the regression methods, and has the same ambiguity. |
| Earlier round, 232 to 245 characters. Two of the three opened with "Postdoc and adjunct faculty", the third with "Quantitative methods in R:" | The two role openings spent the space on what the Job title field already shows, and said "hit" where these say "find". |

## Adding to this file

A wording decision is worth an entry when it took more than one exchange, when
an option was rejected for a reason that is not obvious from the result, or
when a hard constraint was discovered. One line is fine. The rejected options
matter more than the chosen one, since those are what get suggested again.
