import 'package:serverpod/serverpod.dart';

/// Resolves the network identity used by authentication rate-limit buckets.
///
/// Proxy headers are trusted only because production ingress keeps Serverpod
/// ports private. The bundled Caddy configuration removes client-supplied
/// identity headers and lets Caddy rebuild `X-Forwarded-For`. Cloudflare Tunnel
/// reaches Serverpod over the private Docker network and supplies the canonical
/// `CF-Connecting-IP` header.
final class AuthRateLimitClientIdentityResolver {
  const AuthRateLimitClientIdentityResolver();

  static const _cloudflareConnectingIpHeader = 'cf-connecting-ip';

  String resolve(Request? request) {
    if (request == null) return 'unknown';

    final socketIp = request.connectionInfo.remote.address.toString();
    final cloudflareValues = request.headers[_cloudflareConnectingIpHeader];
    if (cloudflareValues != null) {
      return _singleIpHeader(cloudflareValues) ?? socketIp;
    }

    final forwardedValues = request.headers[Headers.xForwardedForHeader];
    if (forwardedValues != null) {
      return _firstIpHeader(forwardedValues) ?? socketIp;
    }

    return socketIp;
  }

  String? _singleIpHeader(Iterable<String> values) {
    if (values.length != 1) return null;

    final value = values.single.trim();
    if (value.contains(',')) return null;
    return _canonicalIp(value);
  }

  String? _firstIpHeader(Iterable<String> values) {
    for (final value in values) {
      final first = value.split(',').first.trim();
      return _canonicalIp(first);
    }
    return null;
  }

  String? _canonicalIp(String value) {
    if (value.isEmpty || value.contains('/')) return null;
    try {
      return IPAddress.parse(value).toString();
    } on FormatException {
      return null;
    }
  }
}
