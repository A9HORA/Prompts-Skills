# Phased Template

Three standalone prompts for running the work across turns, or across different models. The most reliable option for a large technology: each subtask gets the model's full attention, and no single response has to carry everything.

Use this when the technology is large, the model is weak, or accuracy matters more than speed.

## Prompt 1 — scope and outline

```
Act as a senior systems engineer scoping a build-grade research dossier on
{TECHNOLOGY}, version {VERSIONS}. Do NOT write the dossier yet.

Deliver:
(a) a 3-sentence definition;
(b) versions and editions, and the current stable version;
(c) the governing body and the exact primary specs and repos (names plus URLs),
    tiered T1 (spec or source code) through T5 (forum post);
(d) a hierarchical OUTLINE covering all of these layers:
    [paste the coverage checklist]

For each outline node: mark source availability SOLID / THIN / MISSING; name the
engineering artifacts that section should yield (grammar, state machine, byte
format, API signatures, oracles, invariants, conformance suite, fuzz surface,
environment matrix); and note which build class it serves — A (built ON it),
B (built FOR it), C (tests it).

Use search if available. Tag claims [V] verified / [U] from memory / [?] unknown.
Never invent a URL.
```

Run this on two different models and diff the outlines. A layer present in one and missing from the other is a coverage hole in the weaker one.

## Prompt 2..N — expand one section per turn

```
Using the outline and sources from before, write section {N}: {SECTION NAME}
for {TECHNOLOGY} in full depth.

Requirements:
- Tag every claim [V] / [U] / [?] / [!] / [F]. A [V] tag needs the URL, the
  version, and the date.
- Never invent a URL. Unsure means [U] or [?].
- Use RFC 2119 keywords (MUST / SHOULD / MAY) only for real spec requirements,
  and cite the clause.
- Include this section's engineering artifacts: grammar, state machine,
  byte-format table, API signatures with error contracts, invariants written as
  testable properties, oracles, extension points, and minimal WORKING code
  labelled with version.
- Mark "CHECKABLE:" on anything a human could verify by running something.

End with two lines: what in THIS section is still thin, and what is unverified.
```

Batch two or three small sections per turn if they're short. Keep the test-surface sections separate — they need room.

## Final prompt — gap audit and verification

```
Here is the assembled dossier on {TECHNOLOGY}: [paste]

Audit it rigorously, in writing:

1) COVERAGE. Rate every checklist layer DEEP / ADEQUATE / THIN / MISSING. List
   every THIN or MISSING item and fill it now, with sources.

2) VERIFICATION. Extract the 15 riskiest factual claims — versions, defaults,
   byte offsets, API signatures, error codes, performance numbers, CVEs,
   security behaviour. For each: restate it as a standalone question that does
   NOT reveal what the dossier said; answer it fresh from sources; compare.
   Where they differ, the dossier is wrong — correct it and log the correction.

3) CITATION CHECK. For every [V] claim, restate the URL and the specific clause.
   Any you cannot restate gets demoted to [U].

4) CONFLICTS. Every place sources disagreed, with tiers.

5) Produce: the claim ledger, the "Unknown / Unverified / Conflicting" section,
   the "How to verify this dossier" list, and the correction log.

Return the corrected dossier plus all audit outputs.
```

Run this on the strongest model available, not the one that wrote the draft if that one was weaker. A model auditing its own output on facts it never knew will pass itself.
