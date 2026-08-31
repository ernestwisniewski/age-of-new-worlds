# Flutter client privacy and diagnostics

The client sends account credentials only to the configured HTTPS Serverpod origin.
It stores only the rotating refresh token in the macOS Keychain; access tokens stay
in process memory. Sign-out revokes the refresh token at the server and removes the
local Keychain entry. Game responses are strict recipient projections and are
rejected if they expose an unexpected envelope or field.

Process-level Flutter failures are written locally as bounded JSON Lines in the
application support directory. A record contains UTC time, failure category, Dart
runtime type, and at most 16 KiB of stack trace. It deliberately omits the error
message, request/response bodies, account identifiers, email addresses, tokens, map
documents, chat, and social data. The active file is capped at 512 KiB with one
previous file retained. Reports are not uploaded automatically.

Debug lifecycle telemetry contains only fixed event codes. There is no analytics,
advertising identifier, chat capture, social graph capture, or background upload.
Any future remote diagnostics service requires a separate privacy review, explicit
retention policy, user-facing disclosure, redaction tests, and an opt-out path before
it enters the production composition.
