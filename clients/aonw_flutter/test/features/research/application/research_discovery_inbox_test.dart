import 'package:aonw_flutter/features/research/application/research_discovery_inbox.dart';
import 'package:flutter_test/flutter_test.dart';

import '../discovery_fixture.dart';

void main() {
  test(
    'queues coalesced completion once and retains minimized acknowledgement',
    () {
      final inbox = ResearchDiscoveryInbox();
      final session = Object();
      inbox.observe(discoveryPlayer(), session: session, enabled: true);
      final player = discoveryPlayer(
        revision: 2,
        discoveries: [firstDiscovery, secondDiscovery],
      );
      inbox.observe(player, session: session, enabled: true);
      expect(inbox.current, firstDiscovery);
      inbox.minimized = true;
      inbox.observe(player, session: session, enabled: true);
      expect(inbox.minimized, isTrue);
      inbox.dismiss();
      expect(inbox.current, secondDiscovery);
      expect(inbox.minimized, isFalse);
      inbox.dismiss();
      inbox.observe(player, session: session, enabled: true);
      expect(inbox.current, isNull);
    },
  );
  test(
    'opening, seeking, recipient change and resync never replay old popups',
    () {
      final inbox = ResearchDiscoveryInbox();
      final session = Object();
      final player = discoveryPlayer(
        revision: 1,
        discoveries: [firstDiscovery],
      );
      inbox.observe(player, session: session, enabled: true);
      expect(inbox.current, isNull);
      inbox.observe(
        discoveryPlayer(
          revision: 2,
          discoveries: [firstDiscovery, secondDiscovery],
        ),
        session: session,
        enabled: true,
      );
      expect(inbox.current, secondDiscovery);
      inbox.observe(player, session: session, enabled: true);
      expect(inbox.current, isNull);
      inbox.observe(
        discoveryPlayer(
          revision: 2,
          actor: 'other',
          discoveries: [secondDiscovery],
        ),
        session: session,
        enabled: true,
      );
      expect(inbox.current, isNull);
      inbox.observe(
        discoveryPlayer(revision: 3),
        session: session,
        enabled: true,
      );
      expect(inbox.current, isNull);
    },
  );
  test('suppressed discoveries do not reappear after enabling', () {
    final inbox = ResearchDiscoveryInbox();
    final session = Object();
    inbox.observe(discoveryPlayer(), session: session, enabled: true);
    final player = discoveryPlayer(revision: 1, discoveries: [firstDiscovery]);
    inbox.observe(player, session: session, enabled: false);
    inbox.observe(player, session: session, enabled: true);
    expect(inbox.current, isNull);
  });
}
