import 'dart:io';

import 'critical_e2e_server_config.dart';

final class CriticalE2eLoopbackIoOverrides extends IOOverrides {
  CriticalE2eLoopbackIoOverrides({required int basePort})
    : _basePort = parseCriticalE2eBasePort(basePort.toString());

  final int _basePort;

  InternetAddress validateAndMapServerSocketBindAddress(
    Object? address,
    int port, {
    required bool v6Only,
    required bool shared,
  }) {
    final isExpectedWildcard =
        address is InternetAddress &&
        address.type == InternetAddressType.IPv6 &&
        address.address == InternetAddress.anyIPv6.address;
    final isExpectedPort =
        port == _basePort || port == _basePort + 1 || port == _basePort + 2;

    if (!isExpectedWildcard || !isExpectedPort || v6Only || shared) {
      throw StateError(
        'Unsafe critical E2E server socket bind: expected wildcard IPv6 on '
        'ports $_basePort, ${_basePort + 1}, or ${_basePort + 2} with '
        'v6Only=false and shared=false; got $address:$port with '
        'v6Only=$v6Only and shared=$shared.',
      );
    }

    return InternetAddress.loopbackIPv4;
  }

  @override
  Future<ServerSocket> serverSocketBind(
    dynamic address,
    int port, {
    int backlog = 0,
    bool v6Only = false,
    bool shared = false,
  }) {
    final mappedAddress = validateAndMapServerSocketBindAddress(
      address,
      port,
      v6Only: v6Only,
      shared: shared,
    );
    return super.serverSocketBind(
      mappedAddress,
      port,
      backlog: backlog,
      v6Only: false,
      shared: false,
    );
  }
}
