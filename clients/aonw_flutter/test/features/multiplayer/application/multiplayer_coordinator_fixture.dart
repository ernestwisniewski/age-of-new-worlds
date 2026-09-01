part of 'multiplayer_coordinator_test.dart';

MultiplayerCoordinator _coordinator(_Session session) => MultiplayerCoordinator(
  session: session,
  documents: const _Documents(),
  secureRandom: Random(7),
);

const _account = MultiplayerAccountView(userId: 'account-1');

final class _Documents implements MultiplayerMatchDocumentSource {
  const _Documents();

  @override
  Future<MultiplayerMatchDocuments> load(
    MultiplayerMatchSetupView setup,
  ) async => const MultiplayerMatchDocuments(
    mapId: 'map-1',
    mapDocument: '{}',
    scenarioDocument: '{}',
    rulesetId: 'ruleset-1',
    matchIdentityDocument: '{}',
    fogEnabled: true,
    creatorPlayerId: 'player-1',
  );
}
