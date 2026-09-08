import 'dart:convert';
import 'dart:io';
import 'package:aonw/game/domain/hex_assessment.dart';
import 'package:aonw_core/game/domain/hex_assessment/hex_assessment_input.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

void main() {
  final resourceSets = <List<ResourceType>>[
    [],
    for (final resource in ResourceType.values) [resource],
    ResourceType.values,
    [ResourceType.wheat, ResourceType.gold, ResourceType.iron],
    [ResourceType.deer, ResourceType.coal],
    [ResourceType.banana, ResourceType.oil],
    [ResourceType.fish, ResourceType.pearls],
  ];
  final rows = <Object>[];
  for (final terrain in TerrainType.values) {
    for (final river in [false, true]) {
      for (final resources in resourceSets) {
        final value = HexAssessmentRules.assessInput(
          HexAssessmentInput(
            baseTerrain: terrain,
            hasRiver: river,
            resources: resources,
            height: 0,
          ),
        );
        rows.add({
          'terrain': terrain.name,
          'river': river,
          'resources': resources.map((r) => r.name).toList(),
          'kind': value.kind.name,
          'recommendation': value.recommendation.name,
          'score': [value.score.city, value.score.defense, value.score.economy],
          'yield': [
            value.yield.food,
            value.yield.production,
            value.yield.gold,
            value.yield.defense,
          ],
          'canFound': value.canFoundCity,
          'tags': value.tags.map((t) => t.name).toList(),
        });
      }
    }
  }
  stdout.writeln(jsonEncode(rows));
}
