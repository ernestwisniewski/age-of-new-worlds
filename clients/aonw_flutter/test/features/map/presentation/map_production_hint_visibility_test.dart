import 'package:aonw_flutter/features/cities/application/city_state.dart';
import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_production_hint_visibility.dart';
import 'package:aonw_flutter/features/map/read_model/pending_action_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_production_test_fixture.dart';
import '../../../support/map_test_fixture.dart';

void main() {
  test(
    'suppresses map decisions while preserving ordinary city inspection',
    () {
      for (final interaction in [
        MapInteractionState(reachable: testReachableView()),
        MapInteractionState(route: testRoutePlanView()),
        const MapInteractionState(movementPending: true),
        const MapInteractionState(city: CityState.loadingFounding('settler')),
        const MapInteractionState(
          city: CityState.loadingCity(
            'city',
            managementMode: CityManagementMode.workedHexes,
          ),
        ),
        const MapInteractionState(
          city: CityState.loadingCity(
            'city',
            managementMode: CityManagementMode.expansion,
          ),
        ),
      ]) {
        expect(
          showMapProductionHints(productionSnapshot(interaction: interaction)),
          isFalse,
        );
      }
      expect(
        showMapProductionHints(
          productionSnapshot(
            interaction: const MapInteractionState(
              city: CityState.loadingCity('city'),
            ),
          ),
        ),
        isTrue,
      );
      expect(
        showMapProductionHints(
          productionSnapshot(
            pendingAction: const PendingResearchSelectionView(),
          ),
        ),
        isTrue,
      );
    },
  );
}
