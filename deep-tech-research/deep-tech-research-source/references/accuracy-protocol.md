# Accuracy Protocol

The point of this protocol is not to make the model accurate — nothing does that. It is to make the model's uncertainty **visible**, so the reader knows which claims to check and which they can lean on.

Add numbered rules here when the user asks for a new sourcing or tagging behaviour. Log the change in `CHANGELOG.md`.

## 1. Tools first

Use search, fetch, or retrieval if available. Do not write from memory alone. The facts a build-grade dossier actually needs — version numbers, config defaults, byte offsets, API signatures, error codes, CVEs — are precisely the facts most likely to have drifted since training, and the ones where a plausible-sounding invention does the most damage.

No tools available? Say so at the top and label the whole document UNVERIFIED — NO TOOL ACCESS. Still produce it. A tagged draft is useful; an untagged one pretending to authority is not.

## 2. Every claim carries a tag

| Tag | Meaning | What it requires |
|---|---|---|
| `[V]` | Verified | Retrieved this session from a T1/T2 source. Give the quoted clause or field, the URL, the version, the date. |
| `[U]` | Unverified | From training memory; no source located. Say so plainly. |
| `[?]` | Unknown | Searched and found nothing. Say what was searched. |
| `[!]` | Conflict | Sources disagree. Show both, with tiers, and say which is more trustworthy and why. |
| `[F]` | Forward-looking | See rule 5. |

A dossier that is 60% `[V]` and 40% honestly `[?]` beats one that is 100% confident prose. Do not convert uncertainty into fluency — that is the failure this whole protocol exists to prevent.

## 3. Abstention is mandatory, not a fallback

When you don't know, write `[?]`. There is no penalty for it and it is the correct answer. There is a large penalty for a confident wrong byte offset, API signature, default value, version number, or CVE, because the reader will build on it.

Smaller and less capable models are worse at knowing what they don't know — calibration improves with scale — so this rule matters more, not less, the weaker the model running it.

## 4. Never fabricate a URL

If you cannot produce a URL you actually retrieved, write `[U]` and name the document instead. An invented citation is worse than no citation: it defeats the reader's ability to check you, which is the one thing the tags exist to enable. Fabricated citations are the most common failure mode of this kind of task — warn the user to click them.

## 5. Forward-looking rule, applied globally

Any statement about what will, may, or is planned to happen gets `[F]` plus a status — PROPOSED / IN PROGRESS / ANNOUNCED / SPECULATIVE — plus the source and that source's date.

This applies everywhere in the document, not only in the roadmap section. Never write a plan as a fact. Never write a proposal as shipped. If a feature's status is unclear, that is `[?]`, not `[V]`.

## 6. Prefer checkable claims over assertions

Where a claim could instead be a runnable check, say so: "verify by running X", "confirm against conformance test Y", "check clause Z of spec W". Mark these `CHECKABLE:` so the reader can convert them into tests.

Execution is ground truth. Prose is not. Every claim converted into a check is a claim that stops depending on the model being right.

## 7. Normative versus informative

Use RFC 2119 keywords in capitals — MUST, MUST NOT, SHOULD, MAY — only where the specification actually mandates the behaviour, and cite the clause. Per RFC 8174 these keywords carry their special meaning only when capitalised. Everything else is informative; mark it so.

This matters for anyone writing a conforming implementation: they need to know which requirements are binding and which are advice.

## 8. Version- and date-stamp every claim

Facts differ across versions. An unversioned claim about a moving technology is close to useless.

## 9. State the training cutoff

Say what it is, and flag every area likely to have changed since — recent releases, active proposals, fresh CVEs.

## Source tiers

Rank every source and say which tier it is. Never let a low tier override a high one without flagging the conflict explicitly.

- **T1** — formal specifications, standards (RFC / ISO / ECMA / W3C / IEEE), and primary source code
- **T2** — official vendor documentation
- **T3** — peer-reviewed papers
- **T4** — vendor engineering blogs
- **T5** — tutorials, StackOverflow, forum posts

## The verification pass

Applies to phase D2 of the workflow.

Take the 8–15 riskiest claims in the draft. Riskiest means: version numbers, config defaults, byte offsets and widths, API signatures, error codes, performance figures, CVEs, security behaviour.

For each one:

1. Restate it as a **standalone question that does not reveal or reference what the draft said.**
2. Answer that question fresh from sources, as though seeing it for the first time.
3. Compare to the draft. If they differ, the draft is wrong — correct it and log the correction.

Step 1 is the load-bearing part. Shown its own sentence and asked "is this right?", a model tends to agree with itself. Asking the bare question breaks that pull.

Worked example. The draft says Redis 7 defaults `maxmemory-policy` to `allkeys-lru`. The verification question is: "What is the default value of `maxmemory-policy` in Redis 7?" — asked cold. Looked up fresh, the real default is `noeviction`. The claim fails and gets corrected.

Note the limit: this only catches errors the model is capable of getting right when asked cold. If it doesn't know the fact at all, the check passes on a repeated wrong answer. That is why the strongest available model should run the audit, and why a weak model must never grade itself.
