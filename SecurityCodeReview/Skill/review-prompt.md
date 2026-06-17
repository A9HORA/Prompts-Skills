# Universal source code security review prompt
 
> **Version:** 3.3
> **Categories:** 80 (37 base + 39 platform-specific + 4 git history)
> **Scope:** Backend, frontend, mobile, AI/LLM, scripts, CI/CD, infrastructure, desktop/native, **git history**
> **Last updated:** 2026-06-17
> **Changelog v3.3:** Added optional Service Context section for business-function-aware severity assessment. Added CWE/OWASP references as a required per-finding field. Findings summary table and report body now sorted by severity descending (Critical → High → Medium), then by confidence descending within same severity.
> **Changelog v3.2:** Added Git History module (categories 77–80, always applied). Expanded category 12 with redaction rules, encoding-aware scanning, and secret format patterns. Added gitleaks integration. Updated version header, quality bar, chain escalation rules, exclusions, confidence definitions, report header, and deliverable structure to cover git history findings.
 
---
 
## Preamble — platform detection
 
Before scanning, detect the project type from manifest files (`package.json`, `build.gradle`, `Podfile`, `Cargo.toml`, `go.mod`, `requirements.txt`, `pyproject.toml`, `setup.py`, `setup.cfg`, `Pipfile`, `pom.xml`, `build.sbt`, `Gemfile`, `Package.swift`, `pubspec.yaml`, `*.csproj`, `*.sln`), directory structure, and code patterns. Apply **Base categories (1–37)** to every project. Apply **Git History categories (77–80)** to every project — these require no detection. Then apply the relevant **platform module(s)**:
 
- **AI/LLM integration detected** — dependency on `openai`, `anthropic`, `langchain`, `llama-index`, `transformers`, `autogen`, `crewai`, `semantic-kernel`, `google-generativeai`, `cohere`, `replicate`, or similar AI SDK; OR code making direct HTTP calls to LLM provider APIs (`api.openai.com`, `api.anthropic.com`, etc.); OR prompt template files (`.prompt`, `.jinja2` with LLM-shaped messages): also apply **categories 38–47**
- **Mobile** — React Native, Flutter, Android (Kotlin/Java), iOS (Swift/ObjC); OR presence of `AndroidManifest.xml`, `Info.plist`, `build.gradle` with `com.android.*`, `*.xcodeproj`, `pubspec.yaml` with `flutter`: also apply **categories 48–55**
- **Web frontend with SSR** — Next.js, Nuxt, Remix, SvelteKit, Astro, or any project with server-rendered HTML templates (EJS, Pug, Handlebars, Jinja2 files serving user-facing pages): also apply **categories 56–62**
- **Web frontend SPA-only** — React, Vue, Angular, Svelte without SSR: also apply **categories 59–62**
- **Scripts / CLI / infrastructure** — Dockerfile, docker-compose, Terraform/Pulumi, Helm/K8s manifests, CI configs, shell/python/ruby scripts; OR presence of `k8s/`, `helm/`, `charts/`, `manifests/`, `.github/workflows/`, `serverless.yml`, `template.yaml` (SAM): also apply **categories 63–70**
- **Desktop / native application** — Electron, Tauri, Qt, GTK, WPF, WinForms, SwiftUI (macOS), or any native binary that runs with local user privileges; OR presence of `electron-builder.yml`, `tauri.conf.json`, `*.wxs` (WiX installer), native IPC/named-pipe code: also apply **categories 71–76**
Multiple modules can apply simultaneously (e.g. a Next.js app with OpenAI integration applies Base + Git History + Web SSR + AI/LLM).
 
If the project type is ambiguous, activate the broader set of modules and note the uncertainty in the report header. It is better to check an irrelevant category (and report "no findings") than to miss an active attack surface.
 
State which platform modules were activated and why in the report header.

---

## Service context (optional — fill before scanning)

If provided, this context adjusts severity assessment and prioritization. If not provided, the reviewer infers from code and notes assumptions in the report header.

| Field | Value |
|-------|-------|
| Service name | {name} |
| Business function | {what it does in 1-2 sentences} |
| Data sensitivity | {PCI, PII, financial, auth tokens, partner credentials, none} |
| Auth mechanism | {JWT via Okta, session cookies, API gateway, mTLS, none/unknown} |
| Deployment target | {GKE, ECS, Lambda, Vercel, on-prem, unknown} |
| Priority categories | {category numbers most relevant — e.g. "9, 10, 16, 23 for a payment service"} |

Business function context changes severity: a missing auth check on a card deletion endpoint is Critical (PCI scope); the same gap on a public healthcheck is informational.
 
---
 
## Instructions
 
Perform a source code and configuration security review of this repository. Cover only the categories listed below that are activated by the platform detection above. **Git History categories (77–80) are always activated** — they do not require platform detection.
 
### How to read category descriptions
 
Each category below describes a **vulnerability pattern** — the dangerous behavior and why it matters. Specific function names, libraries, and framework APIs are listed as *illustrative examples, not an exhaustive checklist*. The reviewer must:
 
1. **Search for the pattern, not just the named functions.** If a category says "`lodash.merge` with user-controlled keys," the actual vulnerability is *any deep/recursive merge of untrusted input into an object* — including custom utility functions, newer libraries, or native APIs that achieve the same effect.
2. **Adapt to the project's language and framework.** If the examples are JavaScript but the repo is Go, find the Go equivalent of the same dangerous pattern. The concept transfers even when the API name doesn't.
3. **Flag novel sinks.** If you find a dangerous pattern not listed in any category but clearly exploitable, report it under the closest matching category and note it as an unlisted variant.
The per-language examples (JS, Python, Go, Java, Ruby, Rust, C#) included in some categories are starting points. The absence of a language-specific example does not mean the pattern is irrelevant for that language.
 
---
 
## Base categories (1–37) — always apply
 
### Input handling
 
**1. Injection — SQL, command, NoSQL, template, LDAP, code/eval**
SQL queries built with string concatenation or template literals instead of parameterized queries. Command execution with user input:
- **JS/TS**: `child_process.exec()` with template literals, `eval()`, `new Function()`, `vm.runInContext()`
- **Python**: `subprocess.run(shell=True)` with f-strings, `os.system()`, `eval()`, `exec()`
- **Go**: `os/exec.Command` with unsanitized args, `fmt.Sprintf` into `database/sql` instead of `?` placeholders
- **Java/Kotlin**: `Runtime.exec()` with string concat, `Statement.executeQuery()` with `+` instead of `PreparedStatement`
- **Ruby**: backtick execution, `system()`, `Kernel.exec()` with interpolation
- **Rust**: `std::process::Command` with user-controlled args, `format!()` into SQL strings
- **C#**: `Process.Start()` with user input, `SqlCommand` with string concat instead of `SqlParameter`
NoSQL operator injection (`$gt`, `$ne` in MongoDB queries from user input). Template injection in Jinja2, Pug, EJS, Handlebars, Twig when user input reaches template compilation (not just variable rendering).
 
**2. SSRF — outbound HTTP with user-controlled URL**
Any outbound HTTP/HTTPS request where the URL, hostname, or path segment comes from user input — regardless of which HTTP client library is used. The pattern: attacker controls where the server sends a request. Include: cloud metadata endpoint access (`169.254.169.254`, `fd00::`, `[::ffff:169.254.169.254]`), DNS rebinding bypasses of private-IP filters, redirect-following that lands on internal networks, and TOCTOU between DNS resolution and connection.
 
**3. Path traversal — file system ops with user input**
Any file system operation (read, write, delete, stat, list) where the file path or any path component derives from request input. The pattern: user controls part of a path that reaches a file system API without canonicalization and confinement to an expected directory. Check for `../` normalization bypass, null byte injection, URL-encoded traversal (`%2e%2e%2f`), double-encoding, and symlink following. Applies to all languages and their respective file APIs.
 
**4. Open redirect**
Redirect targets (`Location` header, `res.redirect()`, `window.location.assign()`, `router.push()`, meta refresh) sourced from query params, headers (Referer, Host, X-Forwarded-Host), cookies, or request body without validation against a parsed-hostname allowlist. Flag: string prefix/suffix matching on URLs (e.g. `startsWith('https://example.com')` matching `https://example.com.evil.tld`), regex without anchors, substring checks.
 
**5. Insecure deserialization**
`JSON.parse` on untrusted input followed by prototype-accessing operations. `pickle.loads()`, `yaml.load()` (without SafeLoader), `ObjectInputStream.readObject()`, `Marshal.load()`, `unserialize()` on user-controlled data. `node-serialize`, `serialize-javascript` with user input.
 
**6. URL construction from untrusted input**
String concatenation to build URLs (`${base}/${userInput}`, `url + '?param=' + value`) instead of `URL`/`URLSearchParams` builders. Allows: parameter injection (`&admin=true`), path traversal on URL, scheme manipulation (`javascript:`, `data:`). Check both server-side upstream calls and client-rendered `href`/`src`/`action` attributes.
 
### Authentication and authorization
 
**7. Authentication — missing auth, JWT issues, weak session handling**
Routes or endpoints without authentication middleware. JWT: missing `algorithms` allowlist in `verify()`, `alg: none` acceptance, symmetric secrets in code, missing `exp`/`iss`/`aud` validation, token in URL query string. Session: predictable session IDs, missing regeneration after login, session fixation via URL parameter.
 
**8. OAuth / OIDC implementation flaws**
Missing or unvalidated `state` parameter (CSRF on auth callback). `redirect_uri` validation bypasses (open redirect on OAuth callback, path traversal, subdomain matching). Authorization code replay (codes accepted more than once). Missing PKCE (`code_verifier`/`code_challenge`) on public clients (SPAs, mobile). Token exchange endpoint accepting arbitrary `audience`/`scope`. `id_token` validated without `nonce`, `iss`, or `aud` check. Implicit grant used when authorization code + PKCE is available.
 
**9. Authorization (IDOR) — endpoints not checking resource ownership**
URL path parameters or query parameters (`userId`, `orderId`, `customerId`, `accountId`, `paymentMethodId`) forwarded to data stores without checking the authenticated principal owns that resource. Include: sequential/guessable IDs, bulk operations without ownership filter.
 
**10. Business-logic trust boundaries**
Request body, header, cookie, or query fields that affect price, discount, currency, quantity, ownership, status, role, or permissions being trusted from client input without server-side validation backed by a signed/verified source (server-side session, signed basket, HMAC'd payload). Flag: payment amounts forwarded from request body, `skipValidation` flags in query strings, role/status fields accepted from client.
 
**11. Trust decisions from client-controlled signals**
Authentication, authorization, role, or identity state derived from HTTP headers (`Referer`, `Origin`, `Host`, `X-Forwarded-*`, `User-Agent`, custom `X-Internal`/`X-Admin`), cookies, query params, or request body without verification by signed token (JWT with verified issuer/aud, HMAC, mTLS at trusted proxy). Specifically:
- `signedIn`/`isAuthenticated`/`isAdmin`/`role`/`userId` set from `req.headers`, `req.cookies`, or `req.query`
- Allowlists implemented as regex against raw Referer/Origin with unescaped dots, missing anchors, or substring matching instead of parsed hostname comparison
- Middleware ordering where a weak gate sets auth state and a stronger gate only overwrites on success
- Tests that assert the insecure behavior as expected
### Data protection
 
**12. Secrets — hardcoded keys, passwords, signing keys in code or config**
API keys, passwords, tokens, signing secrets, database connection strings in source files, config files (environment JSON/YAML, `appsettings.json`, `.env` committed to repo), or CI/CD configs. Include: base64-encoded credentials in headers, default passwords that are never rotated, secrets in Dockerfiles or docker-compose.yml. Check common config locations: `config/`, `.github/workflows/`, `Jenkinsfile`, `Dockerfile`, `docker-compose*.yml`, `terraform.tfvars`, `.env*`, and any project-specific bootstrap config (e.g. `settings.json`, `local.json`, environment config files referenced in startup scripts).

Also check for secrets in **encoded forms** that bypass plaintext grep:
- Base64-encoded strings near credential-named variables (decode and verify)
- Hex-encoded keys or tokens
- URL-encoded passwords in connection strings (`postgres://user:p%40ssw0rd@host`)
- Multi-line PEM blocks (`-----BEGIN * PRIVATE KEY-----`)
- JWTs with real claims in source (`eyJ...` — decode payload to check for non-test data)

**Secret format patterns to scan for** (in addition to variable-name heuristics):

| Provider / Type | Pattern |
|----------------|---------|
| AWS Access Key ID | `AKIA[0-9A-Z]{16}` |
| GCP Service Account | `"type": "service_account"` in JSON files |
| GCP API Key | `AIza[0-9A-Za-z\-_]{35}` |
| GitHub PAT (classic) | `ghp_[0-9a-zA-Z]{36}` |
| GitHub PAT (fine-grained) | `github_pat_[0-9a-zA-Z_]{82}` |
| GitLab PAT | `glpat-[0-9a-zA-Z\-_]{20,}` |
| Slack token | `xox[bpras]-[0-9a-zA-Z-]{10,}` |
| Stripe live key | `sk_live_[0-9a-zA-Z]{24,}` |
| OpenAI key | `sk-[0-9a-zA-Z]{48}` or `sk-proj-[0-9a-zA-Z\-_]{48,}` |
| Anthropic key | `sk-ant-[0-9a-zA-Z\-_]{40,}` |
| SendGrid | `SG\.[0-9a-zA-Z\-_]{22}\.[0-9a-zA-Z\-_]{43}` |
| npm token | `npm_[0-9a-zA-Z]{36}` |
| PyPI token | `pypi-[0-9a-zA-Z\-_]{50,}` |
| Generic private key | `-----BEGIN (RSA\|EC\|DSA\|OPENSSH\|PGP)? ?PRIVATE KEY-----` |
| Generic connection string | `(mongodb\|postgres\|mysql\|redis\|amqp\|mssql)://[^:]+:[^@]+@` |

These patterns supplement — not replace — contextual analysis. A pattern match without credential context is **low confidence**.

**Placeholder/example exclusions:** Do not flag values that are clearly fake: `YOUR_API_KEY_HERE`, `changeme`, `xxx`, `TODO`, `REPLACE_ME`, `sk-test-xxxx`, `pk_test_*` (Stripe test keys are public by design), all-zero keys, `example`, `dummy`, `fake`, `placeholder`. If ambiguous, report as **medium confidence** and note the uncertainty.

**Redaction rule:** When including secret values in the report under "Affected code," **never print the full secret**. Show first 8 characters + `...` + last 4 characters. For short secrets (< 16 chars): first 4 + `...` + last 2. Example: `AKIA1234...5678`, `ghp_abc1...wxyz`.

**Dedup rule with category 63:** If a secret appears in a CI/CD config file, report it under **category 12** (secrets). Cross-reference category 63 in the finding, but do not create a duplicate finding under 63 for the same secret. Category 63 covers CI/CD-specific non-secret issues (build arg patterns, env structure). Category 12 owns all hardcoded credential findings regardless of location.
 
**13. Sensitive data in client-side state**
API keys, internal service URLs, PII, auth tokens, or partner credentials serialized into Redux/Vuex/Pinia/Zustand state, SSR payloads (`window.__STATE__`), `localStorage`, `sessionStorage`, or client-readable cookies (missing `httpOnly`). Any secret readable via `document.cookie` or browser DevTools.
 
**14. Cookie security flags**
Cookies carrying auth tokens, session IDs, API credentials, or PII set without `httpOnly`, `Secure`, or `SameSite`. Cookies with `SameSite: None` without `Secure`. Overly broad `Domain` or `Path` values. Credentials in cookies that should be server-only.
 
**15. Verbose errors / sensitive data in logs or responses**
Stack traces, internal file paths, database queries, or connection strings returned in HTTP responses. PII, tokens, full credit card numbers, or secrets written to logs. Error objects forwarded to clients without sanitization (`res.json(error)`).
 
**16. PCI scope indicators**
Code that handles raw PAN (Primary Account Number), CVV/CVC, track data, or magnetic stripe data outside a PCI-certified tokenization boundary. Flag: `cardNumber`, `fullCreditCard`, `cvv`, `cvc`, `trackData` fields accepted in request body and forwarded to non-PCI-certified endpoints. Credit card numbers logged, stored in session/state, or passed to third-party APIs without tokenization. This is a compliance-critical finding even if no direct exploit exists — PCI scope expansion triggers audit and breach-notification obligations.
 
### Network and transport
 
**17. Tainted-input forwarding**
Public input (query params, headers, body fields) passed to internal services, message queues, partner APIs, or cache keys without validation or sanitization. Includes: header forwarding (`Authorization`, custom headers) to unintended downstream services, user input in cache key construction.
 
**18. CORS misconfiguration**
Dynamic `Access-Control-Allow-Origin` from `Origin` header without allowlist validation. `Access-Control-Allow-Credentials: true` with wildcard or reflected origin. `Access-Control-Allow-Origin: *` on authenticated endpoints.
 
**19. Permissive TLS / infra config**
Any code or configuration that disables TLS certificate verification on outbound connections — the pattern is "trust any certificate presented by the remote server." Examples by ecosystem: Node.js `rejectUnauthorized: false` or `NODE_TLS_REJECT_UNAUTHORIZED=0`, Python `verify=False`, Go `InsecureSkipVerify: true`, PHP `CURLOPT_SSL_VERIFYPEER => false`, Java `TrustAllCerts` implementations, .NET `ServerCertificateCustomValidationCallback` returning `true`. Also: public cloud storage buckets (S3, GCS, Azure Blob) without access restrictions, overly permissive security groups or firewall rules, and IAM policies with `*` resource/action in IaC files.
 
**20. Proxy trust misconfiguration**
Application configured to trust forwarded headers (`X-Forwarded-Host`, `X-Forwarded-For`, `X-Forwarded-Proto`) from any upstream without restricting to known proxy IPs/CIDRs. The pattern: client-derived hostname, IP, or protocol used for security decisions because the framework believes a trusted proxy set them. Examples: Express `trust proxy` set to `true` (trusts all), ASP.NET `ForwardedHeadersOptions` without `KnownProxies`, Nginx `set_real_ip_from 0.0.0.0/0`, Django `SECURE_PROXY_SSL_HEADER` without matching reverse-proxy config. This is a force multiplier — it enables open redirect, SSRF, and host-header injection through downstream findings.
 
**21. Subdomain / host validation flaws**
String prefix, suffix, or contains checks on hostnames instead of parsed `URL` hostname comparison. `endsWith('.example.com')` matching `evil-example.com`. `startsWith('https://example.com')` matching `https://example.com.evil.tld`. `includes('example.com')` matching `notexample.com`. Must use `new URL(x).hostname` and exact or suffix match against `.` boundary.
 
### Abuse and resilience
 
**22. Rate limiting and abuse controls**
Endpoints performing expensive, sensitive, or abusable operations without throttling — the pattern is "unauthenticated or low-cost repeated invocation with no cap." Check: authentication flows (login, register, password reset, OTP/MFA verify), AI/LLM completion endpoints, search, PDF/report generation, email/SMS send, payment initiation, file upload. Look for the *absence* of rate-limiting middleware, API gateway throttle config, or per-IP/per-user caps on these routes. The specific middleware varies by framework — what matters is whether any mechanism exists, not which one.
 
**23. Race conditions / TOCTOU**
Check-then-act patterns on financial state, inventory, quotas, coupons, or one-time tokens. Flag even if the exploit path is unclear. Include: read-modify-write without locking, double-spend on payment callbacks, concurrent redemption of single-use codes.
 
**24. Webhook / callback verification**
Incoming HTTP requests from third parties (payment processors, partner systems, CI/CD, messaging platforms) accepted without verifying authenticity. The pattern: the server trusts the request body/headers solely because they arrived at a known endpoint URL, without HMAC/signature verification, replay protection (timestamp + nonce), or sender IP/origin validation. The specific verification mechanism varies by provider — what matters is whether *any* authenticity check exists before the payload influences state.
 
### Code quality and dependencies
 
**25. Mass assignment — request body fields auto-bound to models**
User-controlled request body fields automatically mapped to internal model fields without an explicit allowlist:
- **JS/TS**: `Object.assign(model, req.body)`, spread `{...req.body}` into DB models, Mongoose `new Model(req.body)`, Sequelize `Model.create(req.body)`
- **Python**: Django `ModelForm` without explicit `fields` (or with `fields = '__all__'`), `Model.objects.create(**request.data)`, SQLAlchemy `Model(**request.json)`
- **Java/Kotlin**: Spring `@ModelAttribute` or `@RequestBody` binding to entity with no `@JsonIgnoreProperties`, Jackson `ObjectMapper.updateValue()` from user input
- **Ruby**: Rails `params.permit` missing or overly broad (`permit!`)
- **Go**: `json.Unmarshal(body, &model)` where model has exported fields like `IsAdmin`, `Role`, `Balance`
- **C#**: ASP.NET model binding without `[Bind(Include=...)]` or `[BindNever]` on sensitive properties
Allows setting `isAdmin`, `role`, `price`, `balance` from request body.
 
**26. Prototype pollution (JavaScript/Node.js only)**
Any recursive or deep merge operation where user-controlled input supplies object keys — enabling prototype chain pollution via `__proto__`, `constructor.prototype`, or similar. The vulnerability is the *pattern* (untrusted keys reaching a property-setting operation that walks the prototype chain), not any specific library. Common sinks include `lodash.merge`, `deepmerge`, `defu`, `Object.assign` with nested spread, or custom recursive merge utilities. Check: `req.body` or `req.query` reaching any deep/recursive property-setting operation without key sanitization or `Object.create(null)` as the target.
 
**27. Dependency CVEs**
Flag only if a known CVE is identifiable directly from lockfiles (`package-lock.json`, `go.sum`, `requirements.txt`, `pom.xml`, `Gemfile.lock`, `Cargo.lock`, `yarn.lock`, `pnpm-lock.yaml`). Include the advisory ID (GHSA/CVE) and affected version. Do not guess based on package names or version ranges alone.
 
**28. Supply chain: typosquat, dependency confusion, install scripts, unpinned actions**
Dependency-level risks that don't show up as CVEs but enable code execution during install or build. The patterns:
- **Typosquatting**: package names one character off from popular packages (check against known-popular names in the ecosystem).
- **Dependency confusion**: private/internal package names that lack a scope or namespace and could be claimed on the public registry.
- **Install scripts**: lifecycle hooks in package manifests (`preinstall`/`postinstall` in `package.json`, `setup.py` with `cmdclass`, `build.rs` in Cargo) that execute arbitrary code at install time.
- **Unpinned CI actions/modules**: CI/CD steps or IaC modules referencing mutable tags (`@main`, `@latest`) instead of immutable SHAs or digests.
**29. Cryptographic implementation flaws**
Weak hashes for passwords (MD5, SHA1, unsalted). Insecure modes (ECB). Hardcoded IVs/nonces. Nonce reuse in AES-GCM/ChaCha20. Non-CSPRNG sources for tokens, session IDs, or keys:
- **JS/TS**: `Math.random()` for secrets; `===` instead of `crypto.timingSafeEqual()` for token comparison
- **Python**: `random.random()` / `random.randint()` instead of `secrets` module; `hashlib.md5()` for passwords instead of `bcrypt`/`argon2`
- **Go**: `math/rand` instead of `crypto/rand`; `subtle.ConstantTimeCompare()` missing for secret comparison
- **Java/Kotlin**: `java.util.Random` instead of `SecureRandom`; `MessageDigest.isEqual()` (not constant-time in older JVMs) instead of `SecretKeySpec` + `Mac`
- **Ruby**: `rand()` instead of `SecureRandom`; `Digest::MD5` for passwords
- **Rust**: `rand::thread_rng()` is CSPRNG (OK), but check for `rand::rngs::SmallRng` or custom seeds for security-sensitive values
- **C#**: `System.Random` instead of `RandomNumberGenerator`; `SHA1.ComputeHash()` for passwords
### Observability and debug
 
**30. Debug/admin endpoints exposed in production**
Routes with `debug`, `admin`, `test`, `internal`, `healthz` (with sensitive data), `phpinfo`, `swagger` (if auth-gated in dev but not prod). Feature flags or env checks that can be bypassed (`?debug=true`, `X-Debug: 1`).
 
**31. Audit trail / security logging gaps**
Auth failures, privilege changes, financial transactions, admin actions, and data export operations not being logged. Logs missing user ID, IP, timestamp, or action context. Logging that is easily bypassable (e.g. logging only in middleware that can be skipped).
 
### Security headers and policies
 
**32. CSP effectiveness**
Check if `Content-Security-Policy` header exists. Flag: `unsafe-inline` in `script-src` (negates XSS protection), `unsafe-eval` in `script-src`, `*` or `data:` in `script-src`/`object-src`, missing `frame-ancestors` (clickjacking), `default-src` too permissive. Note: a weak CSP is a severity multiplier for every injection finding — escalate co-occurring injection findings by one level when CSP is ineffective.
 
**33. Clickjacking / frame protection**
Missing both `X-Frame-Options` and `frame-ancestors` CSP directive on pages with sensitive actions (payment, account settings, permission grants, data deletion). Flag if frameable by any origin.
 
### Server-side template and rendering
 
**34. SSR hydration / serialization XSS**
`JSON.stringify()` interpolated into inline `<script>` tags without escaping `</script>`, `<`, `<!--`, `U+2028`, `U+2029`. Covers: `window.__STATE__`, `window.__PRELOADED__`, `__NEXT_DATA__`, bootstrap globals, preloaded configs. `JSON.stringify` alone does NOT escape `<` or `/`. Every inline JSON payload needs a `</` escape pass or must be placed in `<script type="application/json">` and parsed client-side.
 
**35. HTML attribute injection in server-rendered templates**
String interpolation into HTML attributes (`href`, `src`, `style`, `on*` handlers, `data-*`) without context-aware escaping:
- **JS/TS**: Template literals in `.ts`/`.js` building HTML strings; EJS `<%- %>`, Pug `!{}`, Handlebars `{{{ }}}`
- **Python**: Jinja2 `{{ var | safe }}` or `Markup()`, Django `{{ var }}` inside `href`/`on*` attributes (auto-escaping doesn't prevent `javascript:` in href), Flask `render_template_string()` with user input
- **Go**: `text/template` used instead of `html/template` for web output (no auto-escaping); or `html/template` with user input in `href`/`srcset`/`style` contexts (Go's html/template does NOT escape URL or CSS contexts)
- **Ruby**: ERB `<%= raw var %>` or `html_safe` in attribute context
- **C#**: Razor `@Html.Raw()` in attribute values
Single-quote or double-quote breakout in attribute values. `javascript:` scheme in `href`/`src` attributes rendered from user input.
 
**36. SSTI in side channels**
User input reaching template engines used for emails, PDFs, invoices, notifications, or report generation (not just HTML rendering). Check: Handlebars/Mustache/Jinja2/Pug `compile()` or `render()` where the template string (not just variables) includes user input.
 
### API-specific
 
**37. GraphQL-specific security**
Introspection enabled in production (`introspection: true` or not explicitly disabled — default is enabled in most frameworks). No query depth limit (`depthLimit`) or complexity limit (`costAnalysis`). Batching enabled without per-batch rate limiting (allows sending N mutations in one request to bypass per-request rate limits). Alias-based brute force (N aliased `login` queries in one request). Field-level authorization missing (resolvers return data without checking caller's role/ownership). Disable introspection: `introspection: process.env.NODE_ENV !== 'production'` is not sufficient if env var can be unset.
 
---
 
## Platform module: AI / LLM (categories 38–47)
 
Apply when `openai`, `anthropic`, `@anthropic-ai/sdk`, `langchain`, `llama-index`, `llamaindex`, `transformers`, `autogen`, `crewai`, `semantic-kernel`, `google-generativeai`, `@google/generative-ai`, `cohere`, `replicate`, or similar AI SDK is found in dependencies or imports.
 
**38. Prompt injection (direct and indirect)**
User input concatenated into LLM prompts via string interpolation, template literals, or f-strings without structural delimiters, input sanitization, or instruction hierarchy. Include: system prompt overrides via user message, injection via retrieved documents (indirect prompt injection in RAG), few-shot example manipulation. Check for: `messages.push({role: 'user', content: userInput})` where `userInput` could contain `role: 'system'` overrides in multi-turn concatenation, or raw document content inserted into prompts without `[DOCUMENT START]`/`[DOCUMENT END]` delimiters.
 
**39. Uncontrolled tool / function calling**
LLM decides which tools to invoke and with what arguments based on user input, without: tool allowlists per user role, argument schema validation before execution, confirmation gates for destructive actions (delete, send, pay, modify), output sanitization from tool results before re-injection into context. Flag: `tools: [...]` passed to completion API where tool list is static but includes destructive operations callable by any user.
 
**40. Token / cost exhaustion**
Missing per-user, per-session, or per-request token limits. No `max_tokens` cap on completion requests. Unbounded prompt/context size accepting user input. Agent/chain loops without depth or iteration limits. No budget controls per API key. Missing abort/timeout on streaming completions.
 
**41. Model output trust**
LLM output used in security-sensitive sinks without sanitization: rendered as HTML (`innerHTML`, `dangerouslySetInnerHTML`, template `{{{ }}}`), used in SQL queries, passed to `eval()`, used as file paths, forwarded to APIs as parameters, used in redirect URLs. LLM output must be treated as untrusted input in every sink.
 
**42. LLM structured output used for control flow without schema validation**
LLM returning JSON (via `response_format: { type: "json_object" }`, function calling, or `tool_choice`) where the parsed output drives: routing decisions, database writes, access control checks, file operations, API calls, or state transitions — without schema validation (`zod`, `ajv`, JSON Schema) between the LLM response and the consuming code. Flag: `JSON.parse(llmResponse)` followed by `if (parsed.action === 'delete')` without validating `parsed` against an expected schema with allowed values.
 
**43. RAG data poisoning / access control**
Vector store queries executed without per-user access control filtering. Retrieved documents may contain content the querying user shouldn't see. Adversarial documents in corpus designed to hijack retrieval results. Missing metadata filtering on vector search (`filter: { userId: currentUser }`). Embedding endpoints exposed without auth.
 
**44. Multi-agent trust boundaries**
When multiple agents communicate (CrewAI, AutoGen, LangGraph, custom orchestration): one compromised agent (via prompt injection on its input) can instruct others to take destructive actions. Flag: agent output from one agent used as system/user message for another without sanitization or permission scoping. Missing per-agent tool restrictions (Agent A can call `delete_user` because Agent B's tools are shared). No output validation between agent handoffs. Supervisor/orchestrator agent trusting sub-agent outputs for routing decisions.
 
**45. System prompt / context leakage**
System prompts containing: API keys, internal URLs, database connection strings, partner agreements, business logic rules, PII, pricing algorithms. Extractable via prompt injection, conversation export, or debug endpoints. Check: hardcoded secrets in system message strings, env vars interpolated into prompts.
 
**46. PII in AI logging pipeline**
User prompts, completions, conversation history, or tool-call arguments logged without PII redaction. Data sent to third-party observability tools (Langfuse, LangSmith, Helicone, Datadog) without scrubbing. Conversations stored for fine-tuning without consent or anonymization. Check: logging middleware around LLM client calls, `callbacks` parameter in LangChain.
 
**47. Embedding endpoint abuse**
Embedding computation endpoints (`/embed`, `/embeddings`) exposed without authentication or rate limiting — allows cost exhaustion by external callers. Adversarial inputs crafted to produce colliding embeddings that poison similarity search results. User-facing embedding endpoints that return raw vectors (enables corpus reconstruction/inversion attacks on private data).
 
---
 
## Platform module: Mobile (categories 48–55)
 
Apply when the project is a React Native, Flutter, Android (Kotlin/Java), or iOS (Swift/Objective-C) application.
 
**48. Insecure local storage**
Tokens, PII, credentials, or secrets stored in: Android `SharedPreferences` / `getSharedPreferences()`, iOS `UserDefaults` / `NSUserDefaults`, React Native `AsyncStorage`, Flutter `shared_preferences`, SQLite databases without encryption (`SQLCipher`). Check: Keychain/Keystore misuse (wrong `kSecAttrAccessible` values, missing biometric binding, `ACCESSIBLE_AFTER_FIRST_UNLOCK` for sensitive data).
 
**49. Certificate pinning absence**
No SSL/TLS pinning on API calls to backend services. Check: missing `TrustManager` implementation (Android), `network_security_config.xml` without `<pin-set>`, missing `ATS` pin configuration (iOS), no pinning plugin in Flutter/React Native (`ssl_pinning_plugin`, `react-native-ssl-pinning`). Flag: `TrustManager` that accepts all certificates, `@SuppressLint("TrustAllX509TrustManager")`.
 
**50. Exported components / deep link hijacking**
Android: exported `Activity`/`Service`/`BroadcastReceiver`/`ContentProvider` in `AndroidManifest.xml` without `android:permission` guard (default export when `<intent-filter>` is present). iOS: custom URL scheme handlers (`application(_:open:options:)`) without source app validation. Universal links / App Links without proper `apple-app-site-association` / `assetlinks.json` verification. Deep link parameters used in navigation or API calls without sanitization.
 
**51. WebView security**
JavaScript enabled (`setJavaScriptEnabled(true)` / `javaScriptEnabled = true`) in WebViews loading untrusted or user-controlled URLs. `addJavascriptInterface` on Android (all API levels — verify usage). `file://` access enabled (`setAllowFileAccess`, `setAllowFileAccessFromFileURLs`). Missing URL allowlist in `shouldOverrideUrlLoading` (Android) / `decidePolicyFor` (iOS). `evaluateJavascript()` with tainted strings.
 
**52. Biometric authentication bypass**
`BiometricPrompt` (Android) / `LAContext` (iOS) where the biometric check result is evaluated client-side only and not bound to a server-side challenge-response (cryptographic operation with Keystore/Keychain-bound key). Attacker on rooted/jailbroken device patches the boolean return value. Flag: `biometricPrompt.authenticate()` callback that simply sets `isAuthenticated = true` without using `CryptoObject` (Android) or `evaluateAccessControl` with `.biometryCurrentSet` (iOS) to gate a key operation.
 
**53. Third-party SDK data collection without consent**
SDKs that auto-collect device IDs, location, advertising identifiers, contacts, or usage analytics without explicit user consent flow in the code. Check for: Facebook SDK (`AppEventsLogger`), Firebase Analytics, Adjust, AppsFlyer, Braze, Amplitude, Segment initialized before consent screen. `ATTrackingManager.requestTrackingAuthorization` (iOS) / `AdvertisingIdClient` (Android) usage without gating. Google Play and App Store privacy manifests (`PrivacyInfo.xcprivacy`, data safety form) absent or incomplete relative to SDK behavior.
 
**54. Binary protections**
`android:debuggable="true"` in release `AndroidManifest.xml`. Missing ProGuard/R8 obfuscation (`minifyEnabled false` in release `build.gradle`). No root/jailbreak detection in payment, auth, or key-management flows. Sensitive data in app screenshots (missing `FLAG_SECURE` on Android, hidden content in `applicationWillResignActive` on iOS).
 
**55. IPC / intent spoofing**
Trusting data from `Intent` extras, `Bundle` arguments, `BroadcastReceiver` data, or `ContentProvider` query URIs without validating sender identity. Implicit broadcasts leaking sensitive data. `PendingIntent` with `FLAG_MUTABLE` and empty base intent (hijackable). Clipboard (`ClipboardManager`/`UIPasteboard`) exposure of tokens, passwords, or PII.
 
---
 
## Platform module: Web frontend (categories 56–62)
 
Apply when the project includes React, Vue, Angular, Svelte, Next.js, Nuxt, Remix, SvelteKit, Astro, or any server-rendered HTML.
 
**56. SSR hydration / serialization XSS** (alias of Base 34 — enforce here if SSR detected)
Duplicate enforcement. If Base 34 was already checked, confirm coverage of framework-specific patterns: Next.js `__NEXT_DATA__`, Nuxt `__NUXT__`, Remix `loader` data, SvelteKit `data` prop serialization.
 
**57. HTML attribute injection** (alias of Base 35 — enforce here with framework-specific sinks)
Framework-specific: React `dangerouslySetInnerHTML`, Vue `v-html`, Angular `[innerHTML]` binding, Svelte `{@html}`. JSX `href={userInput}` without scheme validation (allows `javascript:`). `<Link href={...}>` / `<a href={...}>` with unvalidated URLs.
 
**58. DOM sink analysis**
Client-side JavaScript using dangerous sinks with user-derived or URL-derived data: `innerHTML`, `outerHTML`, `document.write()`, `document.writeln()`, `eval()`, `setTimeout(string)`, `setInterval(string)`, `new Function(string)`, `jQuery.html()`, `jQuery.append()` with HTML strings, `Element.insertAdjacentHTML()`. Sources: `location.hash`, `location.search`, `location.href`, `document.referrer`, `window.name`, `postMessage` data, URL params via `URLSearchParams` or framework router.
 
**59. PostMessage validation**
`window.addEventListener('message')` handlers without `event.origin` check or with insufficient origin validation (substring check, missing protocol). `postMessage()` calls with `targetOrigin: '*'`. Data received via `postMessage` used in DOM sinks, API calls, or navigation without sanitization.
 
**60. Service Worker poisoning / persistence**
Service Worker (`sw.js`, `service-worker.js`) that: caches pages containing auth tokens or PII, intercepts API calls and can modify responses, uses `importScripts()` from CDN without SRI, has overly broad `scope` (e.g. `/`), or persists after user logout (no `registration.unregister()` on sign-out). A compromised or malicious Service Worker is a persistent XSS that survives navigation, cookie clearing, and page reloads.
 
**61. Subresource integrity (SRI)**
Third-party scripts loaded from CDNs (`cdnjs.cloudflare.com`, `cdn.jsdelivr.net`, `unpkg.com`, etc.) via `<script src="...">` without `integrity` attribute. Flag only for scripts, not stylesheets (lower risk). Note the CDN domain and resource.
 
**62. Source map exposure in production**
`.map` files served from the production domain (`/static/js/*.js.map`, `/assets/*.map`). Webpack/Vite/esbuild/Rollup `devtool` config set to `source-map` (external map files) in production builds. Source maps expose original source code, internal file paths, comments, and sometimes embedded secrets/TODOs. Check: `devtool` in `webpack.config.*`, `build.sourcemap` in `vite.config.*`, `sourceMap` in `tsconfig.json` production build.
 
---
 
## Platform module: Scripts / CLI / Infrastructure (categories 63–70)
 
Apply when the repository contains Dockerfiles, CI/CD configs, Terraform/Pulumi, Helm/Kubernetes manifests, shell scripts, or standalone Python/Ruby/Node CLI tools.
 
**63. Credentials in CI/CD config**
Secrets, API keys, tokens, or passwords hardcoded in: `.github/workflows/*.yml`, `.gitlab-ci.yml`, `Jenkinsfile`, `bitbucket-pipelines.yml`, `azure-pipelines.yml`, `.circleci/config.yml`, `Makefile`, build scripts. Include: secrets passed as build args (`--build-arg SECRET=value`), environment variables in plain text in CI configs, secrets in Terraform `variable` defaults.

Note: If the finding is a hardcoded credential value, report under **category 12** and cross-reference here. Category 63 covers structural CI/CD issues (insecure patterns, build arg exposure, missing secret masking) that are not purely "a secret in a file."
 
**64. Dockerfile security**
Running as root (no `USER` directive after package install). `COPY . .` or `ADD . .` including `.env`, `.git`, credentials. Unpinned base images (`:latest`, no digest). Secrets in `ENV` or `ARG` that persist in image layers. `apt-get install` without `--no-install-recommends`. Exposed ports with no documentation of expected auth. Health check endpoints with sensitive data.
 
**65. Kubernetes / Helm deployment security**
Privileged containers (`privileged: true`, `allowPrivilegeEscalation: true`). `hostNetwork: true`, `hostPID: true`, `hostIPC: true`. Missing `readOnlyRootFilesystem`. Service accounts with `cluster-admin` or overly broad RBAC. Secrets in ConfigMaps instead of Secrets. Missing `NetworkPolicy` (all pods can reach all pods). Missing resource `limits` (CPU/memory — enables DoS). `automountServiceAccountToken: true` (default) on pods that don't need API access. Tiller / Helm 2 usage (unauthenticated cluster-admin). `emptyDir` volumes for sensitive data (no encryption at rest).
 
**66. Serverless misconfiguration**
Lambda / Cloud Functions / Azure Functions with: overly broad IAM execution role (`Action: *`, `Resource: *`), public API Gateway endpoint without authentication, environment variables containing secrets visible in cloud console (use SSM/Secrets Manager instead), no VPC binding when accessing internal resources, `timeout` and `memorySize` set high enough to be cost-exploitable, missing reserved concurrency (allows cost-based DoS), function URL with `AuthType: NONE`.
 
**67. IaC state file exposure**
`terraform.tfstate`, `terraform.tfstate.backup`, or `pulumi.*.json` committed to the repository. These files contain every secret, resource ID, and configuration value in plaintext. Check: `.gitignore` missing `*.tfstate*`, state files present in git history, S3/GCS state backend without encryption or access logging. Also flag: `terraform.tfvars` with real secrets (should use env vars or secret manager references).
 
**68. Unsafe file operations in scripts**
Temp file creation via predictable names (`/tmp/myapp_export.csv`) instead of `mkstemp`/`mkdtemp`. Symlink following on user-writable paths. World-readable permissions (`chmod 777`, `0666`) on sensitive files. `tar` extraction without path validation (zip slip). Script that runs as root and writes to user-specified paths without canonicalization.
 
**69. Shell injection in scripts**
`os.system()`, `subprocess.run(shell=True)`, `subprocess.Popen(shell=True)` with f-strings or `.format()`. Backtick execution in Ruby/Perl. `child_process.exec()` with template literals. `eval` in bash with user-supplied variables. `xargs` without `-0` on filenames with spaces/special characters.
 
**70. GitHub Actions security**
`pull_request_target` trigger with `actions/checkout` of PR HEAD (allows PR author to execute arbitrary code with write permissions). `workflow_run` trigger processing artifacts from untrusted workflows. `${{ github.event.issue.body }}` or `${{ github.event.pull_request.title }}` in `run:` steps (script injection). Secrets available to forked PR workflows. `GITHUB_TOKEN` with overly broad permissions (`permissions: write-all`). Third-party actions referenced by tag instead of SHA.
 
---
 
## Platform module: Desktop / Native (categories 71–76)
 
Apply when the project is an Electron, Tauri, Qt, GTK, WPF, WinForms, SwiftUI (macOS), or any native application that runs with local user privileges.
 
**71. Auto-updater security**
Update mechanism that downloads and executes code without: signature verification on the update payload (Authenticode, GPG, Ed25519), pinned TLS to the update server, rollback protection (version downgrade attacks). Check: Electron `autoUpdater` without `verifyUpdateCodeSignature`, Tauri updater without `pubkey` config, custom updater using plain HTTP or HTTPS without cert/signature verification. A compromised update channel gives persistent RCE on every installed client.
 
**72. IPC / named pipe / socket security**
Inter-process communication channels (named pipes, Unix domain sockets, D-Bus, Windows COM, Electron `ipcMain`/`ipcRenderer`) that: accept connections without authenticating the peer, pass unsanitized data to privileged operations, expose privileged APIs to renderer/untrusted processes. Electron-specific: `contextIsolation: false`, `nodeIntegration: true` in renderer, `webSecurity: false`, `remote` module enabled, `shell.openExternal()` with user-controlled URLs.
 
**73. Local privilege escalation**
Application installs services/daemons running as root/SYSTEM that accept commands from unprivileged users. Writable installation directories under `%PROGRAMFILES%` (Windows) or `/usr/local/bin` (Unix) that allow DLL/dylib hijacking. Setuid binaries with exploitable input handling. Insecure `PATH` or `LD_LIBRARY_PATH`/`DYLD_LIBRARY_PATH` usage in helper scripts.
 
**74. DLL / dylib / shared library hijacking**
Application loads libraries from relative paths or user-writable directories without integrity checks. Windows: missing `SetDllDirectory("")`, `LoadLibrary` with relative path, manifest without `<dllRedirection>`. macOS: `@rpath` pointing to user-writable locations. Linux: `RPATH`/`RUNPATH` set to relative or writable directories. Electron: native modules loaded from `app.asar.unpacked` without verification.
 
**75. Sensitive data in local files**
Application writes tokens, credentials, PII, or encryption keys to plaintext files in user-accessible directories (`~/.config/`, `%APPDATA%/`, `Application Support/`). Missing file permission restrictions (world-readable). Logs containing sensitive data. SQLite databases without encryption storing auth tokens. Check: `fs.writeFileSync` / `open()` / `fwrite()` writing secrets to disk without OS-level encryption (DPAPI on Windows, Keychain on macOS, `libsecret` on Linux).
 
**76. Deep link / custom protocol handler hijacking**
Application registers custom URL schemes (`myapp://`) or file associations (`.myapp`) without validating the origin or content of incoming URLs. Attacker-crafted URLs can: trigger privileged actions, inject arguments into command-line parsing, navigate embedded WebViews to malicious sites, or exploit argument injection in protocol handler registration. Check: scheme handlers that pass URL components to shell commands, file handlers that auto-open/execute content.
 
---

## Git History module (categories 77–80) — always apply

This module scans git history for secrets that were committed and later removed. These secrets remain extractable by anyone who can clone the repository. **This module is always activated** — it requires no platform detection.

### Prerequisites

This module requires a **full clone** (not shallow). If reviewing a shallow clone, note the limitation in the report header and skip categories 77–78. Run `git log --oneline | wc -l` to verify depth.

**Tooling:** This module uses **gitleaks** for automated scanning. Run gitleaks first, then perform the manual verification steps described in each category. Gitleaks catches pattern-matched secrets; manual steps catch what gitleaks misses.

### Gitleaks execution (mandatory first step)

Before manual review, run:

```bash
# Scan current working tree
gitleaks detect --source . --no-git --report-format json --report-path gitleaks-current.json

# Scan full git history
gitleaks detect --source . --report-format json --report-path gitleaks-history.json

# If a .gitleaks.toml config exists in repo, it will be used automatically.
# If it does not exist, use default rules — do NOT skip this step.
```

Process gitleaks output:
1. Parse both JSON reports.
2. For each finding, record: `RuleID`, `Description`, `File`, `StartLine`, `Commit`, `Author`, `Date`, `Match` (the secret value — apply redaction rule from category 12 before including in report).
3. Deduplicate: same secret value across multiple commits = one finding with an exposure timeline showing all commits.
4. Validate: discard findings that match known placeholder/test patterns (see category 12 exclusions). Mark ambiguous matches as **medium confidence**.
5. Every gitleaks finding that survives validation becomes a category 77 or 78 finding (77 if still in current tree, 78 if removed).

After gitleaks, proceed with the manual steps below — they catch secrets gitleaks misses (encoded secrets, secrets in binary-adjacent paths, suspicious commit patterns).

---

**77. Secrets in git history — still present in current tree**

Secrets found by gitleaks in the current working tree scan (`gitleaks-current.json`) AND confirmed by manual review.

Manual supplement — run these after gitleaks to catch encoded/contextual secrets it may miss:

```bash
# Connection strings with embedded credentials (gitleaks may miss URL-encoded passwords)
git grep -nE '(mongodb|postgres|mysql|redis|amqp|mssql)://[^:]+:[^@]+@'

# Base64 blobs near credential variable names
git grep -nE '(secret|key|token|password|credential|auth)\s*[:=]\s*[A-Za-z0-9+/]{40,}={0,2}'

# PEM private keys
git grep -lE '-----BEGIN .* PRIVATE KEY-----'

# Hardcoded JWTs (decode payload to verify non-test)
git grep -nE 'eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.'
```

For each finding, determine:
- **What it authenticates to** (cloud provider, database, SaaS, internal service)
- **What access it grants** (read-only, read-write, admin)
- **Whether it appears to be production, staging, or development** (check hostname, variable naming, surrounding config context)

**78. Secrets in git history — removed from current tree but never rotated**

The highest-value category. Secrets found by gitleaks in the history scan (`gitleaks-history.json`) that are NOT present in the current working tree — meaning a developer committed them, then deleted them in a later commit. The secret remains extractable from git history forever.

Manual supplement — run these after gitleaks:

```bash
# Files deleted from tree that commonly contain secrets
git log --all --diff-filter=D --name-only -- '*.env*' '*.pem' '*.key' '*.p12' '*.pfx' '*.jks' '*.keystore'

# Show full content of all .env file changes across entire history
git log --all -p -- '*.env*' '*.secret*' '*.credentials*'

# Search history for secret-pattern strings (catches secrets gitleaks rules may not cover)
git log --all -p -S 'AKIA' -- .
git log --all -p -S 'sk_live_' -- .
git log --all -p -S 'sk-ant-' -- .
git log --all -p -S 'ghp_' -- .
git log --all -p -S 'glpat-' -- .
git log --all -p -S 'xox' -- .
git log --all -p -S 'SG.' -- .
git log --all -p -S 'BEGIN PRIVATE KEY' -- .
git log --all -p -S 'service_account' -- .

# Commits with messages suggesting secret cleanup (often the removal commit — look at the PARENT commit for the actual secret)
git log --all --oneline --grep='remove secret\|fix credential\|rotate key\|oops\|revert.*password\|remove password\|update env\|remove api.key\|accidental'
```

For each finding, build an **exposure timeline**:

| Event | Commit SHA | Date | Author |
|-------|-----------|------|--------|
| Introduced | `{sha}` | `{date}` | `{author}` |
| Removed | `{sha}` | `{date}` | `{author}` |
| Rotated | `{sha}` or **no evidence found** | | |

To check for rotation evidence: search current tree for the same variable name with a different value, check CI/CD configs for secret manager references replacing the hardcoded value, or look for commits with messages like `rotate`, `regenerate`, `new key`. If no evidence of rotation exists, assume the secret is still valid.

**Status classification:**
- `ACTIVE` — secret is in the current working tree right now
- `REMOVED_NOT_ROTATED` — deleted from tree but no evidence the credential was rotated/revoked at the provider
- `REMOVED_ROTATED` — deleted from tree AND evidence of rotation found (new value, secret manager migration, provider-side revocation commit message)
- `UNKNOWN` — cannot determine status from available evidence

**79. Git remote and submodule credential exposure**

```bash
# Check .git/config for credentials embedded in remote URLs
git config --list | grep -E 'url.*://[^@]+@'

# Check .gitmodules for submodule URLs with embedded credentials
cat .gitmodules 2>/dev/null | grep -E 'url.*://[^@]+@'

# Check .gitmodules for submodule URLs pointing to domains that may be claimable
# (abandoned orgs, expired domains — flag for manual verification)
cat .gitmodules 2>/dev/null | grep url
```

Flag:
- Remote URLs in format `https://user:token@github.com/...` — the token is cloned to every developer's machine
- Submodule URLs with embedded credentials
- Submodule URLs pointing to GitHub orgs/repos that no longer exist (supply chain hijack risk — attacker registers the abandoned namespace)

**80. Missing secret prevention controls**

Check for the *absence* of secret-leak prevention mechanisms. These are Medium severity — they represent missing guardrails, not active exposures.

```bash
# Pre-commit hook with secret scanning
ls .pre-commit-config.yaml 2>/dev/null && grep -l 'detect-secrets\|gitleaks\|trufflehog\|talisman' .pre-commit-config.yaml

# Gitleaks config (indicates awareness of secret scanning)
ls .gitleaks.toml .gitleaksrc 2>/dev/null

# CI pipeline secret scanning step
grep -rl 'gitleaks\|trufflehog\|detect-secrets' .github/workflows/ .gitlab-ci.yml .circleci/ Jenkinsfile bitbucket-pipelines.yml 2>/dev/null

# .gitignore coverage for secret-bearing file types
grep -E '\.env|\.pem|\.key|\.p12|\.pfx|\.jks|\.keystore|tfstate|\.secret' .gitignore 2>/dev/null
```

Report:

| Control | Status | Recommendation |
|---------|--------|----------------|
| `.gitignore` coverage for secret file types | `{adequate / gaps — list missing entries}` | Add: `*.env*`, `*.pem`, `*.key`, `*.p12`, `*.pfx`, `*.jks`, `*.keystore`, `*.tfstate*` |
| Pre-commit secret scanning hook | `{present / absent}` | Add `gitleaks` to `.pre-commit-config.yaml` |
| CI pipeline secret scanning | `{present / absent}` | Add `gitleaks detect` step to CI pipeline |
| Gitleaks config file | `{present / absent}` | Create `.gitleaks.toml` with project-specific allowlist for known false positives |

---
 
## Quality bar
 
- Report all **Critical** and **High**.
- Report **Medium** only if exploitable from a public entrypoint.
- **Exception for Git History findings (categories 77–80):** Report Medium for missing prevention controls (category 80) even without a public entrypoint — these are preventive control gaps. Report all Critical/High from categories 77–78 regardless of public/private repo status — any person with clone access can extract the secrets.
- Skip **Low** and **Info**.
### Chain escalation rules
 
When two findings combine to form a more dangerous exploit chain, escalate severity. Apply every matching rule — multiple can fire on the same finding. Rules reference category names so they survive renumbering.
 
| Rule | Trigger combination | Escalation | Rationale |
|------|---------------------|------------|-----------|
| **CSP × Injection** | CSP ineffective + any XSS/injection finding (Injection, SSR hydration, HTML attribute injection, SSTI, DOM sinks) | Injection finding escalates one level (Medium→High, High→Critical) | Weak CSP removes the last defense; injection becomes guaranteed script execution. |
| **PCI × Auth bypass** | PCI scope indicator + missing auth or auth bypass (Authentication, OAuth, Business-logic trust, Trust decisions) | Escalate to Critical | Unauthenticated access to PAN triggers mandatory breach notification and PCI scope expansion. |
| **Injection × Cookie flags** | Any XSS/injection finding + auth cookies missing `httpOnly` | Injection finding escalates one level | Injection + readable auth cookies = full session hijack / account takeover chain. |
| **IDOR × Sensitive data** | IDOR on endpoint returning/modifying payment methods, PAN, SSN, medical records, or auth credentials | Escalate to Critical | Data sensitivity multiplies impact beyond generic IDOR. Note the data type in the finding. |
| **Open redirect × OAuth** | Open redirect on an OAuth `redirect_uri` callback endpoint | Escalate to Critical | Attacker steals authorization codes via redirect, yielding victim's access token. |
| **Prompt injection × Destructive tools** | Prompt injection + uncontrolled tool calling where tools include destructive actions (delete, send, pay, modify, write) | Escalate to Critical | Prompt injection with destructive tool access is RCE-equivalent — attacker executes arbitrary actions under the user's identity. |
| **Proxy trust × Host-header sink** | Proxy misconfiguration + any finding using `req.hostname`/`req.ip`/`req.protocol` for redirects, URL construction, or security decisions | Co-occurring finding escalates one level | Proxy trust is the enabler; without it the downstream bug may be unexploitable. |
| **Race condition × Financial op** | TOCTOU on payment, balance, coupon, credit, quota, or inventory operation | Escalate to Critical | Double-spend, coupon replay, or balance manipulation has direct financial impact. |
| **Secrets exposure × Public reach** | Hardcoded secret (category 12) or history secret (categories 77–78) used by an unauthenticated endpoint, exposed in client bundle, in a public repository, or in a repo accessible to 50+ users (e.g. org-wide read) | Escalate to Critical | Secret is actively exploitable without any precondition — rotate immediately. |
| **Multi-agent × Destructive agent** | Compromised agent output reaching an agent with destructive tools | Escalate to Critical | One poisoned agent cascades to destructive actions in another; blast radius multiplied by agent count. |
| **Supply chain × CI/CD** | Malicious install script or unpinned action in a CI/CD pipeline that has access to production secrets or deployment credentials | Escalate to Critical | Supply chain compromise in CI/CD = arbitrary code execution with production access. |
| **History secret × CI/CD access** | Secret from git history (category 78) is a CI/CD token, deploy key, or cloud IAM credential AND the CI pipeline has production deployment permissions | Escalate to Critical | Extracted historical credential grants production deployment access. |
| **History secret × Cloud IAM** | AWS `AKIA*` key, GCP service account JSON, or Azure `SharedAccessKey` found in git history (category 78) with status `REMOVED_NOT_ROTATED` | Escalate to Critical | Cloud IAM credentials enable lateral movement across the entire cloud account — blast radius is the full cloud estate. |
 
## Exclusions
 
Do not report vulnerabilities located in:
- Vendored deps (`node_modules/`, `vendor/`, `.cargo/registry/`, `venv/`, `.venv/`)
- Generated code (auto-generated clients, protobuf output, GraphQL codegen)
- Build output (`dist/`, `build/`, `target/`, `.next/`, `coverage/`, `out/`, `.nuxt/`)

**Test file rules:**
- For **categories 1–76**: Do not report vulnerabilities in test files (`*.test.*`, `*_test.go`, `__tests__/`, `tests/`, `*.spec.*`, `cypress/`, `e2e/`, `playwright/`). **Do** read test files as evidence — tests that assert insecure behavior confirm the production bug is intentional and exploitable. Cite them in the **Related** scope tier.
- For **categories 77–80 (Git History)**: **DO scan and report secrets in test files.** Developers frequently put real credentials in test fixtures. A real AWS key in `tests/integration/test_api.py` is just as exploitable as one in `src/config.py`. The exclusion for test files does NOT apply to secret findings.

**Git history exclusions:**
- Do not report secrets in vendored dependency commits (changes only within `node_modules/`, `vendor/`, etc.)
- Do not report gitleaks findings that match the project's `.gitleaks.toml` allowlist (if one exists) — but DO note in the report that an allowlist is in use and list what it suppresses, so stakeholders can verify the suppressions are appropriate.
 
## Search behavior
 
Use **grep / ripgrep across the entire repository**. Do not sample. Do not stop after finding N issues. Every claim about the code must cite `file:line`. Findings without file:line citations are invalid and must be dropped.

**For Git History findings (categories 77–78):** Citations must include the commit SHA: `commit_sha:file:line`. Use gitleaks JSON output as the primary source, supplemented by manual `git log -p` verification. Findings without `commit:file:line` citations are invalid.
 
---
 
## Confidence
 
Each finding must have a confidence rating:
- **high** — vulnerable code pattern directly visible in source
- **medium** — exploitability depends on downstream service behavior, runtime config, or caller context
- **low** — pattern match only; may be mitigated by unseen controls

**Additional guidance for secret findings (categories 12, 77–78):**
- **high** — string matches a known secret format (see pattern table in category 12) AND is used as a credential in code context (assigned to `Authorization` header, passed to SDK constructor, used in connection string, referenced by credential-named variable)
- **medium** — string matches a known format but context is ambiguous (could be test/placeholder, could be real), OR variable is named like a secret but value is unclear
- **low** — high-entropy string in a suspicious location but no format match or clear credential usage
---
 
## Deliverable
 
A single markdown file suitable for engineering and security stakeholders.
 
**Output location:** Save the report to `{REPO_NAME}-security-assessment-report-{scan-date-in-yyyy-mm-dd-format}.md`. Do not print inline.
 
---
 
## Document structure
 
### Report header
 
```
# Security review of {repo_name}
 
| Field | Value |
|-------|-------|
| Repository | {repo_name} (`org/repo`) |
| Review type | Static source, configuration, and git history review (80-category scope) |
| Service context | {service name and business function — from Service Context section, or "Inferred from code: {description}"} |
| CVSS version | 3.1 Base |
| Platform modules activated | {list modules and why} |
| Git history module | Active — {full clone / shallow clone (limited)} |
| Gitleaks version | {output of `gitleaks version`} |
| Gitleaks findings (raw) | {count from gitleaks-current.json} current tree, {count from gitleaks-history.json} history |
| Gitleaks findings (validated) | {count after dedup and false-positive removal} |
| Categories scoped | {list all activated category numbers} |
```
 
### How to read Scope, Location, and Execution flow
 
Include this section verbatim:
 
> - **Scope — Defect**: Files containing the vulnerable pattern or missing control; fix these first.
> - **Scope — Propagation**: Code that forwards tainted data or registers the route that reaches the defect.
> - **Scope — Related**: Tests, mitigations, or contrast files for context only (unless the defect is in that file).
> - **Location**: Canonical subset of Defect-tier paths for the finding.
> - **Location (git history)**: `commit_sha:file:line` — secret was present at this commit. May no longer be in current tree.
> - **Execution flow**: Numbered path from request entry to sink, each step citing `file:line`.
>
> For simple single-file findings, Scope collapses to just a file path. The three-tier breakdown is for multi-file chains.
>
> **Confidence**: *high* = pattern visible in code (or known secret format + credential context); *medium* = depends on downstream service behavior (or ambiguous secret); *low* = pattern match only.
>
> **Severity**: Critical 9.0–10.0 · High 7.0–8.9 · Medium 4.0–6.9.
 
### Findings summary table
 
```
| # | Title | Severity | Category | Confidence | Status |
|---|--------|----------|----------|------------|--------|
```

Sort rows by severity descending: Critical first, then High, then Medium. Within the same severity, order by confidence descending (high → medium → low).

Note: **Status** column applies only to secret findings (categories 12, 77–78). Use `ACTIVE`, `REMOVED_NOT_ROTATED`, `REMOVED_ROTATED`, or `UNKNOWN`. Leave blank for non-secret findings.

### Finding order

Present findings in the report body in the same order as the summary table: all Critical findings first, then High, then Medium. Within the same severity, high-confidence findings before medium and low.
 
### Per finding — required fields
 
**Severity** — Critical / High / Medium with CVSS mapping.
 
**Confidence** — high / medium / low.
 
**CVSS 3.1 Base** — For high-confidence findings with non-obvious severity: produce a full vector string with per-metric reasoning (AV, AC, PR, UI, S, C, I, A). For self-evident severity (e.g. hardcoded production secret in a public repo = Critical, missing httpOnly on session cookie = Medium): state the score and a one-line justification instead of the full breakdown. Mark uncertain metrics where applicable.

**For secret findings (categories 12, 77–78):** CVSS is a poor fit for credential exposure. Instead of forcing a full vector, use this severity anchor:
- **Critical** — Production secret, cloud IAM key, private signing key, or payment processor live key. Active or removed-not-rotated.
- **High** — Staging/development secret that shares format with production, or removed-not-rotated secret of any environment where rotation status is uncertain.
- **Medium** — Ambiguous secret (may be placeholder), or missing prevention control (category 80).

State the severity level and a one-line justification. Full CVSS vector is optional for secret findings.
 
**Scope** — For findings spanning multiple files: use the three-tier table (Defect / Propagation / Related). For single-file findings (e.g. a missing flag, a config value): list the file path directly — no table needed.
 
Three-tier table format (when applicable):
 
```
| Tier | Paths |
|------|-------|
| Defect | ... |
| Propagation | ... |
| Related | ... |
```
 
**Location** — Canonical path(s) to defect files. For git history findings: `commit_sha:file:line`.
 
**Execution flow** — Numbered steps from request entry to sink, each citing `file:line`. Keep it as short as the chain actually is — don't pad simple flows. For complex chains, include every meaningful hop but aim for clarity over completeness (typically 3–10 steps). **For secret findings:** execution flow is optional — most secrets are single-location findings. Include only if the secret propagates through multiple files (e.g. loaded from config, passed to SDK, forwarded to downstream service).
 
**Issue details** — Mechanism (2–3 sentences). Preconditions (what attacker needs).
 
**Implicit assumption violated** — One sentence stating what the code assumes about its inputs or environment that an attacker can break. **Required** when the finding depends on code trusting an input, identity, ownership, timing, or environment property it shouldn't — typically findings involving authentication, authorization, identity, trust boundaries, business logic, race conditions, or AI agent trust. Omit for pure configuration or dependency findings where no implicit trust is involved.
 
**Steps to reproduce** — Concrete steps, including curl commands or UI actions. **For git history secrets:** include the exact git command to extract the secret: `git show {commit_sha}:{file_path} | grep -n '{redacted_pattern}'`.
 
**Affected code** — `path/to/file:startLine-endLine` with inline code block. **Apply redaction rule:** never print full secret values. Show first 8 + `...` + last 4 characters.

**Exposure timeline** (required for categories 77–78, optional for category 12):
```
| Event | Commit SHA | Date | Author |
|-------|-----------|------|--------|
| Introduced | {sha} | {date} | {author} |
| Removed | {sha} | {date} | {author} |
| Rotated | {sha or "no evidence found"} | | |
```

**Blast radius** (required for secret findings): What an attacker can do with this specific secret. Be concrete: "Read/write access to production PostgreSQL on `db.example.com` containing customer PII" — not "database access."
 
**Exploit dependency** — What an attacker or condition needs and how that dependency can be satisfied. **For git history secrets:** "Attacker needs clone access to the repository. For public repos: no precondition. For private repos: any org member, contractor, or CI system with read access."
 
**Business risk** — Include only if the code clearly handles payments, PII, auth tokens, or partner integrations. Do not invent business context.
 
**Recommended fix** — Concrete code change with example. Not generic advice. If recommending a secret manager, name it (Google Secret Manager / AWS Secrets Manager / HashiCorp Vault) and reference known internal config if visible in the repo. **For git history secrets, the fix has three mandatory parts:**
1. **Rotate** — specific rotation steps for this credential type at the provider
2. **Purge from history** — `git filter-repo --invert-paths --path {file}` or `bfg --replace-text passwords.txt` command (note: requires force-push and re-clone by all developers)
3. **Prevent recurrence** — specific `.gitignore` entry, pre-commit hook config, or secret manager migration

**CWE / OWASP** — Primary CWE ID (e.g. CWE-639 for IDOR, CWE-89 for SQLi) and OWASP Top 10 2021 mapping (e.g. A01:2021 Broken Access Control). If no standard CWE maps cleanly, state "No direct CWE" and describe the weakness class. For secret findings (categories 12, 77–78): use CWE-798 (Use of Hard-coded Credentials) or CWE-540 (Inclusion of Sensitive Information in Source Code).
 
### Negative findings section (required)
 
After all findings, include:
 
```
## Categories reviewed with no qualifying findings
```
 
List every activated category that had no Critical/High/Medium findings, with a one-line note explaining why (e.g., "no user-input file paths in server", "Apple Pay validates gateway hosts at `file:line`").
 
### Positive controls observed (required)
 
List security controls that are correctly implemented. These provide audit evidence and highlight what NOT to break during remediation. Format:
 
```
## Positive controls observed
 
- {Description} — `file:line`
```

For git history, include positive observations like:
- Pre-commit secret scanning hook present — `.pre-commit-config.yaml:12`
- Gitleaks CI step configured — `.github/workflows/security.yml:34`
- `.gitignore` covers `*.env*`, `*.pem`, `*.key` — `.gitignore:8-12`
- Secrets loaded from environment/secret manager, not hardcoded — `src/config.ts:15`
 
### Remediation priority (required)
 
```
## Recommended remediation priority
 
1. **Immediate (same-hour):** {active production secrets in current tree — rotate NOW, then continue review. Cloud IAM keys, payment processor live keys, private signing keys.}
2. **Urgent (same-day):** {secrets removed from tree but not rotated (category 78 REMOVED_NOT_ROTATED), active credential exposure via unauthenticated endpoints, PCI scope violations}
3. **Short-term (this sprint):** {exploitable auth bypass, open redirects on payment flows, IDOR on customer data, git history purge with git-filter-repo/BFG, .gitignore gaps}
4. **Planned (next quarter):** {architectural changes, JWT redesign, CSP nonce migration, agent trust model, pre-commit hook rollout, secret manager migration, developer training on secret hygiene}
```
 
Group findings by remediation batch, not by individual finding number.

**Immediate-action escalation rule:** If any category 77 finding is a production cloud IAM key (AWS `AKIA*`, GCP service account, Azure key) or payment processor live key (`sk_live_*`), prepend this to the report before the findings summary:

```
## ⚠️ IMMEDIATE ACTION REQUIRED

The following active production secrets were found in the current tree. Rotate these BEFORE reading the rest of this report:

| Secret type | Location | Rotate at |
|-------------|----------|-----------|
| {type} | {file:line} | {provider console URL} |
```
 
---
 
## Footer
 
```
*Report generated from static analysis and git history scan of repository `{repo_name}` at review time. Secrets identified in git history remain extractable until history is rewritten (git-filter-repo / BFG) and all clones are refreshed. Rotation of compromised credentials is required regardless of history purge — assume any committed secret is compromised. Re-validate findings after remediation and in target deployment configuration.*
```
