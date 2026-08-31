import 'dart:async';
import 'dart:convert';
import 'dart:io';

abstract interface class SteamOpenIdVerification {
  Future<SteamOpenIdVerificationResult> verify(Map<String, String> query);
}

final class SteamOpenIdVerificationResult {
  const SteamOpenIdVerificationResult._({
    required this.valid,
    required this.diagnostic,
    this.httpStatus,
  });

  const SteamOpenIdVerificationResult.valid()
    : this._(valid: true, diagnostic: 'valid');

  const SteamOpenIdVerificationResult.rejected(
    String diagnostic, {
    int? httpStatus,
  }) : this._(valid: false, diagnostic: diagnostic, httpStatus: httpStatus);

  final bool valid;
  final String diagnostic;
  final int? httpStatus;
}

final class SteamOpenIdVerifier implements SteamOpenIdVerification {
  SteamOpenIdVerifier({
    Uri? endpoint,
    this.timeout = const Duration(seconds: 5),
    this.maxRequestBytes = 16 * 1024,
    this.maxResponseBytes = 4 * 1024,
  }) : assert(timeout > Duration.zero),
       assert(maxRequestBytes > 0),
       assert(maxResponseBytes > 0),
       endpoint = endpoint ?? steamEndpoint;

  static final Uri steamEndpoint = Uri.parse(
    'https://steamcommunity.com/openid/login',
  );

  final Uri endpoint;
  final Duration timeout;
  final int maxRequestBytes;
  final int maxResponseBytes;

  @override
  Future<SteamOpenIdVerificationResult> verify(
    Map<String, String> query,
  ) async {
    if (!_isSteamProviderResponse(query)) {
      return const SteamOpenIdVerificationResult.rejected(
        'invalid_provider_response',
      );
    }
    final body = utf8.encode(_verificationBody(query));
    if (body.length > maxRequestBytes) {
      return const SteamOpenIdVerificationResult.rejected('request_too_large');
    }

    final client = HttpClient()
      ..autoUncompress = true
      ..connectionTimeout = timeout;
    try {
      return await _exchange(client, body).timeout(timeout);
    } on TimeoutException {
      return const SteamOpenIdVerificationResult.rejected('timeout');
    } on IOException {
      return const SteamOpenIdVerificationResult.rejected('network_error');
    } on FormatException {
      return const SteamOpenIdVerificationResult.rejected(
        'invalid_response_encoding',
      );
    } finally {
      client.close(force: true);
    }
  }

  bool _isSteamProviderResponse(Map<String, String> query) {
    const namespace = 'http://specs.openid.net/auth/2.0';
    final claimedId = query['openid.claimed_id'];
    final identity = query['openid.identity'];
    return query['openid.ns'] == namespace &&
        query['openid.mode'] == 'id_res' &&
        query['openid.op_endpoint'] == steamEndpoint.toString() &&
        claimedId != null &&
        claimedId == identity &&
        _present(query, 'openid.return_to') &&
        _present(query, 'openid.response_nonce') &&
        _present(query, 'openid.assoc_handle') &&
        _present(query, 'openid.signed') &&
        _present(query, 'openid.sig');
  }

  bool _present(Map<String, String> query, String key) {
    return query[key]?.isNotEmpty ?? false;
  }

  Future<SteamOpenIdVerificationResult> _exchange(
    HttpClient client,
    List<int> body,
  ) async {
    final request = await client.postUrl(endpoint);
    request
      ..followRedirects = false
      ..headers.contentType = ContentType(
        'application',
        'x-www-form-urlencoded',
        charset: 'utf-8',
      )
      ..contentLength = body.length
      ..add(body);
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return SteamOpenIdVerificationResult.rejected(
        'http_status',
        httpStatus: response.statusCode,
      );
    }

    final bytes = <int>[];
    await for (final chunk in response) {
      if (bytes.length + chunk.length > maxResponseBytes) {
        return const SteamOpenIdVerificationResult.rejected(
          'response_too_large',
        );
      }
      bytes.addAll(chunk);
    }
    final responseBody = utf8.decode(bytes);
    final valid = responseBody
        .split('\n')
        .any((line) => line.trim() == 'is_valid:true');
    return valid
        ? const SteamOpenIdVerificationResult.valid()
        : const SteamOpenIdVerificationResult.rejected('provider_rejected');
  }

  String _verificationBody(Map<String, String> query) {
    final parameters = <String, String>{};
    for (final entry in query.entries) {
      if (entry.key.startsWith('openid.')) {
        parameters[entry.key] = entry.value;
      }
    }
    parameters['openid.mode'] = 'check_authentication';
    return Uri(queryParameters: parameters).query;
  }
}
