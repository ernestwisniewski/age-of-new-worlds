import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/app/composition/app_composition.dart';
import 'package:aonw_flutter/features/multiplayer/infrastructure/auth_token_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'engine inspects the packaged starter through the native adapter',
    (tester) async {
      expect(aonwEngineClientAvailable, isTrue);
      final session = await createAonwEngineSession();
      expect(session, isNotNull);
      addTearDown(session!.close);

      final document = await rootBundle.loadString(
        'assets/maps/aonw2_starter/map.json',
      );
      final response = await session.send(
        AonwClientRequest.inspectMap(mapDocument: document),
      );
      final map = response.require<AonwMapInspectedResponse>().map;
      expect(map.mapId, 'aonw2_starter');
      expect(map.tiles, hasLength(49));
      expect(map.gridLayout, AonwMapGridLayout.oddQFlatTop);
    },
  );

  testWidgets('standalone app starts at the production main menu', (
    tester,
  ) async {
    await tester.pumpWidget(AppComposition.production().root);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('new-game')), findsOneWidget);
    expect(find.byKey(const ValueKey('multiplayer')), findsOneWidget);
  });

  testWidgets('secure token storage persists and removes one isolated value', (
    tester,
  ) async {
    final key =
        'aonw.test.refresh-token.'
        '${DateTime.now().toUtc().microsecondsSinceEpoch}';
    final store = SecureAuthTokenStore(refreshTokenKey: key);
    addTearDown(store.clear);

    await store.writeRefreshToken('integration-token');
    expect(await store.readRefreshToken(), 'integration-token');
    await store.clear();
    expect(await store.readRefreshToken(), isNull);
  });
}
