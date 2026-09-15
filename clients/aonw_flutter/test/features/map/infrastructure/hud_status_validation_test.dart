import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/features/map/infrastructure/recipient_hud_status_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cultural HUD status cannot name a different recipient', () {
    const status = AonwVictoryStatus(
      kind: AonwVictoryStatusKind.culture,
      critical: true,
      leaderPlayerId: 'owner',
    );
    expect(
      () => validateVictoryStatusRecipient(status, 'owner'),
      returnsNormally,
    );
    expect(
      () => validateVictoryStatusRecipient(status, 'observer'),
      throwsFormatException,
    );
  });

  test('shortages must be unique ordered stockpile resource kinds', () {
    expect(
      () => validateStrategicShortages([
        AonwResourceType.oil,
        AonwResourceType.aluminium,
      ]),
      returnsNormally,
    );
    for (final resources in [
      [AonwResourceType.oil, AonwResourceType.oil],
      [AonwResourceType.aluminium, AonwResourceType.oil],
      [AonwResourceType.wheat],
    ]) {
      expect(
        () => validateStrategicShortages(resources),
        throwsFormatException,
      );
    }
  });
}
