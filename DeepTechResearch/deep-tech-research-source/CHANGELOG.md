# Changelog

Log every gap found and every edit made. This is how the skill improves instead of repeating the same omission.

Format:

```
## YYYY-MM-DD
- GAP: what was missed, and where it was noticed
- FIX: which file changed, and what the new line says
```

---

## 2026-07-31 — initial version

Built from Master Research Prompt v3. Structure: 37-item coverage checklist across five groups, nine-rule accuracy protocol with five claim tags, artifact extraction list, persistent source registry, lite and phased templates.

Gaps already fixed during development, kept here as a record of what the design is guarding against:

- GAP: objective covered only tools built *on* a technology, ignoring tools built *for* it and tools that *test* it.
  FIX: three build classes A/B/C in `SKILL.md`; twelve test-surface layers (items 17–28) in `coverage-checklist.md`.
- GAP: no way to tell a verified claim from a remembered one, so gaps got smoothed into confident prose.
  FIX: five-tag system plus mandatory abstention in `accuracy-protocol.md` rules 2 and 3.
- GAP: fabricated URLs attached to `[V]` tags, defeating the point of tagging.
  FIX: `accuracy-protocol.md` rule 4.
- GAP: roadmap items presented as shipped facts.
  FIX: global forward-looking rule, `accuracy-protocol.md` rule 5.
- GAP: no durable source list across conversations.
  FIX: `references/source-registry.md`, which persists with the installed skill.
