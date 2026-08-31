import 'dart:io';

import 'package:test/test.dart';

import 'support/critical_e2e_loopback_io_overrides.dart';

void main() {
  group('critical E2E loopback IO overrides', () {
    final overrides = CriticalE2eLoopbackIoOverrides(basePort: 18080);

    test('maps wildcard IPv6 to IPv4 loopback for all three listeners', () {
      for (final port in [18080, 18081, 18082]) {
        final mappedAddress = overrides.validateAndMapServerSocketBindAddress(
          InternetAddress.anyIPv6,
          port,
          v6Only: false,
          shared: false,
        );

        expect(mappedAddress.address, InternetAddress.loopbackIPv4.address);
        expect(mappedAddress.type, InternetAddressType.IPv4);
        expect(mappedAddress.isLoopback, isTrue);
      }
    });

    final unsafeBinds =
        <({String name, Object? address, int port, bool v6Only, bool shared})>[
          (
            name: 'wildcard IPv4',
            address: InternetAddress.anyIPv4,
            port: 18080,
            v6Only: false,
            shared: false,
          ),
          (
            name: 'IPv6 loopback',
            address: InternetAddress.loopbackIPv6,
            port: 18080,
            v6Only: false,
            shared: false,
          ),
          (
            name: 'string address',
            address: InternetAddress.anyIPv6.address,
            port: 18080,
            v6Only: false,
            shared: false,
          ),
          (
            name: 'port below the listener range',
            address: InternetAddress.anyIPv6,
            port: 18079,
            v6Only: false,
            shared: false,
          ),
          (
            name: 'port above the listener range',
            address: InternetAddress.anyIPv6,
            port: 18083,
            v6Only: false,
            shared: false,
          ),
          (
            name: 'IPv6-only socket',
            address: InternetAddress.anyIPv6,
            port: 18080,
            v6Only: true,
            shared: false,
          ),
          (
            name: 'shared socket',
            address: InternetAddress.anyIPv6,
            port: 18080,
            v6Only: false,
            shared: true,
          ),
        ];

    for (final unsafe in unsafeBinds) {
      test('rejects ${unsafe.name}', () {
        expect(
          () => overrides.validateAndMapServerSocketBindAddress(
            unsafe.address,
            unsafe.port,
            v6Only: unsafe.v6Only,
            shared: unsafe.shared,
          ),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('Unsafe critical E2E server socket bind'),
            ),
          ),
        );
      });
    }

    test('uses the same validated critical E2E base-port range', () {
      expect(
        () => CriticalE2eLoopbackIoOverrides(basePort: 1023),
        throwsFormatException,
      );
      expect(
        () => CriticalE2eLoopbackIoOverrides(basePort: 65534),
        throwsFormatException,
      );
    });
  });
}
