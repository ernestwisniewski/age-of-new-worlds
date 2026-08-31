import 'package:aonw_engine_client/src/protocol_json.dart';
import 'package:aonw_engine_client/src/protocol_research_values.dart';

final class AonwPlayerResearchView {
  const AonwPlayerResearchView({
    required this.activeTechnology,
    required this.activeProgress,
    required this.activeEffectiveCost,
    required this.scienceOverflow,
    required this.scienceYield,
  });

  factory AonwPlayerResearchView.empty() => AonwPlayerResearchView(
    activeTechnology: null,
    activeProgress: null,
    activeEffectiveCost: null,
    scienceOverflow: 0,
    scienceYield: AonwScienceYieldBreakdown(
      total: 0,
      byCityId: const {},
      sources: const [],
    ),
  );

  factory AonwPlayerResearchView.fromJson(Object? source) {
    final value = readObject(source, 'player research view');
    requireKeys(value, const {
      'activeTechnologyId',
      'activeProgress',
      'activeEffectiveCost',
      'scienceOverflow',
      'scienceYield',
    }, 'player research view');
    return AonwPlayerResearchView(
      activeTechnology: value['activeTechnologyId'] == null
          ? null
          : AonwTechnologyId.fromJson(value['activeTechnologyId']),
      activeProgress: value['activeProgress'] == null
          ? null
          : readInt(value['activeProgress'], 'active research progress'),
      activeEffectiveCost: value['activeEffectiveCost'] == null
          ? null
          : readInt(
              value['activeEffectiveCost'],
              'active research effective cost',
            ),
      scienceOverflow: readInt(value['scienceOverflow'], 'science overflow'),
      scienceYield: AonwScienceYieldBreakdown.fromJson(value['scienceYield']),
    );
  }

  final AonwTechnologyId? activeTechnology;
  final int? activeProgress;
  final int? activeEffectiveCost;
  final int scienceOverflow;
  final AonwScienceYieldBreakdown scienceYield;
}
