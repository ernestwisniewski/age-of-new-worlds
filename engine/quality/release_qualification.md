# Rust Engine Release Qualification

- Branch: `dev`
- Purpose: release qualification evidence
- Required commit scope: complete E0-PS11 engine, stable client/native contract,
  quality and supply-chain policies
- Required workflows on one commit: CI, Dependency Vulnerability Scan,
  Rust Engine Deep Checks, Rust Engine Security Checks

Changing this file explicitly dispatches the expensive release qualification
workflows. Routine engine commits do not touch it and therefore do not start
mutation, fuzz, Miri, sanitizer, or release-metadata jobs. Use each workflow's
manual dispatch for ad hoc verification.
