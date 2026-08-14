---
name: deep-tech-research
description: Produce an exhaustive, build-grade research dossier on any computing technology — spec, internals, wire format, APIs, test surface, security, failure modes — with every claim tagged VERIFIED / UNVERIFIED / UNKNOWN so gaps stay visible instead of being smoothed into confident prose. Use whenever someone wants deep, complete, thorough, or in-depth research on a technology, protocol, language, file format, library, framework, or runtime, or wants to understand one well enough to BUILD with it, parse it, reverse-engineer it, or test it. Covers requests like "everything about X", "technical deep dive on X", "I need a reference for X", "how does X actually work internally", or "I'm writing a client/parser/plugin for X and need the whole surface". Also use when someone reports that earlier research missed something and wants the coverage checklist permanently updated. Trigger even when the word "research" never appears — "I need to know everything about gRPC before I write a client" is exactly this skill.
---

# Deep Technology Research

Produce a research dossier on a technology that is complete enough to build with, not just read.

The core discipline: **make uncertainty legible.** A dossier where 60% of claims are verified and 40% are honestly marked unknown is far more useful than one that is 100% fluent, because the reader knows where to spend their own verification effort. Fluency is not accuracy, and a confident wrong byte offset costs more than an admitted gap.

## Before starting

Read these three files. They carry the substance; this file carries the workflow.

- `references/accuracy-protocol.md` — the claim tags, the abstention rule, the verification pass. Non-optional; this is what makes the output trustworthy.
- `references/coverage-checklist.md` — the layers every dossier must cover. **This is the file that gets edited when a gap is found.**
- `references/artifacts.md` — the engineering artifacts to extract (grammars, byte tables, oracles). These are what make a dossier build-grade.

Then check `references/source-registry.md` for sources the user has already vetted, and prefer them.

Read `references/evidence.md` only if the user asks why the method is shaped this way.

## Scope the request first

Ask for the version if it isn't given. "Research gRPC" produces a worse dossier than "gRPC core plus grpc-go, current stable, C-core wire protocol." Narrow scope buys depth. One clarifying question is worth several wasted turns.

Then establish which of these the user actually needs, because it changes what to emphasize:

- **Class A — building ON it.** Plugins, extensions, apps, integrations. Emphasize APIs, config, extension points, error contracts.
- **Class B — building FOR it.** Parsers, linters, disassemblers, converters, debuggers, codemods. Emphasize grammar, byte-level format, semantics, edge cases.
- **Class C — testing it.** Conformance runners, fuzzers, differential testers, load and chaos harnesses. Emphasize oracles, invariants, input taxonomy, fault injection, environment matrix.

If they don't say, assume all three and cover the checklist fully.

## Use tools

If search or fetch is available, use it. Do not write from memory alone — the facts most likely to be needed (version numbers, defaults, byte offsets, API signatures, CVEs) are exactly the facts most likely to be stale or confabulated.

If no tools are available, say so at the top and label the whole document UNVERIFIED — NO TOOL ACCESS. Then still produce it, because a tagged draft the user can verify is worth having.

## Workflow

Work through these in order and show each one. Skipping the audit phases defeats the point.

**A — Scope.** Define the technology in three sentences. List versions and the current stable one. Name the governing body. List the primary sources to be used, tiered T1–T5, cross-checked against the source registry. Flag registry gaps.

**B — Outline.** A hierarchical outline covering every checklist item. Per node: source availability SOLID / THIN / MISSING, the artifacts it should yield, and which build class it serves. No prose yet. Getting the skeleton right first prevents the drift where early sections are deep and later ones are one-liners.

**C — Expand.** Write each section in depth, tagged, with artifacts attached. Depth over breadth. If the user is in a chat interface with output limits, expand in batches and say what comes next.

**D — Self-audit.** Four passes, written out, not silent:

1. *Coverage sweep.* Re-read the checklist. Name every layer covered shallowly or skipped. Fill them.
2. *Chain-of-verification.* Take the 8–15 riskiest claims. Restate each as a standalone question that does not reveal what the draft said, answer it fresh from sources, then compare. Where they differ, the draft is wrong. The isolation matters — shown its own sentence, a model tends to agree with itself.
3. *Adversarial read.* "What would a maintainer of this technology say is wrong or missing here?" Answer honestly and fix it.
4. *Tag audit.* Anything untagged gets tagged. Anything marked VERIFIED whose URL and clause can't be restated right now gets demoted to UNVERIFIED.

**E — Claim ledger.** A table of every substantive claim: `ID | claim | tag | source + URL | tier | version | date`. This is the completeness guarantee — nothing in the prose may be missing from it.

**F — Memory palace.** Only if the user asked for one. Rooms are coverage layers; each holds 3–7 vivid concrete objects, each citing its ledger IDs; give a fixed walking order. State plainly that a palace is a compression device and therefore cannot hold every detail — it is the index, and the ledger is what guarantees nothing was lost.

**G — Closing sections.** Unknown/Unverified/Conflicting gathered in one place. Coverage self-assessment rating each layer DEEP / ADEQUATE / THIN / MISSING. "How to verify this dossier" — the exact sources and commands a human should run, ordered by risk. The correction log from D2.

**H — Token estimate.** Give a per-phase estimate, labelled ESTIMATE — not measured, and say the authoritative numbers are in the API usage fields or the platform usage panel. Never dress an estimate as telemetry.

## Output

For a substantial dossier, write to a file rather than dumping it in chat — the user will want to keep it, diff it, and hand it to other people. Markdown by default.

If the dossier will exceed the output limit, never truncate silently. Emit scope and outline first, then numbered batches, ending each with what comes next. Never drop a citation or a tag to save space.

## When the user finds a gap

This is expected and the skill is built for it. Earlier dossiers will miss things; that's information, not failure.

When the user says a layer was missed, an artifact wasn't extracted, or a rule needs to change:

1. Fix the current dossier first.
2. Then make it permanent — edit the reference file so the gap can't recur:
   - a missing topic or layer → add a numbered item to `references/coverage-checklist.md` under the right group
   - a missing artifact type → add a bullet to `references/artifacts.md`
   - a new rule about tagging, sourcing, or abstention → add a numbered rule to `references/accuracy-protocol.md`
   - a source they want used from now on → add it to `references/source-registry.md` with its tier
3. Log it in `CHANGELOG.md`: the date, what was missed, and which file changed.
4. Tell them plainly which file you edited and what the new line says, so they can check it and edit it themselves later.

If the skill is installed rather than sitting in the working directory, the installed copy may be read-only. Copy it to a writable location, edit there, repackage with `package_skill.py` from the skill-creator skill, and hand back the `.skill` file for them to re-save. Keep the folder name and the `name` field unchanged so it updates in place instead of creating a duplicate.

When the user offers a source that isn't in the registry: tell them its tier, say whether it conflicts with anything already there, and ask whether to add it. Don't add silently.

## Other prompt shapes

- `templates/lite.md` — one-shot version for small or weak models, no search, or tight output limits. Fewer constraints, because instruction-following degrades as constraints multiply and small models drop the ones at the back.
- `templates/phased.md` — three standalone prompts (scope/outline, per-section expansion, final audit) for running the work across turns or across models. The most reliable option for large technologies.

## Honest limits — state these to the user, don't bury them

No prompt or skill delivers 100% accuracy. Models hallucinate at measurable, variable rates and have fixed knowledge cutoffs. Retrieval reduces this substantially but does not eliminate it. Fabricated URLs are the single most common failure mode, so tell the user to click them.

What this skill actually delivers: maximum coverage, traceable claims, and visible gaps. Verification against primary sources is the human's job, and the dossier should tell them exactly where to start.
