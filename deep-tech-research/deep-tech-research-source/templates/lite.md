# Lite Template

For small or weak models, no search, or tight output limits. Fewer constraints on purpose: instruction-following degrades as constraints multiply, and small models silently drop the ones at the back of a long list. Run it once per topic cluster rather than once for everything.

Fill `{TECHNOLOGY}` and `{VERSIONS}`.

```
You are a senior engineer writing a build-grade reference on {TECHNOLOGY},
version {VERSIONS}.

Use web search if you have it. Tag EVERY claim:
  [V] verified from a spec or official doc — give the URL
  [U] from memory, no source found
  [?] you looked and don't know
Never invent a URL. If you don't know, write [?]. Guessing is the worst outcome
here — a confident wrong byte offset or default value costs more than an
admitted gap. Any statement about future plans gets [F] plus
PROPOSED / ANNOUNCED / SPECULATIVE.

Cover ALL of these with real depth ("N/A" only with a reason):
1) what it is and why it exists; 2) governing body plus spec names and URLs;
3) versions and current stable; 4) core concepts glossary; 5) architecture and
internals; 6) wire or file format at byte level; 7) key API signatures plus
error contracts plus stability guarantees; 8) memory and concurrency model;
9) config surface with defaults; 10) install, build, toolchain; 11) official
conformance suite (name plus URL) and how to run it; 12) input-space taxonomy —
valid, invalid, boundary, malformed; 13) test oracles — how do you know an
output is right?; 14) invariants an implementation must hold; 15) environment and
compatibility matrix; 16) failure modes and fault-injection points; 17) resource
limits and behaviour at the limit; 18) performance and how to benchmark it
correctly; 19) security model and known CVEs with IDs; 20) licensing;
21) ecosystem and alternative implementations; 22) migration and deprecation
policy; 23) roadmap [F].

Include where they exist: a formal grammar (EBNF/ABNF), a protocol state
machine, byte-format tables, extension points, and three minimal WORKING code
examples labelled with version — one that USES it, one that PARSES or inspects
it, one that TESTS it.

Then: list anything you covered shallowly and fill it. Re-check your 8 riskiest
claims against sources, asking each as a standalone question without looking at
what you already wrote. End with an "Unknown / Unverified / Conflicts" list.

If this won't fit in one answer, output the outline first and ask which section
to expand.
```

## Running this on a weak model

Feed one section per turn rather than all 23 at once. Cut the list to roughly 8 items per call.

Never let the weak model run its own verification pass — a model that doesn't know a fact will return the same wrong answer to the verification question and pass itself. Run the audit on the strongest model available, or by hand.

Click every URL. On weak models, fabricated citations are the dominant failure mode, and the `[V]` tag will get attached to guesses.

Drop the memory palace and the claim ledger. Both need the whole dossier held in context at once.
