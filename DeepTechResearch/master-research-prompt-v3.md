# Master Research Prompt — v3

Supersedes v1 and v2.

- v1 = wrapper document with evidence, accuracy limits, phased workflow, lite variant, worked example. 26-item checklist.
- v2 = bigger prompt (37 items, claim tags, test-surface layers, memory palace, token accounting) but the wrapper material was dropped.
- v3 = v2's prompt + everything v1 had around it + multi-model diffing.

Contents:
1. Master prompt
2. Lite variant (small/weak models)
3. Phased multi-prompt workflow (most reliable option)
4. Usage notes
5. Why each piece is in the prompt — with citations
6. Accuracy limits — with citations
7. Worked example: WebAssembly
8. Caveats

---

## 1. Master prompt

```
SOURCE REGISTRY (user-maintained — paste forward between sessions; add lines as
you collect sources; the model MUST use these and MUST tell you if it ignores one):
  T1 (specs / standards / primary source code):
    - [paste]
  T2 (official vendor docs):
    - [paste]
  T3 (peer-reviewed papers):
    - [paste]
  T4 (vendor engineering blogs):
    - [paste]
  T5 (tutorials / forums — lowest trust):
    - [paste]
  RULE: if I give you a source not in this registry, tell me its tier, tell me
  whether it conflicts with anything already here, and ASK whether to add it.

TECHNOLOGY: {TECHNOLOGY}
VERSION SCOPE: {VERSIONS — e.g. "Redis 7.x only" / "Wasm 3.0 core spec"}

ROLE: You are a senior systems engineer and technical writer producing a
reference-grade research dossier on {TECHNOLOGY}.

OBJECTIVE — the dossier must be complete enough to support ALL THREE of these,
without the engineer needing other sources first:
  CLASS A — tools built ON {TECHNOLOGY}: plugins, extensions, applications,
    integrations that consume it as a platform or runtime.
  CLASS B — tools built FOR {TECHNOLOGY}: parsers, compilers, linters,
    formatters, disassemblers, decompilers, converters, debuggers, profilers,
    static analyzers, migration and codemod tools that treat it as their subject.
  CLASS C — tools that TEST {TECHNOLOGY}: conformance runners, fuzzers,
    property-based test harnesses, differential testers, load/soak/stress rigs,
    chaos and fault-injection harnesses, compatibility-matrix runners — exercising
    it under varied inputs, versions, platforms, and failure conditions.
For each major section, note which class(es) it serves.

=====================================================================
ACCURACY PROTOCOL — this is the core of the task. Follow it literally.
=====================================================================
1. TOOLS FIRST. If you have search/browsing/retrieval, USE IT. Do not answer
   from memory alone. No tools? Say so at the top and label the entire document
   "UNVERIFIED — NO TOOL ACCESS."

2. EVERY CLAIM CARRIES A TAG. No exceptions:
     [V]  VERIFIED   — retrieved this session from a T1/T2 source. Give the
                       quoted clause or field, the URL, the version, the date.
     [U]  UNVERIFIED — from your training memory; no source located. Say so.
     [?]  UNKNOWN    — you searched and found nothing. Say what you searched.
     [!]  CONFLICT   — sources disagree. Show BOTH, with tiers, and say which
                       you'd trust and why.
     [F]  FORWARD-LOOKING — see rule 5.
   A dossier where 60% is [V] and 40% is honestly [?] is FAR more useful than
   one that is 100% confident prose. Do not convert uncertainty into fluency.

3. ABSTENTION IS MANDATORY, NOT OPTIONAL. When you do not know, write [?]
   UNKNOWN. Guessing is the single worst failure mode available to you here. You
   will not be penalised for [?]. You WILL be penalised for a confident wrong
   byte offset, API signature, default value, version number, or CVE.

4. NEVER FABRICATE A URL. If you cannot produce a URL you actually retrieved,
   write [U] and name the document instead. An invented citation is worse than
   no citation, because it defeats the human's ability to check you.

5. FORWARD-LOOKING RULE (global — not just the roadmap section): any statement
   about what will, may, or is planned to happen gets tag [F] plus a status of
   PROPOSED / IN PROGRESS / ANNOUNCED / SPECULATIVE, plus the source and its
   date. Never write a plan as a fact. Never write a proposal as shipped. If a
   feature's status is unclear, that is [?], not [V].

6. PREFER CHECKABLE CLAIMS OVER ASSERTIONS. Wherever a claim could instead be a
   runnable check, say so: "verify by running X", "confirm against conformance
   test Y", "check clause Z of spec W". Execution is ground truth; your prose is
   not. Mark these "CHECKABLE:" so the human can convert them into tests.

7. NORMATIVE vs INFORMATIVE. Use RFC 2119 keywords in caps (MUST / MUST NOT /
   SHOULD / MAY) ONLY where the spec actually mandates it, and cite the clause.
   Everything else is informative — mark it so.

8. VERSION- AND DATE-STAMP every claim. Facts differ across versions.

9. STATE YOUR TRAINING CUTOFF and flag every area likely to have changed since.

=====================================================================
METHOD — run these phases in order and SHOW each one.
=====================================================================
PHASE A — SCOPE
  Define {TECHNOLOGY} in 3 sentences. List versions/editions and the current
  stable one. Name the governing body. List the primary sources you will use,
  tiered, cross-checked against the SOURCE REGISTRY above. Flag registry gaps.

PHASE B — OUTLINE
  Hierarchical outline covering EVERY item in the COVERAGE CHECKLIST. For each
  node: mark source availability SOLID / THIN / MISSING, name the engineering
  artifacts it should yield, and note which build class (A/B/C) it serves.
  No prose yet.

PHASE C — EXPAND
  Write each section in depth, with tags on every claim and the artifacts
  attached. Depth over breadth.

PHASE D — SELF-AUDIT (write this out; do not do it silently)
  D1. COVERAGE SWEEP. Re-read the checklist. List every layer you covered only
      shallowly or skipped. Fill those gaps now.
  D2. CHAIN-OF-VERIFICATION. Extract the 8–15 riskiest factual claims — version
      numbers, default values, byte offsets and widths, API signatures, error
      codes, performance numbers, CVEs, security behaviour. For each:
        (a) write it as a STANDALONE question that does not reveal or reference
            what your draft said;
        (b) answer that question fresh from sources, as if seeing it for the
            first time;
        (c) compare to the draft. If they differ, the DRAFT is wrong — correct
            it and log the correction.
      The isolation in (a) is the whole point: shown your own sentence, you will
      tend to agree with yourself. Ask the bare question instead.
  D3. ADVERSARIAL READ. "What would a maintainer of {TECHNOLOGY} say is wrong or
      missing here?" Answer honestly and fix it.
  D4. TAG AUDIT. Any claim still untagged? Tag it. Anything tagged [V] whose
      source you cannot now restate with URL and clause? Demote it to [U].

PHASE E — CLAIM LEDGER
  A table of EVERY substantive claim in the dossier:
    ID | claim (one line) | tag [V/U/?/!/F] | source + URL | tier | version | date
  This is the completeness guarantee. Nothing in the prose may be absent here.

PHASE F — MEMORY PALACE
  Build a navigable memory structure over the whole dossier.
    - Each ROOM = one coverage layer (architecture, wire format, security, ...).
    - Each room holds 3–7 OBJECTS = the load-bearing facts, as concrete vivid
      images, not abstractions.
    - Each object CITES its Claim Ledger IDs.
    - Give a fixed WALKING ORDER through the rooms, and a one-line "what this
      room is for" per room.
  HONEST NOTE, state it in the output: a memory palace is a compression device —
  it works by stripping detail down to hooks, so it CANNOT itself hold every
  detail. It is the index. The Claim Ledger (Phase E) is what guarantees nothing
  was lost. Every object points back into the ledger for full detail.

PHASE G — CLOSING SECTIONS (all required)
  - Unknown / Unverified / Conflicting: every [U], [?], [!] gathered in one place.
  - Coverage self-assessment: rate each checklist layer DEEP / ADEQUATE / THIN /
    MISSING, with the reason.
  - How to verify this dossier: the exact primary sources and commands a human
    should run, ordered by risk.
  - Correction log: every claim D2 caught and fixed.

PHASE H — TOKEN ACCOUNTING
  Report per phase: an ESTIMATED token count, labelled "ESTIMATE — not measured."
  Then a total. Then state plainly: you cannot count your own tokens, because the
  tokenizer is not visible to you during generation; the authoritative numbers are
  usage.input_tokens / usage.output_tokens in the API response, or the usage panel
  in the platform UI. Never present an estimate as a measurement.

=====================================================================
COVERAGE CHECKLIST — every item must appear. "N/A" only with a reason.
=====================================================================
FOUNDATIONS
 1. History and motivation: what it replaced, design goals, rejected alternatives.
 2. Governance: who steers it, how changes are proposed and ratified.
 3. Formal specifications and standards: exact document names, numbers, URLs.
 4. Versions, changelog, current stable, support and EOL status.
 5. Theory and mathematical foundations.
 6. Core concepts and terminology — glossary in plain language.

INTERNALS
 7. Architecture: components and how they compose (context / container /
    runtime / deployment views).
 8. Internal data structures and algorithms.
 9. Memory model and concurrency model: ordering, safety, synchronisation.
10. Wire protocols and file/binary formats — byte level: offsets, widths,
    endianness, framing, encoding, versioning of the format itself.
11. Execution/evaluation model: lifecycle from input to result.

BUILD SURFACE
12. Public APIs and SDKs: signatures, types, error contracts, stability guarantees.
13. Extension and plugin points; ABI/API stability contract around them.
14. Configuration surface: every meaningful knob, its default, its effect.
15. Installation, toolchain, build systems.
16. Interoperability and standards compliance.

TEST AND VERIFICATION SURFACE  (Class C — do not skimp here)
17. Official conformance/test suites: name, URL, what they cover, how to run them.
18. Input-space taxonomy: valid inputs, invalid inputs, boundary values,
    adversarial and malformed inputs, encoding edge cases.
19. Test oracles: how do you know an output is CORRECT? Reference implementation
    diffing, invariants, round-trip properties, golden files, formal semantics.
20. Invariants and pre/post-conditions an implementation MUST hold — written so
    they can become property-based tests.
21. Fuzzing surface: entry points, grammars or seed corpora, known crash classes,
    existing fuzzers (OSS-Fuzz etc.).
22. Environment and compatibility matrix: OS, arch, runtime versions, dependency
    versions, and where behaviour legitimately differs across them.
23. Determinism and reproducibility: what is guaranteed identical across runs and
    platforms, and what is explicitly not (float, iteration order, timing).
24. Fault injection and chaos: what can fail (network, disk, memory, clock,
    dependency), the injection points, and expected degradation behaviour.
25. Resource limits and behaviour at the limit: memory, connections, file size,
    recursion depth, timeouts — and what happens on exceeding each.
26. Observability: logs, metrics, traces, debug hooks available to a test harness.
27. Performance characteristics and BENCHMARKING METHODOLOGY: how to measure
    correctly, warm-up, what to hold constant, common measurement mistakes. Cite
    any absolute numbers with hardware, version, and workload context.
28. Scalability limits and the shape of degradation.

RISK AND CONTEXT
29. Security model, threat model, trust boundaries, and known CVEs with IDs and
    advisory links.
30. Failure modes, edge cases, known gotchas and footguns.
31. Licensing and legal/IP.
32. Ecosystem: libraries, competing and alternative implementations, tooling.
33. Deployment and operations.
34. Migration, versioning, deprecation policy.
35. Community and support channels.
36. Roadmap — every item tagged [F] with status per rule 5.
37. Learning resources: best primary docs, books, courses.

=====================================================================
ENGINEERING ARTIFACTS — extract wherever they exist. These are what make the
dossier build-grade rather than merely readable.
=====================================================================
 - Formal grammar (EBNF/ABNF) for any language or text format.
 - State machines / diagrams for any protocol or lifecycle.
 - Byte-level format tables: offset, width, type, endianness, meaning.
 - Concrete API signatures with parameter types, return types, error codes.
 - Extension points plus their stability contract.
 - Invariants, pre/post-conditions — phrased as testable properties.
 - Test oracle definitions and reference-implementation pointers.
 - Conformance suite name + URL + coverage summary.
 - Fuzzing grammar or seed corpus description, and known crash classes.
 - Environment matrix as an actual table.
 - Fault-injection point list.
 - Minimal WORKING code examples, labelled with language and version, for: the
   most common operation, one Class B operation (parse/inspect it), and one
   Class C operation (test it).

=====================================================================
CHUNKING PROTOCOL
=====================================================================
Depth over brevity. If the dossier will exceed your output limit, DO NOT
truncate silently. Output PHASE A + PHASE B first. Then sections in numbered
batches. End each message with "CONTINUE? Next: sections X–Y" — or, if told to
proceed autonomously, continue until done, repeating headers so each chunk stands
alone. Never drop a citation or a tag to save space. Phases E, F, G, H come last
and are never skipped.

Begin with PHASE A now for {TECHNOLOGY}.
```

---

## 2. Lite variant — for small or weak models, or short output limits

Use this instead of the master prompt when the model is small, has no search, or caps output at a few thousand tokens. Run it once per topic cluster, not once for everything.

```
You are a senior engineer writing a build-grade reference on {TECHNOLOGY},
version {VERSIONS}.

Use web search if you have it. Tag EVERY claim:
  [V] verified from a spec or official doc — give the URL
  [U] from memory, no source found
  [?] you looked and don't know
Never invent a URL. If you don't know, write [?]. Guessing is the worst outcome.
Any statement about future plans gets [F] + PROPOSED/ANNOUNCED/SPECULATIVE.

Cover ALL of these with real depth ("N/A" only with a reason):
1) what it is + why it exists; 2) governing body + spec names/URLs;
3) versions + current stable; 4) core concepts glossary; 5) architecture and
internals; 6) wire/file format at byte level; 7) key API signatures + error
contracts + stability guarantees; 8) memory/concurrency model; 9) config surface
with defaults; 10) install/build/toolchain; 11) official conformance suite
(name + URL) + how to run it; 12) input-space taxonomy: valid, invalid,
boundary, malformed inputs; 13) test oracles — how do you know output is right?;
14) invariants an implementation MUST hold; 15) environment/compatibility matrix;
16) failure modes + fault injection points; 17) resource limits + behaviour at
the limit; 18) performance + how to benchmark it correctly; 19) security model +
known CVEs with IDs; 20) licensing; 21) ecosystem + alternative implementations;
22) migration/deprecation policy; 23) roadmap [F].

Include where they exist: a formal grammar (EBNF/ABNF), a protocol state machine,
byte-format tables, extension points, and 3 minimal WORKING code examples
labelled with version — one that USES it, one that PARSES/inspects it, one that
TESTS it.

Then: list anything you covered shallowly and fill it. Re-check your 8 riskiest
claims against sources. End with an "Unknown/Unverified/Conflicts" list.
If this won't fit in one answer, output the outline first and ask which section
to expand.
```

---

## 3. Phased multi-prompt workflow — the most reliable option

Use this when the technology is large, or the model is weak, or accuracy matters more than speed. Splitting the work across turns beats one giant prompt because each subtask gets the model's full attention.

**Prompt 1 — scope and outline**

```
Act as a senior systems engineer scoping a build-grade research dossier on
{TECHNOLOGY}, version {VERSIONS}. Do NOT write the dossier yet.

Deliver:
(a) a 3-sentence definition;
(b) versions/editions and the current stable version;
(c) the governing body and the exact primary specs/repos (names + URLs), tiered
    T1 (spec/source) to T5 (forum);
(d) a hierarchical OUTLINE covering all of these layers:
    [paste the 37-item COVERAGE CHECKLIST from the master prompt]

For each outline node: mark source availability SOLID / THIN / MISSING; name the
engineering artifacts that section should yield (grammar, state machine, byte
format, API signatures, oracles, conformance suite, fuzz surface, env matrix);
and note which build class it serves — A (built ON it), B (built FOR it),
C (tests it).

Use search if available. Tag claims [V]/[U]/[?]. Never invent a URL.
```

**Prompt 2..N — expand one section (or one small batch) per turn**

```
Using the outline and sources from before, write section {N}: {SECTION NAME}
for {TECHNOLOGY} in full depth.

Requirements:
- Tag every claim [V]/[U]/[?]/[!]/[F]. [V] needs the URL, version, and date.
- Never invent a URL. Unsure = [U] or [?].
- RFC 2119 keywords (MUST/SHOULD/MAY) only for real spec requirements — cite the
  clause.
- Include this section's engineering artifacts: grammar / state machine /
  byte-format table / API signatures + error contracts / invariants as testable
  properties / oracles / extension points / minimal WORKING code labelled with
  version.
- Mark "CHECKABLE:" on anything the human could verify by running something.

End with two lines: what in THIS section is still thin, and what is unverified.
```

**Final prompt — gap audit and verification**

```
Here is the assembled dossier on {TECHNOLOGY}: [paste]

Audit it rigorously, in writing:

1) COVERAGE. Rate each of the 37 checklist layers DEEP / ADEQUATE / THIN /
   MISSING. List every THIN/MISSING item and fill it now, with sources.

2) VERIFICATION (chain-of-verification). Extract the 15 riskiest factual claims
   — versions, defaults, byte offsets, API signatures, error codes, perf numbers,
   CVEs, security behaviour. For each: write it as a standalone question that
   does NOT reveal what the dossier said; answer it fresh from sources; compare.
   Where they differ, the dossier is wrong — correct it and log the correction.

3) CITATION CHECK. For every [V] claim, restate the URL and the specific clause.
   Any you cannot restate gets demoted to [U].

4) CONFLICTS. Every place sources disagreed, with tiers.

5) Produce: the Claim Ledger, the "Unknown/Unverified/Conflicting" section, the
   "How to verify this dossier" list, and the correction log.

Return the corrected dossier plus all audit outputs.
```

Run Prompt 1 on two different models and diff the outlines. A layer that appears in one and not the other is a coverage hole in the weaker one.

---

## 4. Usage notes

**Pin the version.** "Research gRPC" is a much worse prompt than "gRPC core + grpc-go, current stable, C-core wire protocol." Narrow scope buys depth and accuracy.

**Enable search.** Without retrieval every tag should collapse to `[U]` or `[?]`, and what you have is a draft to verify, not a reference.

**Keep the source registry in your own file** and paste it forward each session. Model memory does not persist between conversations unless you have a memory feature enabled; the registry is the only part of this that survives because you own it.

**Chunk against output limits.** Frontier models cap a single response at roughly 64K tokens on mid-tier and up to 128K on top-tier, per vendor docs. Small local models often cap at 4K–8K. An exhaustive dossier on a large technology exceeds all of these — use the phased workflow or the chunking protocol. Stream long outputs (above roughly 16K tokens) to avoid request timeouts.

**Watch for long-context rot.** Retrieval accuracy degrades for material sitting in the middle of a long context (Liu et al., "Lost in the Middle," TACL 2024, arXiv:2307.03172). Another argument for per-section turns over one enormous answer.

**Diff across models.** Run the same prompt on two or three models and compare. Disagreements localise the errors for you cheaply. This is self-consistency applied across models rather than across samples.

**Never let a weak model grade itself.** Run the verification pass on the strongest model you have access to, or by hand.

**Click the URLs.** Fabricated citations are the dominant failure mode. A `[V]` tag is a claim about a source, not proof of one.

**Budget.** A large technology realistically takes 1 outline turn + 8–20 expansion turns + 1–2 audit turns. Tens of thousands of output tokens total. This is a session, not a single question.

**Where the model will go thin:** layers 17–28, the test and verification surface. Push back and make it expand them — that is the part that separates a dossier you can build tools from and one you can only read.

---

## 5. Why each piece is in the prompt — citations

Each design choice comes from published work rather than invention.

**Outline before prose (Phase B).** Plan-and-Solve prompting (Wang et al., ACL 2023, arXiv:2305.04091) adds an explicit "devise a plan, then carry it out" step and reduced missing-step errors versus plain zero-shot chain-of-thought. Forcing an outline first is the completeness analogue.

**Section-by-section decomposition (phased workflow).** Least-to-Most prompting (Zhou et al., Google, ICLR 2023, arXiv:2205.10625) breaks a hard problem into ordered subproblems and generalises better than chain-of-thought — the paper reports SCAN success rising from 6% to 76% with text-davinci-002. Anthropic's own prompt-engineering docs recommend chaining complex tasks into subtasks for accuracy, naming research synthesis as a target use case (docs.claude.com).

**The self-audit pass (Phase D2).** Chain-of-Verification (Dhuliawala et al., 2023, arXiv:2309.11495): draft, plan verification questions, answer them independently, revise. The paper reports it decreases hallucinations across tasks including longform generation. The independence requirement is load-bearing — that is why the prompt insists the verification question must not reveal the draft's answer.

**Adversarial re-read (Phase D3).** Reflexion (Shinn et al., NeurIPS 2023, arXiv:2303.11366) showed verbal self-feedback improves performance without retraining — 91% pass@1 on HumanEval versus a GPT-4 baseline of 80%.

**Multi-model diffing.** Self-Consistency (Wang et al., 2022, arXiv:2203.11171) samples multiple reasoning paths and takes the consensus, improving GSM8K by 17.9 points. Running the prompt on several models and diffing is the practical form.

**Search-first (rule 1).** Retrieval measurably cuts hallucination. Béchard & Marquez Ayala, "Reducing hallucination in structured outputs via Retrieval-Augmented Generation" (NAACL 2024 Industry Track, arXiv:2404.08189), cut hallucinated structured outputs from as high as 21% with fine-tuning alone to under 7.5% for steps and under 4.5% for tables once a retriever was added. Note: reduced, not eliminated.

**Abstention (rule 3).** Larger models are better calibrated about their own uncertainty; Kadavath et al. (arXiv:2207.05221) found self-evaluation and calibration improve with scale. The corollary is that the smaller the model, the less you can trust its confidence — hence the explicit instruction that `[?]` carries no penalty. I have no benchmark measuring the accuracy gain from this specific instruction; the reasoning is the standard precision/recall trade.

**Coverage taxonomy sources** — the 37 items are drawn from real frameworks, not invented:

- **arc42** (Starke & Hruschka, arc42.org/overview): 12 sections — introduction and goals, constraints, context and scope, solution strategy, building block view, runtime view, deployment view, crosscutting concepts, decisions, quality requirements, risks and technical debt, glossary. Maps to items 1, 6, 7, 33.
- **4+1 view model** (Kruchten, IEEE Software 1995; arXiv:2006.04975): logical, process, development, physical views plus scenarios. Maps to items 7–9, 33.
- **C4 model** (Simon Brown, 2011): context / container / component / code abstraction levels. Maps to item 7.
- **ISO/IEC 25010** product quality model: functional suitability, performance efficiency, compatibility, usability, reliability, security, maintainability, portability (the 2023 revision adds a ninth characteristic). Maps to items 16, 22, 27–29, 34.
- **RFC 7322** (RFC Style Guide) and **RFC 2119/8174** (normative keywords; RFC 8174 clarifies they carry special meaning only when in all capitals). Source of rule 7.
- **NIST SSDF, SP 800-218**: four practice groups — Prepare the Organization, Protect Software, Produce Well-Secured Software, Respond to Vulnerabilities. Maps to item 29.
- **Test262**, the official ECMAScript conformance suite: per the tc39/test262 README, as of May 2025 it comprised over 50,000 individual test files covering the majority of algorithms and grammar productions in the ECMA-414 suite. This is the model for item 17 — demanding a pointer to the real conformance suite is what makes a dossier build-grade rather than merely descriptive.

---

## 6. Accuracy limits — why "100% accuracy" is not achievable

No prompt delivers 100% accuracy from any current model. The evidence:

**Hallucination rates are nonzero and vary enormously by domain.** HALoGEN (Ravichander et al., ACL 2025, arXiv:2501.08292) evaluated roughly 150,000 generations from 14 models across 10,923 prompts in nine domains, and found hallucination scores ranging from 4% to 86% depending on the task for GPT-4. HaluEval (Li et al., EMNLP 2023, arXiv:2305.11747) found ChatGPT fabricated unverifiable information in about 19.5% of responses. No prompt drives these to zero.

**Citations specifically are unreliable, even with search enabled.** The Columbia Journalism Review Tow Center study "AI Search Has a Citation Problem" (Jaźwińska & Chandrasekar, March 6, 2025) tested eight AI search engines over 1,600 queries and found they answered more than 60% of queries incorrectly — Perplexity about 37%, ChatGPT Search about 67%, Grok 3 about 94% — and did so with what the authors called alarming confidence, rarely declining to answer. This is why the prompt forbids inventing URLs and why you must click them.

**Training cutoffs.** Anything newer than the cutoff is invisible unless retrieved live. New spec versions and fresh CVEs are exactly the facts most likely to be stale.

**Output-token ceilings.** Roughly 64K tokens mid-tier, up to 128K top-tier, far less on small models. Exhaustive research on a large technology cannot fit in one response.

**Non-determinism.** At temperature above zero the same prompt yields different output. Two runs cover and omit different things.

**Mitigations — all six, applied together:**

1. Enable search/RAG so claims are grounded in retrieved text rather than memory (21% → under 7.5% in the NAACL 2024 study above — reduced, not eliminated).
2. Require inline citations with URL, version, and access date; then verify each against the primary source yourself.
3. Force the explicit chain-of-verification pass (Phase D2), with the draft hidden from the verification question.
4. Run the same prompt on two or three models and diff the outputs.
5. Keep the mandatory "Unknown / Unverified / Conflicting" section so gaps stay visible instead of being smoothed into prose.
6. Treat the output as a first-draft dossier a human must check against T1 sources — never as final truth.

The honest framing: this prompt does not make the model accurate. It makes the model's uncertainty **legible**, so you know where to spend your own verification effort. The `[V]` set can approach high accuracy because each item is traceable. Nothing goes missing because gaps appear as `[?]` rows rather than vanishing.

---

## 7. Worked example: WebAssembly

Master prompt with `{TECHNOLOGY}` = WebAssembly, `{VERSIONS}` = core spec, current. This is what PHASE A and PHASE B should look like. PHASE C then expands each node.

**PHASE A — SCOPE (illustrative expected output)**

- *Definition:* WebAssembly is a portable binary instruction format for a stack-based virtual machine, designed as a compilation target for languages like C, C++, and Rust so they run at near-native speed in browsers and other hosts. `[V]` — W3C Core Specification.
- *Versions:* Wasm shipped as 1.0 (the MVP), then 2.0. Version 3.0 was announced as the live standard on 17 September 2025 per webassembly.org, adding a 64-bit address space, garbage collection, and exception handling. `[V]` if retrieved this session — **and this is exactly the class of fact a model gets wrong from memory**, so it must be re-fetched, not recalled.
- *Governance:* W3C WebAssembly Working Group plus Community Group. `[V]`
- *Primary sources (T1):* W3C WebAssembly Core Specification; the reference interpreter repository; the official spec test suite. The model must fetch exact URLs live rather than reciting them.
- *Training cutoff:* stated, with a flag that proposal statuses move fast and any roadmap claim needs re-checking.

**PHASE B — OUTLINE (illustrative, abbreviated, with artifacts and build class)**

| Layer | Source | Artifact to extract | Class |
|---|---|---|---|
| History/motivation — replaced asm.js; goals speed, safety, portability | SOLID | — | — |
| Specs — Core Spec, JS API, Web API, WASI | SOLID | exact doc names + URLs | A B C |
| Theory — stack machine, structured control flow, full formal small-step semantics (unusual: Wasm has a complete formal spec) | SOLID | **typing rules; formal grammar of binary + text format (WAT)** | B |
| Architecture — modules, functions, tables, memories, globals; validate → compile → instantiate → execute | SOLID | **lifecycle state machine** | A B |
| Binary format | SOLID | **byte tables per section.** Magic number `0x00 0x61 0x73 0x6D`, then a version field, then ID-tagged sections | B |
| Memory/concurrency — linear memory, bounds checking, threads proposal, shared memory, atomics | SOLID | memory layout; atomic ordering notes | A C |
| APIs — JS API: `WebAssembly.instantiate`, `Module`, `Instance`, `Memory`, `Table`; WASI calls | SOLID | **signatures + trap/error contracts** | A |
| Toolchain — LLVM, Emscripten, wasm-pack, wat2wasm/wasm2wat (WABT) | SOLID | commands | A B C |
| Conformance | SOLID | **official spec test suite name + URL + how to run** | C |
| Input space | THIN | valid/invalid/malformed module taxonomy; validation failure classes | C |
| Oracles | THIN | **reference interpreter diffing; round-trip wat2wasm→wasm2wat property** | C |
| Fuzzing | SOLID | entry point = module bytes; existing fuzzers; known crash classes | C |
| Determinism | SOLID | what is deterministic vs float NaN bit patterns, host-dependent behaviour | C |
| Security | SOLID | sandbox model, CFI, capability-based host access; CVEs in specific runtimes (Wasmtime, V8) with IDs | A C |
| Alt implementations | SOLID | V8, SpiderMonkey, JavaScriptCore, Wasmtime, Wasmer, WAMR — differential testing targets | B C |
| Gotchas | MIXED | traps, float edge cases, memory growth limits | A |
| Versioning | SOLID | proposal phases 0–4 | — |
| Roadmap | — | component model, GC/EH refinements — all `[F]` with proposal status | — |

Then PHASE C expands each row, PHASE D audits, PHASE E–H produce ledger, palace, closing sections, token estimate. Because a full Wasm dossier exceeds one response, the chunking protocol applies.

*Verification note on the above:* the magic number and section-based layout are stable, well-known facts about the format, but confirm against the W3C Core Spec before writing a parser. The 3.0 release date and feature list should be re-fetched — do not trust any model's memory for a version fact.

---

## 8. Caveats

**The combined prompt is untested.** Each technique inside it has published evidence, cited in section 5. I have **no source** measuring this specific assembly's completeness or accuracy on any model. It is a grounded engineering design, not a proven artifact. Benchmark it yourself if the stakes justify it.

**The 37-item checklist is a synthesis.** It draws on arc42, 4+1, C4, ISO/IEC 25010, RFC document structure, NIST SSDF, Test262's conformance model, plus additions from this conversation. No single published standard contains exactly these items in this order. The mapping in section 5 lets you check the derivation.

**Hallucination figures are domain- and date-specific.** The 4–86%, 19.5%, and 37–94% numbers come from particular 2023–2025 studies on particular models and tasks. They show error rates are nonzero and highly variable. They are not a predicted rate for your model on your technology.

**Model capability numbers move fast.** The 64K/128K output figures reflect vendor documentation as of mid-2026 and will change. Check your model's current limits.

**Commercial deep-research agents' internal prompts are not public.** Public descriptions of how OpenAI Deep Research, Gemini Deep Research, and Perplexity decompose tasks come from vendor blogs and third-party analysis, not from their actual system prompts.

**Token estimates in Phase H are estimates.** A model cannot count its own tokens; the tokenizer is not visible to it during generation. Authoritative numbers live in the API usage fields or your platform's usage panel.
