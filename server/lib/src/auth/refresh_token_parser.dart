import 'dart:convert';

import 'package:serverpod/serverpod.dart';

/// The non-secret identifier carried by a Serverpod JWT refresh token.
final class ParsedRefreshTokenId {
  const ParsedRefreshTokenId({required this.value, required this.encoded});

  final UuidValue value;
  final String encoded;
}

/// Parses the identifier shared by all secrets in a Serverpod JWT refresh
/// token.
///
/// Keeping format recognition here prevents authentication controls from
/// assigning malformed tokens to a credential bucket that token rotation
/// would reject.
ParsedRefreshTokenId? parseRefreshTokenId(String refreshToken) {
  try {
    final parts = refreshToken.split(':');
    if (parts.length != 4 || parts.first != 'sajrt') return null;
    return ParsedRefreshTokenId(
      value: UuidValue.fromByteList(base64Decode(parts[1])),
      encoded: parts[1],
    );
  } catch (_) {
    return null;
  }
}
