# Coverage Checklist

Every item appears in every dossier. Write "N/A" only with a stated reason.

**This is the file to edit when a gap is found.** Add a numbered item under the right group, keep the numbering contiguous, and log the change in `CHANGELOG.md`. Nothing else in the skill needs to change.

Group labels in brackets show which build class the item mainly serves: A = building on it, B = building for it, C = testing it.

## Foundations

1. History and motivation: what it replaced, design goals, alternatives that were rejected and why.
2. Governance: who steers it, how changes are proposed and ratified. [A B C]
3. Formal specifications and standards: exact document names, numbers, URLs. [A B C]
4. Versions, changelog, current stable, support and EOL status. [A B C]
5. Theory and mathematical foundations.
6. Core concepts and terminology — a glossary in plain language.

## Internals

7. Architecture: components and how they compose (context / container / runtime / deployment views). [A B]
8. Internal data structures and algorithms. [B]
9. Memory model and concurrency model: ordering, safety, synchronisation. [A C]
10. Wire protocols and file/binary formats at byte level: offsets, widths, endianness, framing, encoding, and how the format itself is versioned. [B]
11. Execution or evaluation model: the lifecycle from input to result. [A B]

## Build surface

12. Public APIs and SDKs: signatures, types, error contracts, stability guarantees. [A]
13. Extension and plugin points, and the ABI/API stability contract around them. [A]
14. Configuration surface: every meaningful knob, its default, its effect. [A C]
15. Installation, toolchain, build systems. [A B C]
16. Interoperability and standards compliance. [A B]

## Test and verification surface

This group is where dossiers most often go thin. Expand it deliberately.

17. Official conformance and test suites: name, URL, coverage, how to run them. [C]
18. Input-space taxonomy: valid inputs, invalid inputs, boundary values, adversarial and malformed inputs, encoding edge cases. [C]
19. Test oracles — how do you know an output is correct? Reference-implementation diffing, invariants, round-trip properties, golden files, formal semantics. [C]
20. Invariants and pre/post-conditions an implementation must hold, written so they can become property-based tests. [B C]
21. Fuzzing surface: entry points, grammars or seed corpora, known crash classes, existing fuzzers. [C]
22. Environment and compatibility matrix: OS, architecture, runtime versions, dependency versions, and where behaviour legitimately differs. [A C]
23. Determinism and reproducibility: what is guaranteed identical across runs and platforms, and what explicitly is not — float, iteration order, timing. [B C]
24. Fault injection and chaos: what can fail (network, disk, memory, clock, dependency), the injection points, expected degradation. [C]
25. Resource limits and behaviour at the limit: memory, connections, file size, recursion depth, timeouts, and what happens on exceeding each. [C]
26. Observability: logs, metrics, traces, and debug hooks available to a test harness. [A C]
27. Performance characteristics and benchmarking methodology: how to measure correctly, warm-up, what to hold constant, common measurement mistakes. Cite absolute numbers only with hardware, version, and workload context. [C]
28. Scalability limits and the shape of degradation. [C]

## Risk and context

29. Security model, threat model, trust boundaries, and known CVEs with IDs and advisory links. [A C]
30. Failure modes, edge cases, known gotchas and footguns. [A B C]
31. Licensing and legal/IP.
32. Ecosystem: libraries, competing and alternative implementations, tooling. Alternative implementations double as differential-testing targets. [B C]
33. Deployment and operations. [A]
34. Migration, versioning, and deprecation policy. [A]
35. Community and support channels.
36. Roadmap — every item tagged forward-looking with a status of PROPOSED / IN PROGRESS / ANNOUNCED / SPECULATIVE, plus source and date.
37. Learning resources: the best primary docs, books, courses.

---

## Provenance

These items are synthesised from real frameworks rather than invented, so the derivation can be checked:

- arc42 documentation template → items 1, 6, 7, 33
- Kruchten's 4+1 view model → items 7–9, 33
- C4 model abstraction levels → item 7
- ISO/IEC 25010 product quality model → items 16, 22, 27–29, 34
- RFC 7322 style guide, RFC 2119/8174 normative keywords → item 3 and the normative/informative rule
- NIST SSDF (SP 800-218) → item 29
- Test262 and W3C-style conformance suites → item 17

No single published standard contains exactly these 37 items in this order. The list is a synthesis; see `evidence.md` for citations.
