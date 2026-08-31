import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:aonw_server/src/auth/steam_open_id_verifier.dart';
import 'package:test/test.dart';

void main() {
  late HttpServer server;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  });

  tearDown(() => server.close(force: true));

  test('accepts a bounded valid Steam verification response', () async {
    final handled = server.first.then((request) async {
      final body = await utf8.decoder.bind(request).join();
      request.response.write('ns:http://specs.openid.net/auth/2.0\n');
      request.response.write('is_valid:true\n');
      await request.response.close();
      return (
        method: request.method,
        body: body,
        contentLength: request.contentLength,
        transferEncoding: request.headers.value('transfer-encoding'),
      );
    });

    final verified = await _verifier(
      server,
    ).verify({..._query, 'ignored': 'not-forwarded'});
    final request = await handled;

    expect(verified.valid, isTrue);
    expect(verified.diagnostic, 'valid');
    expect(request.method, 'POST');
    expect(request.contentLength, utf8.encode(request.body).length);
    expect(request.transferEncoding, isNull);
    expect(request.body, contains('openid.mode=check_authentication'));
    expect(request.body, contains('openid.claimed_id='));
    expect(request.body, isNot(contains('ignored')));
  });

  test('accepts a gzip-compressed Steam verification response', () async {
    final handled = server.first.then((request) async {
      await request.drain<void>();
      request.response.headers.set(HttpHeaders.contentEncodingHeader, 'gzip');
      request.response.add(gzip.encode(utf8.encode('is_valid:true\n')));
      await request.response.close();
    });

    final verified = await _verifier(server).verify(_query);

    expect(verified.valid, isTrue);
    expect(verified.diagnostic, 'valid');
    await handled;
  });

  test('rejects oversized verification requests before network I/O', () async {
    final verifier = SteamOpenIdVerifier(
      endpoint: _endpoint(server),
      maxRequestBytes: 32,
    );

    final verified = await verifier.verify({
      ..._query,
      'openid.sig': List.filled(128, 'x').join(),
    });

    expect(verified.valid, isFalse);
    expect(verified.diagnostic, 'request_too_large');
  });

  test('rejects oversized verification responses', () async {
    final handled = server.first.then((request) async {
      await request.drain<void>();
      request.response.write(List.filled(64, 'x').join());
      await request.response.close();
    });
    final verifier = SteamOpenIdVerifier(
      endpoint: _endpoint(server),
      maxResponseBytes: 32,
    );

    final verified = await verifier.verify(_query);
    expect(verified.valid, isFalse);
    expect(verified.diagnostic, 'response_too_large');
    await handled;
  });

  test('reports a non-success Steam response status', () async {
    final handled = server.first.then((request) async {
      await request.drain<void>();
      request.response.statusCode = HttpStatus.serviceUnavailable;
      await request.response.close();
    });

    final verified = await _verifier(server).verify(_query);

    expect(verified.valid, isFalse);
    expect(verified.diagnostic, 'http_status');
    expect(verified.httpStatus, HttpStatus.serviceUnavailable);
    await handled;
  });

  test(
    'fails closed when Steam does not respond before the deadline',
    () async {
      final handled = server.first.then((request) async {
        await request.drain<void>();
        await Future<void>.delayed(const Duration(milliseconds: 150));
        try {
          request.response.write('is_valid:true\n');
          await request.response.close();
        } on IOException {
          // The verifier force-closes the timed-out connection.
        }
      });
      final verifier = SteamOpenIdVerifier(
        endpoint: _endpoint(server),
        timeout: const Duration(milliseconds: 50),
      );

      final verified = await verifier.verify(_query);
      expect(verified.valid, isFalse);
      expect(verified.diagnostic, 'timeout');
      await handled;
    },
  );

  test('rejects a response from another OpenID operator before I/O', () async {
    final verified = await _verifier(server).verify({
      ..._query,
      'openid.op_endpoint': 'https://attacker.example/openid',
    });

    expect(verified.valid, isFalse);
    expect(verified.diagnostic, 'invalid_provider_response');
  });

  test('rejects mismatched claimed and identity values before I/O', () async {
    final verified = await _verifier(server).verify({
      ..._query,
      'openid.identity':
          'https://steamcommunity.com/openid/id/00000000000000000',
    });

    expect(verified.valid, isFalse);
    expect(verified.diagnostic, 'invalid_provider_response');
  });
}

SteamOpenIdVerifier _verifier(HttpServer server) {
  return SteamOpenIdVerifier(endpoint: _endpoint(server));
}

Uri _endpoint(HttpServer server) {
  return Uri.parse('http://${server.address.address}:${server.port}/openid');
}

const _query = <String, String>{
  'openid.ns': 'http://specs.openid.net/auth/2.0',
  'openid.mode': 'id_res',
  'openid.op_endpoint': 'https://steamcommunity.com/openid/login',
  'openid.claimed_id': 'https://steamcommunity.com/openid/id/12345678901234567',
  'openid.identity': 'https://steamcommunity.com/openid/id/12345678901234567',
  'openid.return_to': 'https://api.example/auth/steam/callback?requestId=test',
  'openid.response_nonce': '2026-07-10T10:00:00Znonce',
  'openid.assoc_handle': 'assoc',
  'openid.signed': 'signed-fields',
  'openid.sig': 'signature',
};
