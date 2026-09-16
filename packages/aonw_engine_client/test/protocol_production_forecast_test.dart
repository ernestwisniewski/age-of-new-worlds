import 'dart:convert';
import 'dart:io';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:test/test.dart';

void main() {
  test('production metadata matches the shared Rust fixture', () {
    final response =
        AonwClientResponse.parse(
              File(
                '../../tests/fixtures/client_protocol/production_options_response.json',
              ).readAsStringSync(),
            ).require<AonwQueryResponse>().result
            as AonwProductionOptionsResult;
    expect(response.buildings.single.forecast.estimatedTurns, 4);
    expect(response.units.single.option.forecast.productionPerTurn, 3);
    expect(response.projects.single.forecast.projectOutput, 1);
    expect(response.projects.single.forecast.estimatedTurns, isNull);
    expect(
      response.rushQuote.rejection,
      AonwCommandRejectionCode.projectCannotBeRushed,
    );
  });

  test(
    'forecasts and rush quotes require every field including nullable values',
    () {
      for (final (data, parse) in [
        (_forecast, AonwProductionForecast.fromJson),
        (_quote, AonwProductionRushQuote.fromJson),
      ]) {
        for (final field in data.keys) {
          final missing = {...data}..remove(field);
          expect(() => parse(missing), throwsFormatException, reason: field);
        }
        expect(
          () => parse({...data, 'opponentGold': 500}),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'forecast numeric values reject negative, fractional and mistyped input',
    () {
      for (final field in [
        'investedProduction',
        'productionPerTurn',
        'estimatedTurns',
        'projectOutput',
      ]) {
        for (final invalid in [-1, 1.5, '3', true]) {
          expect(
            () =>
                AonwProductionForecast.fromJson({..._forecast, field: invalid}),
            throwsFormatException,
          );
        }
      }
      for (final field in ['production', 'goldCost']) {
        expect(
          () => AonwProductionRushQuote.fromJson({..._quote, field: -1}),
          throwsFormatException,
        );
      }
      expect(
        () =>
            AonwProductionForecast.fromJson({..._forecast, 'spawnBlocked': 0}),
        throwsFormatException,
      );
    },
  );

  test(
    'unaffordable quotes preserve exact amounts without deriving a price',
    () {
      final quote = AonwProductionRushQuote.fromJson(
        jsonDecode('''
      {"production":7,"goldCost":19,"rejection":"rush_production_unavailable"}
    '''),
      );
      expect(quote.production, 7);
      expect(quote.goldCost, 19);
      expect(
        quote.rejection,
        AonwCommandRejectionCode.rushProductionUnavailable,
      );
    },
  );
}

const _forecast = <String, Object?>{
  'investedProduction': 4,
  'productionPerTurn': 3,
  'estimatedTurns': null,
  'projectOutput': null,
  'spawnBlocked': false,
};
const _quote = <String, Object?>{
  'production': 3,
  'goldCost': 6,
  'rejection': null,
};
