import 'package:aonw_server_client/aonw_server_client.dart';
import 'package:test/test.dart';

void main() {
  test('generated client protocol round-trips engine game requests', () {
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

    final command = GamePlayerCommandRequest(
      matchId: 'match-1',
      clientCommandId: 'command-1',
      commandJson:
          '{"type":"fortifyUnit","expectedRevision":3,"unitId":"unit-1"}',
    );
    final commandRoundTrip = Protocol().deserialize<GamePlayerCommandRequest>(
      command.toJson(),
    );
    expect(commandRoundTrip.matchId, 'match-1');
    expect(commandRoundTrip.clientCommandId, 'command-1');
    expect(commandRoundTrip.commandJson, contains('fortifyUnit'));
  });
}
