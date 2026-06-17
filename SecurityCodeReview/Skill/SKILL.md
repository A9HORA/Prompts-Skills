---
name: security-review-prompt
description: >
  Universal 80-category source code security review prompt (v3.3). Generates a
  comprehensive security assessment report for any repository — backend, frontend,
  mobile, AI/LLM, scripts, CI/CD, infrastructure, desktop/native, and git history.
  Produces a structured Markdown report with findings sorted by severity, CVSS scoring,
  CWE/OWASP references, execution flows, and remediation priority batching.

  Use this skill whenever the user asks to: "security review this repo", "scan this
  codebase for vulnerabilities", "do a security audit", "run a security assessment",
  "find vulnerabilities", "check for security issues", "pentest this code", "review
  this service for security", "check for hardcoded secrets", "scan git history for
  secrets", "check for leaked credentials", or any variant of security review,
  vulnerability assessment, threat modeling, or secure code review. Also trigger when
  the user says "use the security review prompt", "run the 80-category scan", "use
  v3.3", or references security categories by number (e.g. "check category 9 and 16").
  Trigger even for partial requests like "check auth on this endpoint" or "is this
  code vulnerable to SSRF" — the prompt covers these as individual categories within
  the full framework.
---

# Universal Source Code Security Review Prompt — v3.3

This skill performs a systematic, 80-category security assessment of a software
repository and produces a detailed Markdown report.

## How this skill works

The full review methodology is in `references/review-prompt.md` (808 lines). **Read
it before starting any review.** It contains all 80 category definitions, platform
detection rules, chain escalation rules, quality bar, deliverable structure, and
report template.

The reference file is the single source of truth. Do not improvise category
definitions or report structure — follow the reference exactly.

---

## Quick Start Workflow

### Step 1: Read the full prompt

```
view references/review-prompt.md
```

Read the entire file. It contains:
- Preamble — platform detection rules
- Service context — optional business context table
- 80 vulnerability categories organized by module
- Quality bar and chain escalation rules
- Confidence and CVSS guidance
- Full report template with required fields
- Exclusion rules

### Step 2: Confirm input

The repository must be available as:
- **Local path**: `/path/to/repository`
- **GitHub URL**: `https://github.com/org/repo` (clone it first)

If the user provides a service context (service name, business function, data
sensitivity, auth mechanism), record it for severity calibration. If not provided,
infer from code and note assumptions in the report header.

### Step 3: Platform detection

Read manifest files to determine which platform modules to activate:
- **Base categories (1–37)** — always active
- **Git History (77–80)** — always active
- **AI/LLM (38–47)** — if AI SDK dependencies found
- **Mobile (48–55)** — if mobile framework detected
- **Web SSR (56–62)** — if SSR framework detected
- **Web SPA (59–62)** — if SPA framework detected
- **Scripts/CI/Infrastructure (63–70)** — if Dockerfiles, CI configs, IaC found
- **Desktop/Native (71–76)** — if Electron, Tauri, etc. detected

Multiple modules can activate simultaneously.

### Step 4: Run gitleaks (if available)

First check if gitleaks is installed:

```bash
which gitleaks && gitleaks version
```

**If gitleaks is installed:**

```bash
# Current working tree
gitleaks detect --source . --no-git --report-format json --report-path gitleaks-current.json

# Full git history
gitleaks detect --source . --report-format json --report-path gitleaks-history.json
```

Process output per the Git History module instructions in the reference file.

**If gitleaks is NOT installed:**

Skip the automated gitleaks scan. Fall back to manual git history scanning only
(the `git grep` and `git log -p -S` commands in categories 77–78 of the reference
file). Note in the report header:

```
| Gitleaks version | Not installed — manual git history scan only |
| Gitleaks findings (raw) | N/A |
| Gitleaks findings (validated) | N/A |
```

Add a recommendation in the report's Positive Controls / Remediation section:

> **Install gitleaks** (`brew install gitleaks` / `apt install gitleaks`) for
> automated secret pattern matching across git history. Manual scanning covers
> common patterns but may miss provider-specific formats that gitleaks detects.

Categories 77–80 remain active — they degrade to manual-only, not skipped.

### Step 5: Scan all activated categories

Use grep/ripgrep across the entire repository. Do not sample. Every claim must
cite `file:line`. Findings without citations are invalid.

For git history findings, citations must include commit SHA: `commit_sha:file:line`.

### Step 6: Apply chain escalation rules

Check all 13 escalation rules (defined in the reference file). When two findings
combine to form a more dangerous chain, escalate severity.

### Step 7: Generate the report

Save to: `{REPO_NAME}-security-assessment-report-{yyyy-mm-dd}.md`

Report structure (all sections required):
1. Report header (with platform modules, service context, gitleaks stats)
2. How to read Scope/Location/Execution flow
3. Findings summary table (sorted: Critical → High → Medium, then by confidence)
4. Individual findings (same order as summary table)
5. Categories reviewed with no qualifying findings
6. Positive controls observed
7. Remediation priority (immediate / urgent / short-term / planned)
8. Footer

### Per-finding required fields

Every finding must include:
- Severity (Critical / High / Medium)
- Confidence (high / medium / low)
- CVSS 3.1 Base (full vector or one-line justification)
- Scope (three-tier table or single path)
- Location (file:line or commit:file:line)
- Execution flow (entry to sink, each step cited)
- Issue details (mechanism + preconditions)
- Implicit assumption violated (when applicable)
- Steps to reproduce (curl commands, git commands for secrets)
- Affected code (with secret redaction: first 8 + ... + last 4)
- Exposure timeline (required for categories 77–78)
- Blast radius (required for secret findings)
- Exploit dependency
- Business risk (only if code handles payments/PII/auth/partner data)
- Recommended fix (concrete code change, not generic advice)
- CWE / OWASP (primary CWE ID + OWASP Top 10 2021 mapping)

---

## Key Rules (quick reference — full details in references/review-prompt.md)

**Quality bar:**
- Report all Critical and High
- Report Medium only if exploitable from public entrypoint
- Git History exception: report Medium for missing prevention controls (cat 80)
- Skip Low and Info

**Severity sorting:**
- Findings summary table: Critical first, then High, then Medium
- Within same severity: high confidence before medium before low
- Report body follows the same order

**Secret redaction:**
- Never print full secrets in the report
- Show first 8 chars + `...` + last 4 chars
- Short secrets (< 16 chars): first 4 + `...` + last 2

**Exclusions:**
- Vendored deps, generated code, build output
- Test files excluded for categories 1–76 (but read as evidence)
- Test files NOT excluded for categories 77–80 (secrets in tests are real)

**Immediate escalation:**
- If category 77 finding is a production cloud IAM key or payment processor live key,
  prepend ⚠️ IMMEDIATE ACTION REQUIRED section before the findings summary
