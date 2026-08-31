import 'package:aonw_server/src/auth/auth_rate_limit_client_identity.dart';
import 'package:aonw_server/src/auth/auth_rate_limiter.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

void main() {
  const resolver = AuthRateLimitClientIdentityResolver();

  test('prefers the canonical Cloudflare client address', () {
    final request = _request(
      headers: const {
        'cf-connecting-ip': ['203.0.113.7'],
        'x-forwarded-for': ['198.51.100.8, 10.0.0.2'],
      },
    );

    expect(resolver.resolve(request), '203.0.113.7');
  });

  test('uses the first address from sanitized X-Forwarded-For', () {
    final firstRequest = _request(
      headers: const {
        'x-forwarded-for': ['198.51.100.8, 10.0.0.2'],
      },
    );
    final secondRequest = _request(
      headers: const {
        'x-forwarded-for': ['198.51.100.9, 10.0.0.2'],
      },
    );

    expect(resolver.resolve(firstRequest), '198.51.100.8');
    expect(resolver.resolve(secondRequest), '198.51.100.9');
    expect(
      resolver.resolve(firstRequest),
      isNot(resolver.resolve(secondRequest)),
    );

    final limiter = DatabaseAuthRateLimiter();
    expect(
      limiter.ipNonceFor(firstRequest, pepper: 'test-pepper'),
      isNot(limiter.ipNonceFor(secondRequest, pepper: 'test-pepper')),
    );
  });

  test('falls back to the socket address without proxy headers', () {
    expect(resolver.resolve(_request(socketIp: '192.0.2.14')), '192.0.2.14');
  });

  test('does not trust the client-supplied Forwarded header', () {
    final request = _request(
      headers: const {
        'forwarded': ['for=203.0.113.7'],
      },
      socketIp: '192.0.2.15',
    );

    expect(resolver.resolve(request), '192.0.2.15');
  });

  test('fails closed to the socket address for malformed proxy identity', () {
    final malformedCloudflare = _request(
      headers: const {
        'cf-connecting-ip': ['not-an-ip'],
        'x-forwarded-for': ['198.51.100.8'],
      },
      socketIp: '192.0.2.15',
    );
    final malformedForwardedFor = _request(
      headers: const {
        'x-forwarded-for': ['not-an-ip, 10.0.0.2'],
      },
      socketIp: '192.0.2.16',
    );
    final ambiguousCloudflare = _request(
      headers: const {
        'cf-connecting-ip': ['203.0.113.7', '203.0.113.8'],
      },
      socketIp: '192.0.2.17',
    );

    expect(resolver.resolve(malformedCloudflare), '192.0.2.15');
    expect(resolver.resolve(malformedForwardedFor), '192.0.2.16');
    expect(resolver.resolve(ambiguousCloudflare), '192.0.2.17');
  });

  test('uses stable fallback when no HTTP request is available', () {
    expect(resolver.resolve(null), 'unknown');
  });
}

Request _request({
  Map<String, Iterable<String>> headers = const {},
  String socketIp = '127.0.0.1',
}) {
  return RequestInternal.create(
    Method.post,
    Uri.parse('http://localhost/auth'),
    Object(),
    headers: Headers.fromMap(headers),
    connectionInfo: ConnectionInfo(
      remote: SocketAddress(address: IPAddress.parse(socketIp), port: 12345),
      localPort: 8080,
    ),
  );
}
