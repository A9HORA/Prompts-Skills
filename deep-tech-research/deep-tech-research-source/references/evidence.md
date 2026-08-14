# Evidence

Why the method is shaped this way. Read this if the user asks for justification, or if you're considering changing the workflow and want to know what each piece is doing.

## The techniques

**Outline before prose (phase B).** Plan-and-Solve prompting (Wang et al., ACL 2023, arXiv:2305.04091) adds an explicit "devise a plan, then carry it out" step and reduced missing-step errors versus plain zero-shot chain-of-thought. Outlining first is the completeness analogue: it prevents the drift where early sections are deep and later ones collapse to one-liners.

**Section-by-section decomposition (the phased template).** Least-to-Most prompting (Zhou et al., ICLR 2023, arXiv:2205.10625) breaks a hard problem into ordered subproblems and generalises better than chain-of-thought — the paper reports SCAN success rising from 6% to 76% with text-davinci-002. Anthropic's prompt-engineering documentation recommends chaining complex tasks into subtasks for accuracy, naming research synthesis specifically.

**The verification pass (phase D2).** Chain-of-Verification (Dhuliawala et al., 2023, arXiv:2309.11495): draft, plan verification questions, answer them independently, revise. The paper reports decreased hallucination across tasks including longform generation. The independence requirement is load-bearing, which is why the protocol insists the verification question must not reveal the draft's answer.

**Adversarial re-read (phase D3).** Reflexion (Shinn et al., NeurIPS 2023, arXiv:2303.11366) showed verbal self-feedback improves performance without retraining — 91% pass@1 on HumanEval against a GPT-4 baseline of 80%.

**Running across multiple models and diffing.** Self-Consistency (Wang et al., 2022, arXiv:2203.11171) samples multiple reasoning paths and takes the consensus, improving GSM8K by 17.9 points. Running the same scope-and-outline prompt on two models and diffing is the practical form; a layer present in one and absent in the other is a coverage hole.

**Search first (rule 1).** Béchard & Marquez Ayala, "Reducing hallucination in structured outputs via Retrieval-Augmented Generation" (NAACL 2024 Industry Track, arXiv:2404.08189), cut hallucinated structured outputs from as high as 21% with fine-tuning alone to under 7.5% for steps and under 4.5% for tables once a retriever was added. Reduced, not eliminated.

**Abstention (rule 3).** Kadavath et al. (arXiv:2207.05221, "Language Models (Mostly) Know What They Know") found self-evaluation and calibration improve with scale. The corollary: the smaller the model, the less its confidence can be trusted, so the explicit "no penalty for `[?]`" instruction matters more on weak models. No benchmark measures the gain from this specific instruction; the reasoning is the standard precision/recall trade.

**Chunked output.** Retrieval accuracy degrades for material in the middle of a long context — "Lost in the Middle" (Liu et al., TACL 2024, arXiv:2307.03172). An argument for per-section turns over one enormous answer, independent of token limits.

## The checklist taxonomy

- **arc42** (arc42.org/overview): 12 sections — introduction and goals, constraints, context and scope, solution strategy, building block view, runtime view, deployment view, crosscutting concepts, decisions, quality requirements, risks and technical debt, glossary.
- **4+1 view model** (Kruchten, IEEE Software 1995; arXiv:2006.04975): logical, process, development, physical views plus scenarios.
- **C4 model** (Simon Brown, 2011): context / container / component / code abstraction levels.
- **ISO/IEC 25010** product quality model: functional suitability, performance efficiency, compatibility, usability, reliability, security, maintainability, portability; the 2023 revision adds a ninth characteristic.
- **RFC 7322** (RFC Style Guide) and **RFC 2119 / 8174** (normative keywords; 8174 clarifies they carry special meaning only when capitalised).
- **NIST SSDF, SP 800-218**: four practice groups — Prepare the Organization, Protect Software, Produce Well-Secured Software, Respond to Vulnerabilities.
- **Test262**, the official ECMAScript conformance suite: per the tc39/test262 README, as of May 2025 it comprised over 50,000 test files covering the majority of algorithms and grammar productions in the ECMA-414 suite. The model for demanding a real conformance-suite pointer.

## Why 100% accuracy is not on offer

**Hallucination rates are nonzero and vary by domain.** HALoGEN (Ravichander et al., ACL 2025, arXiv:2501.08292) evaluated roughly 150,000 generations from 14 models across 10,923 prompts in nine domains and found hallucination scores ranging from 4% to 86% depending on task for GPT-4. HaluEval (Li et al., EMNLP 2023, arXiv:2305.11747) found ChatGPT fabricated unverifiable information in about 19.5% of responses.

**Citations are unreliable even with search enabled.** The Columbia Journalism Review Tow Center study "AI Search Has a Citation Problem" (Jaźwińska & Chandrasekar, 6 March 2025) tested eight AI search engines over 1,600 queries and found they answered more than 60% incorrectly — roughly 37% for Perplexity, 67% for ChatGPT Search, 94% for Grok 3 — and did so with what the authors described as alarming confidence, rarely declining to answer. This is why rule 4 forbids inventing URLs and why users must be told to click them.

**Other hard limits.** Training cutoffs make recent releases and fresh CVEs invisible without retrieval. Output-token ceilings (roughly 64K mid-tier, up to 128K top-tier, far less on small models) mean exhaustive research on a large technology cannot fit one response. Non-determinism means two runs of the same prompt cover and omit different things.

**Numbers above are domain- and date-specific.** They come from particular 2023–2025 studies on particular models. They show error rates are nonzero and highly variable; they are not a prediction for any given model on any given technology.

**This method is untested as an assembly.** Each technique above has published evidence. There is no benchmark for this specific combination. Treat it as a grounded engineering design, not a proven artifact, and benchmark it if the stakes justify it.
