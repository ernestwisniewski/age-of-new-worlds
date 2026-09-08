# Hex inspection reference vectors

The vectors were evaluated from `flame_4x` revision
`c6473641e57eb4337218234669c361db01c45d6e` before implementing the Rust query.
They cover every terrain, both river states, every individual resource, all
resources together and four mixed-resource precedence cases.

Regenerate from this repository with a configured reference checkout:

```sh
dart --packages=/path/to/flame_4x/.dart_tool/package_config.json tool/fixtures/generate_hex_inspection_reference.dart
```

The generator imports reference rules. Production code and CI do not depend on
that checkout. Rust tests compare the stored classification, scores,
recommendations and ordered tags for 980 cases, plus canonical base yields for
910 cases. River-only base terrain is invalid in canonical map content; the
remaining 70 reference cases therefore do not describe valid map yields.
Resource disclosure and state-dependent improvement access have separate tests.
