# Index

Everything from this project. Read in this order if you're picking it back up cold.

## Start here

| File | What it is |
|---|---|
| `deep-tech-research.skill` | **The deliverable.** Zip package of the skill. Unzip into `~/.claude/skills/`. |
| `claude-code-setup.md` | Install, housekeeping, description tuning, context budget. |
| `test-order.md` | Ordered test sequence. Run this before trusting the skill. |

## The skill, unpacked (editable)

`deep-tech-research-source/` — same content as the `.skill` file, as loose files. Split so patching a gap means adding one line, not rewriting a prompt.

| File | Role | Edit when |
|---|---|---|
| `SKILL.md` | Workflow, build classes, gap-capture loop | Rarely |
| `references/coverage-checklist.md` | The 37 layers | **A topic was missed** — main edit target |
| `references/accuracy-protocol.md` | 5 claim tags, abstention, no-fabricated-URLs, verification pass | A sourcing or tagging rule changes |
| `references/artifacts.md` | Grammars, byte tables, oracles, state machines | An artifact type was missed |
| `references/source-registry.md` | Your vetted sources by tier — persists across sessions | You vet a new source |
| `references/evidence.md` | Citations for every design choice | Never, unless the method changes |
| `templates/lite.md` | One-shot version for weak/small models | — |
| `templates/phased.md` | 3 standalone prompts for multi-turn or multi-model runs | — |
| `CHANGELOG.md` | Gap log | Every time a gap is fixed |

## Supporting

| File | What it is | Status |
|---|---|---|
| `master-research-prompt-v3.md` | The prompt before it became a skill. 8 sections: master prompt, lite variant, phased workflow, usage notes, evidence, accuracy limits, WebAssembly worked example, caveats. | Current. Useful for pasting into other tools — ChatGPT, Gemini, a raw API call. |
| `trigger-eval.json` | 20 queries: 10 should-trigger, 10 tricky near-misses. | For the description-tuning step. |
| `private-skills-vault.md` | Private vault + `--add-dir` + symlinks + skill restriction config. | **Mostly moot.** Written for a team-sharing scenario you don't have. Two bits still apply: the dotfiles-repo leak check, and the context budget. Keep it if the team situation changes. |

## Corrections applied

Three errors in `claude-code-setup.md` were fixed after reading the official Claude Code skills docs:

1. Said edits apply "on the next session." Wrong — Claude Code watches skill directories and picks up `SKILL.md` changes within the current session.
2. Told you to look for `~/.claude/skills/skill-creator/scripts/run_loop.py`. Wrong for Claude Code — `skill-creator` is a plugin there, installed with `/plugin install skill-creator@claude-plugins-official`, and it stores evals in `evals/evals.json`.
3. Had no context-budget check. Added as section 6, and as step 1 of the test order, because a truncated description makes a trigger test meaningless.

## Known state

The skill is **validated and packaged but untested.** Nothing has been run against it. Triggering is unverified. Output quality is unverified. `test-order.md` exists precisely because that work is still outstanding.

## Honest limits, carried forward

No prompt or skill reaches 100% accuracy. The design makes uncertainty legible rather than making the model correct — verification against primary sources stays your job. Fabricated URLs are the dominant failure mode, so click them. Weak models will tag guesses as verified because calibration improves with scale, so never let a weak model run its own audit. Full citations for all of this are in `references/evidence.md`.
