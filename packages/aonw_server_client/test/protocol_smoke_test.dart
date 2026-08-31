import 'package:aonw_server_client/aonw_server_client.dart';
import 'package:test/test.dart';

void main() {
  test('generated client protocol round-trips Rust game requests', () {
    final request = GameCreateMatchRequest(
      mapId: 'myranth',
      mapDocument: '{"schemaVersion":1}',
      scenarioDocument: '{"schemaVersion":1}',
      rulesetId: 'aonw-standard',
      matchIdentityJson: '{"gameMode":"multiplayer"}',
      fogEnabled: true,
      creatorPlayerId: 'player-1',
    );

    final roundTrip = Protocol().deserialize<GameCreateMatchRequest>(
      request.toJson(),
    );

    expect(roundTrip.mapId, 'myranth');
    expect(roundTrip.rulesetId, 'aonw-standard');
    expect(roundTrip.fogEnabled, isTrue);
    expect(roundTrip.creatorPlayerId, 'player-1');
  });
}
