# Engineering Artifacts

Extract these wherever the technology has them. They are the difference between a dossier someone can read and a dossier someone can build from. Prose describing a binary format is not the same thing as a table of offsets.

Add bullets here when a needed artifact type is missing. Log the change in `CHANGELOG.md`.

## Structure and semantics

- **Formal grammar** in EBNF or ABNF for any language or text format. Not a prose description of the syntax — the actual production rules, because that is what a parser is written against.
- **State machines** for any protocol or lifecycle: states, events, transitions, terminal states, and what happens on an unexpected event in each state.
- **Byte-level format tables** for any binary format: offset, width, type, endianness, meaning, and whether the field is required. Include magic numbers and version fields.
- **Typing rules or validation rules** where the technology defines them formally.

## Interface contracts

- **API signatures** with parameter types, return types, and the full error or exception set. Note which errors are recoverable.
- **Error contracts**: what the caller can rely on when something fails — is state rolled back, is the connection dead, is retry safe.
- **Extension and plugin points**, with the stability contract around each: is this ABI-stable, API-stable, or explicitly internal.
- **Stability guarantees**: which parts of the surface are covered by the versioning policy and which can change without notice.

## Testability

- **Invariants and pre/post-conditions**, phrased so they can become property-based tests directly. "Parsing then re-serialising yields identical bytes" is usable; "the parser is correct" is not.
- **Test oracle definitions** — how does a test decide an output is right? Options: diff against a reference implementation, check an invariant, round-trip property, golden file, formal semantics.
- **Conformance suite** name, URL, what it covers, what it does not cover, and the commands to run it.
- **Reference implementation** name and URL, plus how it relates to the spec — is it normative, or just one implementation among several.
- **Fuzzing surface**: entry points that accept untrusted input, a grammar or seed corpus description, and known crash classes.
- **Environment matrix** as an actual table: OS, architecture, runtime version, dependency versions, and the cells where behaviour legitimately differs.
- **Fault-injection points**: the list of things that can fail underneath it and how to make each fail on demand.

## Code

Minimal **working** examples, each labelled with language and version. Three at minimum, one per build class:

1. One that **uses** it — the most common operation.
2. One that **inspects or parses** it — reading it as data.
3. One that **tests** it — asserting a property or running a conformance case.

Minimal means it runs as written, with no elided setup. If setup is unavoidable, include it. An example with `# ... configure client here ...` in the middle is not an example.

Label untested code as untested. Do not present code you could not run as though it were verified.
