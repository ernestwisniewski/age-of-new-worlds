# Security Policy

## Supported Versions

The public repository tracks active development on `main`. Security fixes are
handled there unless release branches are created later.

## Reporting A Vulnerability

Please do not open public issues for suspected vulnerabilities. Report security
concerns by email to `security@aonw.net` with:

- affected component or platform;
- steps to reproduce;
- impact and suggested severity;
- any logs, screenshots, or proof-of-concept details that can be shared safely.

Do not include real user passwords, tokens, private keys, or production data in
the report.

## Secret Handling

The repository should never contain real secrets. Keep these local and ignored:

- `.env` and other local environment files (all secrets, including OAuth, live here);
- signing keys, keystores, provisioning profiles, and service-account JSON;
- database backups and production logs.
