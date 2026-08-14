# Setting up and testing deep-tech-research in Claude Code

## 1. Install

Skills in Claude Code are filesystem-based — no upload, no API call. Personal skills go in `~/.claude/skills/`, project-scoped ones in `.claude/skills/`. Source: https://code.claude.com/docs/en/skills

The `.skill` file is a zip with the folder already at its root, so unzipping into the skills directory lands it correctly.

**Personal install** (available in every project — what you want here):

```bash
mkdir -p ~/.claude/skills
unzip ~/Downloads/deep-tech-research.skill -d ~/.claude/skills/
ls ~/.claude/skills/deep-tech-research
```

You should see `SKILL.md`, `CHANGELOG.md`, `references/`, `templates/`.

**Project install instead** (committed to the repo, shared with the team):

```bash
mkdir -p .claude/skills
unzip ~/Downloads/deep-tech-research.skill -d .claude/skills/
```

Then start a **new** Claude Code session — skills are picked up at session start, not hot-reloaded.

```bash
claude
```

Confirm it loaded:

```
/skills
```

`deep-tech-research` should appear in the list.

Windows note: paths are the same, `~` resolves to `C:\Users\you`. Use PowerShell's `Expand-Archive` if `unzip` isn't available:

```powershell
Expand-Archive -Path "$HOME\Downloads\deep-tech-research.skill" -DestinationPath "$HOME\.claude\skills\"
```

## 2. Housekeeping

- **Edit:** edit the files in place at `~/.claude/skills/deep-tech-research/`. Claude Code watches skill directories and picks up `SKILL.md` changes **within the current session**, no restart needed. No repackaging either — this is the main advantage of the filesystem install over the Claude.ai one. Two exceptions: live detection covers `SKILL.md` text only, and if you create a top-level skills directory that didn't exist at session start, restart so Claude Code can watch it.
- **Disable temporarily:** rename the folder with a leading underscore, or set `"deep-tech-research": "off"` under `skillOverrides` in settings.
- **Remove:** delete the folder.
- **Version control it:** `git init` inside the folder, or symlink it from a repo. Claude Code follows symlinks out of the skills directory and reads `SKILL.md` from the target.
- **Check its context cost:** `/doctor` reports the skill-listing budget and its biggest contributors. See section 6.

## 3. Test A — does it trigger?

This is the test that matters most, and it needs no extra tooling. Start a fresh session and type a query that *should* fire the skill but never says the word "research":

```
ok i need to write a parser for ELF binaries in rust and i keep getting
confused by the section header table vs the program header table. can you
get me everything on the ELF format — the actual byte layout, offsets and
widths, not another blog post summary
```

**Pass:** Claude announces it's using `deep-tech-research`, then reads `references/accuracy-protocol.md` and `references/coverage-checklist.md` before writing anything.

**Fail modes to watch for:**
- Skill never fires → description problem, go to section 5.
- Skill fires but Claude writes prose without reading the reference files → the "Before starting" instruction isn't landing.
- Skill fires and reads files but claims are untagged → the accuracy protocol isn't being applied.

Then run a negative control in a fresh session:

```
write me a redis client in go that supports pipelining
```

This should **not** fire the skill. It asks for code, not a dossier. If it fires here, the description is over-broad.

## 4. Test B — end-to-end quality

Fresh session. Pick something with a real spec, a byte-level format, a conformance suite, and CVEs, so every part of the checklist gets exercised:

```
deep dive on RESP3, the redis wire protocol. i'm writing a client in go
from scratch and i need the framing rules exactly right, including how it
differs from RESP2.
```

RESP3 is a good test case because it's small enough to finish in one session but has a real specification, exact byte-prefix framing, and version-dependent behaviour — so bluffing is easy to spot.

Grade the output against these, which are the skill's actual claims about itself:

| Check | What to look for |
|---|---|
| Tags present | Every claim carries `[V]` / `[U]` / `[?]` / `[!]` / `[F]` |
| Tags honest | Spot-check three `[V]` claims — does the URL resolve, and does the cited clause actually say that? |
| No invented URLs | Click them all. This is the most common failure mode. |
| Byte-level detail | Actual type-prefix bytes and terminator rules, not prose description |
| Test surface covered | Checklist items 17–28 got real depth, not one-liners |
| Verification pass ran | A visible list of riskiest claims re-checked as standalone questions, plus a correction log |
| Gaps visible | An Unknown/Unverified/Conflicting section that isn't empty |
| Version-stamped | Claims say which Redis/RESP version they apply to |

An empty Unknown section on a first pass is a red flag, not a good sign — it usually means the model smoothed uncertainty into confident prose, which is the exact failure the protocol exists to prevent.

Then feed it the deliberate gap-capture test:

```
you didn't cover how RESP3 push messages interact with client-side caching
invalidation. add that to the checklist permanently so it doesn't get
skipped next time.
```

**Pass:** it fixes the dossier, then edits `references/coverage-checklist.md`, logs it in `CHANGELOG.md`, and tells you which file changed and what the new line says. Verify by `git diff` or by opening the file.

## 5. Optimizing the description (optional)

Only needed if triggering is unreliable after section 6's budget check comes back clean.

In Claude Code, `skill-creator` is a plugin, not a local script directory. Install it from the official marketplace:

```text
/plugin install skill-creator@claude-plugins-official
```

If Claude Code says `Marketplace "claude-plugins-official" not found`:

```text
/plugin marketplace add anthropics/claude-plugins-official
```

If it says the plugin isn't in the marketplace, your local copy is stale — `/plugin marketplace update claude-plugins-official`, then retry the install.

After installing, run `/reload-plugins` to make its skills available in the current session. Then ask in plain language:

```text
evaluate my deep-tech-research skill with skill-creator
```

It walks you through writing test cases and runs the loop:

- **Test cases** stored in `evals/evals.json` inside the skill directory
- **Isolated runs** — a subagent per test case so each starts with clean context, recording tokens and duration
- **Grading** — each assertion checked against the output, pass/fail with evidence written to `grading.json`
- **Benchmark** — pass rate, time, and tokens for with-skill versus without-skill in `benchmark.json`, so you can weigh the pass-rate gain against the token overhead
- **Version comparison** — blind A/B between two versions of the skill before you commit an edit
- **Description tuning** — generates should-trigger and should-not-trigger prompts, measures the hit rate, proposes description edits
- **Review viewer** — an HTML report where you inspect each output and record feedback the next iteration reads

Eval file format and full workflow: https://agentskills.io/skill-creation/evaluating-skills

`trigger-eval.json` alongside this guide feeds the description-tuning step: 10 queries that should fire, 10 near-misses that shouldn't. The negatives are deliberately tricky — "write me a redis client in go" shares keywords with the positives but wants code, not a dossier.

If you'd rather not install the plugin, run the 20 queries by hand across fresh sessions and count. Slower, same information.

Note: the baseline comparison is the whole point. Run each prompt with the skill available and again with it disabled via `skillOverrides`, in a fresh session both times. Fresh matters — leftover context from authoring the skill masks gaps in the written instructions.

## 6. Check the context budget

Do this **before** trusting any trigger test. Claude Code loads a listing of every skill name and description into context. The budget scales at 1% of the model's context window, and when the listing overflows, Claude Code drops descriptions starting with the skills you invoke least. A skill with no description in the listing stops triggering reliably — so a failed trigger test can be a budget problem, not a description problem.

```text
/doctor
```

That reports the listing's estimated context cost and the biggest contributors. `/context` shows the Skills row after the budget is applied, which is what the model actually receives.

If it's over budget, either:

- raise it — `skillListingBudgetFraction` setting (e.g. `0.02` for 2%), or the `SLASH_COMMAND_TOOL_CHAR_BUDGET` environment variable for a fixed character count
- free room — set rarely-invoked skills to `"name-only"` in `skillOverrides`

Each entry's combined `description` plus `when_to_use` text is capped at 1,536 characters regardless of budget, which is why this skill's description leads with the key use case. `skillListingMaxDescChars` changes that cap.

## 7. What to report back

If something fails, send:

- the exact query you typed
- whether the skill fired
- which reference files Claude read (visible in the session output)
- what was wrong with the output
- whether `/doctor` showed the listing over budget

Description problems and instruction problems get fixed in different files, so whether it fired is the first thing to establish.
