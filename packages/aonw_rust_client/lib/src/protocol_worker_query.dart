part of 'protocol_query.dart';

final class AonwWorkerOptionsResult extends AonwQueryResult {
  AonwWorkerOptionsResult({
    required this.stamp,
    required this.unitId,
    required this.coordinate,
    required List<AonwWorkerImprovementOption> improvements,
    required this.canAssign,
    required this.canBuildRoad,
    required this.automation,
  }) : improvements = List.unmodifiable(improvements);

  factory AonwWorkerOptionsResult.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'stamp',
      'unitId',
      'coordinate',
      'improvements',
      'canAssign',
      'canBuildRoad',
      'automation',
    }, 'worker options');
    return AonwWorkerOptionsResult(
      stamp: AonwSessionStamp.fromJson(value['stamp']),
      unitId: readString(value['unitId'], 'worker options unit id'),
      coordinate: AonwCoordinate.fromJson(value['coordinate']),
      improvements: readList(
        value['improvements'],
        'worker improvement options',
        (item, _) => AonwWorkerImprovementOption.fromJson(item),
      ),
      canAssign: readBool(value['canAssign'], 'worker assignment option'),
      canBuildRoad: readBool(value['canBuildRoad'], 'worker road option'),
      automation: value['automation'] == null
          ? null
          : AonwWorkerAutomationOption.fromJson(value['automation']),
    );
  }

  final AonwSessionStamp stamp;
  final String unitId;
  final AonwCoordinate coordinate;
  final List<AonwWorkerImprovementOption> improvements;
  final bool canAssign;
  final bool canBuildRoad;
  final AonwWorkerAutomationOption? automation;
}

final class AonwWorkerImprovementOption {
  const AonwWorkerImprovementOption({
    required this.improvement,
    required this.buildTurns,
  });

  factory AonwWorkerImprovementOption.fromJson(Object? source) {
    final value = readObject(source, 'worker improvement option');
    requireKeys(value, const {
      'improvement',
      'buildTurns',
    }, 'worker improvement option');
    return AonwWorkerImprovementOption(
      improvement: AonwFieldImprovementKind.fromJson(value['improvement']),
      buildTurns: readUnsigned(value['buildTurns'], 'worker build turns'),
    );
  }

  final AonwFieldImprovementKind improvement;
  final int buildTurns;
}
