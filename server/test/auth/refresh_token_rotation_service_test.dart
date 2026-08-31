import 'dart:convert';

import 'package:aonw_server/src/auth/refresh_token_parser.dart';
import 'package:aonw_server/src/auth/refresh_token_rotation_service.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

void main() {
  test('parses a Serverpod JWT refresh-token id once for all consumers', () {
    final id = UuidValue.fromString('018f4f7a-6b5c-7d8e-9f01-23456789abcd');
    final encodedId = base64Encode(id.toBytes());

    final parsed = parseRefreshTokenId('sajrt:$encodedId:fixed:rotating');

    expect(parsed?.value, id);
    expect(parsed?.encoded, encodedId);

    expect(
      RefreshTokenRotationService.parseRefreshTokenId(
        'sajrt:$encodedId:fixed:rotating',
      ),
      id,
    );
    expect(
      RefreshTokenRotationService.parseRefreshTokenId('not-a-token'),
      isNull,
    );
    expect(
      RefreshTokenRotationService.parseRefreshTokenId(
        'sajrt:not-base64:fixed:rotating',
      ),
      isNull,
    );
  });
}
