# Universal source code security review prompt
 
> **Version:** 3.1
> **Categories:** 76 (37 base + 39 platform-specific)
> **Scope:** Backend, frontend, mobile, AI/LLM, scripts, CI/CD, infrastructure, desktop/native
> **Last updated:** 2026-06-02
 
---
 
## Preamble — platform detection
 
Before scanning, detect the project type from manifest files (`package.json`, `build.gradle`, `Podfile`, `Cargo.toml`, `go.mod`, `requirements.txt`, `pyproject.toml`, `setup.py`, `setup.cfg`, `Pipfile`, `pom.xml`, `build.sbt`, `Gemfile`, `Package.swift`, `pubspec.yaml`, `*.csproj`, `*.sln`), directory structure, and code patterns. Apply **Base categories (1–37)** to every project. Then apply the relevant **platform module(s)**:
 
- **AI/LLM integration detected** — dependency on `openai`, `anthropic`, `langchain`, `llama-index`, `transformers`, `autogen`, `crewai`, `semantic-kernel`, `google-generativeai`, `cohere`, `replicate`, or similar AI SDK; OR code making direct HTTP calls to LLM provider APIs (`api.openai.com`, `api.anthropic.com`, etc.); OR prompt template files (`.prompt`, `.jinja2` with LLM-shaped messages): also apply **categories 38–47**
- **Mobile** — React Native, Flutter, Android (Kotlin/Java), iOS (Swift/ObjC); OR presence of `AndroidManifest.xml`, `Info.plist`, `build.gradle` with `com.android.*`, `*.xcodeproj`, `pubspec.yaml` with `flutter`: also apply **categories 48–55**
- **Web frontend with SSR** — Next.js, Nuxt, Remix, SvelteKit, Astro, or any project with server-rendered HTML templates (EJS, Pug, Handlebars, Jinja2 files serving user-facing pages): also apply **categories 56–62**
- **Web frontend SPA-only** — React, Vue, Angular, Svelte without SSR: also apply **categories 59–62**
- **Scripts / CLI / infrastructure** — Dockerfile, docker-compose, Terraform/Pulumi, Helm/K8s manifests, CI configs, shell/python/ruby scripts; OR presence of `k8s/`, `helm/`, `charts/`, `manifests/`, `.github/workflows/`, `serverless.yml`, `template.yaml` (SAM): also apply **categories 63–70**
- **Desktop / native application** — Electron, Tauri, Qt, GTK, WPF, WinForms, SwiftUI (macOS), or any native binary that runs with local user privileges; OR presence of `electron-builder.yml`, `tauri.conf.json`, `*.wxs` (WiX installer), native IPC/named-pipe code: also apply **categories 71–76**
Multiple modules can apply simultaneously (e.g. a Next.js app with OpenAI integration applies Base + Web SSR + AI/LLM).
 
If the project type is ambiguous, activate the broader set of modules and note the uncertainty in the report header. It is better to check an irrelevant category (and report "no findings") than to miss an active attack surface.
 
State which platform modules were activated and why in the report header.
 
---
 
## Instructions
 
Perform a source code and configuration security review of this repository. Cover only the categories listed below that are activated by the platform detection above.
 
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
 
## Quality bar
 
- Report all **Critical** and **High**.
- Report **Medium** only if exploitable from a public entrypoint.
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
| **Secrets exposure × Public reach** | Hardcoded secret used by an unauthenticated endpoint, exposed in client bundle, or in a public repository | Escalate to Critical | Secret is actively exploitable without any precondition — rotate immediately. |
| **Multi-agent × Destructive agent** | Compromised agent output reaching an agent with destructive tools | Escalate to Critical | One poisoned agent cascades to destructive actions in another; blast radius multiplied by agent count. |
| **Supply chain × CI/CD** | Malicious install script or unpinned action in a CI/CD pipeline that has access to production secrets or deployment credentials | Escalate to Critical | Supply chain compromise in CI/CD = arbitrary code execution with production access. |
 
## Exclusions
 
Do not report vulnerabilities located in:
- Test files (`*.test.*`, `*_test.go`, `__tests__/`, `tests/`, `*.spec.*`, `cypress/`, `e2e/`, `playwright/`)
- Vendored deps (`node_modules/`, `vendor/`, `.cargo/registry/`, `venv/`, `.venv/`)
- Generated code (auto-generated clients, protobuf output, GraphQL codegen)
- Build output (`dist/`, `build/`, `target/`, `.next/`, `coverage/`, `out/`, `.nuxt/`)
**Do** read test files as evidence — tests that assert insecure behavior confirm the production bug is intentional and exploitable. Cite them in the **Related** scope tier.
 
## Search behavior
 
Use **grep / ripgrep across the entire repository**. Do not sample. Do not stop after finding N issues. Every claim about the code must cite `file:line`. Findings without file:line citations are invalid and must be dropped.
 
---
 
## Confidence
 
Each finding must have a confidence rating:
- **high** — vulnerable code pattern directly visible in source
- **medium** — exploitability depends on downstream service behavior, runtime config, or caller context
- **low** — pattern match only; may be mitigated by unseen controls
---
 
## Deliverable
 
A single markdown file suitable for engineering and security stakeholders.
 
**Output location:** Save the report to `SECURITY_REVIEW_{REPO_NAME}.md`. Do not print inline.
 
---
 
## Document structure
 
### Report header
 
```
# Security review of {repo_name}
 
| Field | Value |
|-------|-------|
| Repository | {repo_name} (`org/repo`) |
| Review type | Static source and configuration review (76-category scope) |
| CVSS version | 3.1 Base |
| Platform modules activated | {list modules and why} |
| Categories scoped | {list all activated category numbers} |
```
 
### How to read Scope, Location, and Execution flow
 
Include this section verbatim:
 
> - **Scope — Defect**: Files containing the vulnerable pattern or missing control; fix these first.
> - **Scope — Propagation**: Code that forwards tainted data or registers the route that reaches the defect.
> - **Scope — Related**: Tests, mitigations, or contrast files for context only (unless the defect is in that file).
> - **Location**: Canonical subset of Defect-tier paths for the finding.
> - **Execution flow**: Numbered path from request entry to sink, each step citing `file:line`.
>
> For simple single-file findings, Scope collapses to just a file path. The three-tier breakdown is for multi-file chains.
>
> **Confidence**: *high* = pattern visible in code; *medium* = depends on downstream service behavior; *low* = pattern match only.
>
> **Severity**: Critical 9.0–10.0 · High 7.0–8.9 · Medium 4.0–6.9.
 
### Findings summary table
 
```
| # | Title | Severity | Category | Confidence |
|---|--------|----------|----------|------------|
```
 
### Per finding — required fields
 
**Severity** — Critical / High / Medium with CVSS mapping.
 
**Confidence** — high / medium / low.
 
**CVSS 3.1 Base** — For high-confidence findings with non-obvious severity: produce a full vector string with per-metric reasoning (AV, AC, PR, UI, S, C, I, A). For self-evident severity (e.g. hardcoded production secret in a public repo = Critical, missing httpOnly on session cookie = Medium): state the score and a one-line justification instead of the full breakdown. Mark uncertain metrics where applicable.
 
**Scope** — For findings spanning multiple files: use the three-tier table (Defect / Propagation / Related). For single-file findings (e.g. a missing flag, a config value): list the file path directly — no table needed.
 
Three-tier table format (when applicable):
 
```
| Tier | Paths |
|------|-------|
| Defect | ... |
| Propagation | ... |
| Related | ... |
```
 
**Location** — Canonical path(s) to defect files.
 
**Execution flow** — Numbered steps from request entry to sink, each citing `file:line`. Keep it as short as the chain actually is — don't pad simple flows. For complex chains, include every meaningful hop but aim for clarity over completeness (typically 3–10 steps).
 
**Issue details** — Mechanism (2–3 sentences). Preconditions (what attacker needs).
 
**Implicit assumption violated** — One sentence stating what the code assumes about its inputs or environment that an attacker can break. **Required** when the finding depends on code trusting an input, identity, ownership, timing, or environment property it shouldn't — typically findings involving authentication, authorization, identity, trust boundaries, business logic, race conditions, or AI agent trust. Omit for pure configuration or dependency findings where no implicit trust is involved.
 
**Steps to reproduce** — Concrete steps, including curl commands or UI actions.
 
**Affected code** — `path/to/file:startLine-endLine` with inline code block.
 
**Exploit dependency** — What an attacker or condition needs and how that dependency can be satisfied.
 
**Business risk** — Include only if the code clearly handles payments, PII, auth tokens, or partner integrations. Do not invent business context.
 
**Recommended fix** — Concrete code change with example. Not generic advice. If recommending a secret manager, name it (Google Secret Manager / AWS Secrets Manager / HashiCorp Vault) and reference known internal config if visible in the repo.
 
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
 
### Remediation priority (required)
 
```
## Recommended remediation priority
 
1. **Immediate (same-day):** {active credential exposure, unauthenticated PII/PAN access, PCI scope violations}
2. **Urgent (this sprint):** {exploitable auth bypass, open redirects on payment flows, IDOR on customer data}
3. **Short-term (1–2 sprints):** {findings with exploit dependencies, config hardening, dependency upgrades}
4. **Planned (next quarter):** {architectural changes, JWT redesign, CSP nonce migration, agent trust model}
```
 
Group findings by remediation batch, not by individual finding number.
 
---
 
## Footer
 
```
*Report generated from static analysis of repository `{repo_name}` at review time. Re-validate findings after remediation and in target deployment configuration.*
```
