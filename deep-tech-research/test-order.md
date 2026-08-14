# Test order

Run in this order. Start a **fresh session** wherever marked — leftover context from earlier turns masks gaps in the skill's written instructions, which is exactly what you're testing.

## 0. Confirm installed

```bash
ls ~/.claude/skills/deep-tech-research/SKILL.md && claude
```

Then in session:

```text
/skills
```

`deep-tech-research` should be listed. If it isn't, the folder is in the wrong place or the frontmatter is malformed — run `claude --debug` to see parse errors.

## 1. Budget check — do this first

```text
/doctor
```

Claude Code truncates skill descriptions when the listing exceeds its budget, dropping them starting with the skills you invoke least. A skill whose description got dropped won't trigger reliably. If you skip this and step 2 fails, you won't know whether the description is bad or was simply never shown to the model.

Over budget? Raise `skillListingBudgetFraction` to `0.02`, or set rarely-used skills to `"name-only"` in `skillOverrides`. Then re-run `/doctor`.

## 2. Trigger test — fresh session

The query never says "research". That's the point — the skill has to fire on intent, not keywords.

```text
ok i need to write a parser for ELF binaries in rust and i keep getting confused by the section header table vs the program header table. can you get me everything on the ELF format — the actual byte layout, offsets and widths, not another blog post summary
```

| Result | Meaning | Fix lives in |
|---|---|---|
| Skill fires, reads `accuracy-protocol.md` and `coverage-checklist.md` before writing prose | Pass | — |
| Never fires | Description problem | `description:` in `SKILL.md` |
| Fires, but writes prose without reading the reference files | "Before starting" isn't landing | `SKILL.md` body |
| Fires, reads files, but claims are untagged | Protocol not being applied | `SKILL.md` body + `accuracy-protocol.md` |

## 3. Negative control — fresh session

```text
write me a redis client in go that supports pipelining
```

Should **not** fire. This wants code, not a dossier. If it fires, the description is over-broad — tighten it, then re-run step 2 to confirm you didn't break the positive case.

## 4. Output quality — fresh session

```text
deep dive on RESP3, the redis wire protocol. i'm writing a client in go from scratch and i need the framing rules exactly right, including how it differs from RESP2.
```

RESP3 is the right test case: small enough to finish in one session, but it has a real specification, exact byte-prefix framing, and version-dependent behaviour — so bluffing is easy to catch.

Grade against these:

| Check | Looking for |
|---|---|
| Tags present | Every claim carries `[V]` / `[U]` / `[?]` / `[!]` / `[F]` |
| Tags honest | Pick three `[V]` claims — does the URL resolve, and does the cited clause actually say that? |
| No invented URLs | Click all of them. Most common failure mode. |
| Byte-level detail | Actual type-prefix bytes and terminator rules, not prose about them |
| Test surface covered | Checklist items 17–28 have real depth, not one-liners |
| Verification pass ran | Visible list of riskiest claims re-asked as standalone questions, plus a correction log |
| Gaps visible | Unknown/Unverified/Conflicting section is **not empty** |
| Version-stamped | Claims say which Redis / RESP version they apply to |

An empty Unknown section on a first pass is a **fail**, not a pass. It almost always means uncertainty got smoothed into confident prose — the exact failure the protocol exists to prevent.

## 5. Gap capture — same session as step 4

```text
you didn't cover how RESP3 push messages interact with client-side caching invalidation. add that to the checklist permanently so it doesn't get skipped next time.
```

Pass: fixes the dossier, edits `references/coverage-checklist.md`, logs it in `CHANGELOG.md`, and tells you which file changed and what the new line says.

## 6. Verify the edit landed on disk

```bash
tail -20 ~/.claude/skills/deep-tech-research/references/coverage-checklist.md
tail -10 ~/.claude/skills/deep-tech-research/CHANGELOG.md
```

If you put the skill under git, `git diff` instead.

## 7. Optional — baseline comparison

The rigorous version of step 4. Run the same RESP3 prompt in a fresh session with the skill turned off (`"deep-tech-research": "off"` in `skillOverrides`), and compare. If the output is no better with the skill than without it, the skill isn't earning its token cost. That comparison, not the trigger test, is what tells you the skill works.

## What to report

- which step failed
- the exact query
- whether the skill fired
- what `/doctor` said about the budget

Trigger failures and behaviour failures get fixed in different files, so establish which one you have first.
