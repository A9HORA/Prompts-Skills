# Source Registry

Sources vetted for reuse. Because this file lives inside the skill, it persists across conversations once the skill is installed — this is the durable source list.

**Editing:** add a line under the right tier. Format: `- Name — URL — what it's good for`. Keep tiers honest; the tier is what decides which source wins a conflict.

**Rule for Claude:** prefer sources listed here. If the user offers a source that isn't here, state its tier, say whether it conflicts with anything already listed, and ask whether to add it. Never add silently. If a listed source turns out to be wrong or stale, say so rather than deferring to it.

---

## T1 — specifications, standards, primary source code

Highest trust. A T1 source overrides everything below it.

- *(empty — add yours)*

## T2 — official vendor documentation

- *(empty — add yours)*

## T3 — peer-reviewed papers

- *(empty — add yours)*

## T4 — vendor engineering blogs

Useful for design rationale and internals that never made it into the docs. Not authoritative on current behaviour.

- *(empty — add yours)*

## T5 — tutorials, StackOverflow, forum posts

Lowest trust. Useful for finding out that a problem exists; not for what the correct behaviour is. Never cite a T5 source against a T1 one without flagging the conflict.

- *(empty — add yours)*

---

## Known-bad or deprecated sources

Sources to actively avoid, and why. Add here when something turns out to be stale, wrong, or superseded — this saves repeating the mistake.

- *(empty)*
