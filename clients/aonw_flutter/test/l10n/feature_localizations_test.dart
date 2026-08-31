import 'dart:convert';
import 'dart:io';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/features/artifacts/presentation/artifact_copy.dart';
import 'package:aonw_flutter/features/artifacts/read_model/artifact_view.dart';
import 'package:aonw_flutter/features/cities/presentation/city_copy.dart';
import 'package:aonw_flutter/features/cities/read_model/city_view.dart';
import 'package:aonw_flutter/features/diplomacy/read_model/diplomacy_view.dart';
import 'package:aonw_flutter/features/logistics/read_model/unit_logistics_view.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/pending_action_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/production/presentation/production_copy.dart';
import 'package:aonw_flutter/features/production/read_model/production_view.dart';
import 'package:aonw_flutter/features/research/presentation/research_copy.dart';
import 'package:aonw_flutter/features/research/read_model/research_view.dart';
import 'package:aonw_flutter/features/workers/presentation/worker_copy.dart';
import 'package:aonw_flutter/features/workers/read_model/worker_view.dart';
import 'package:aonw_flutter/l10n/generated/aonw_localizations.dart';
import 'package:aonw_flutter/l10n/generated/aonw_localizations_en.dart';
import 'package:aonw_flutter/l10n/generated/aonw_localizations_pl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final localizations = <AonwLocalizations>[
    AonwLocalizationsEn(),
    AonwLocalizationsPl(),
  ];

  test('every locale catalog has the complete template key set', () {
    final templateKeys = _messageKeys('lib/l10n/app_en.arb');
    final polishKeys = _messageKeys('lib/l10n/app_pl.arb');

    expect(polishKeys, templateKeys);
  });

  test('every feature copy key has an ARB translation', () {
    for (final l10n in localizations) {
      _expectSelectCases(
        CityText.values,
        localize: (value) => l10n.cityText(value.name),
        fallback: l10n.cityText('__missing__'),
        fallbackAllowedFor: const {'title'},
      );
      _expectSelectCases(
        WorkerText.values,
        localize: (value) => l10n.workerText(value.name),
        fallback: l10n.workerText('__missing__'),
        fallbackAllowedFor: const {'title'},
      );
      _expectSelectCases(
        ProductionText.values,
        localize: (value) => l10n.productionText(value.name),
        fallback: l10n.productionText('__missing__'),
      );
      _expectSelectCases(
        ArtifactText.values,
        localize: (value) => l10n.artifactText(value.name),
        fallback: l10n.artifactText('__missing__'),
      );
      _expectSelectCases(
        ResearchText.values,
        localize: (value) => l10n.researchText(value.name),
        fallback: l10n.researchText('__missing__'),
        fallbackAllowedFor: const {'title'},
      );
      _expectStringSelectCases(
        const {
          'open',
          'close',
          'noContacts',
          'compose',
          'target',
          'action',
          'send',
          'invalid',
          'pending',
          'relations',
          'proposals',
          'messages',
          'agreements',
          'accept',
          'reject',
          'amount',
          'goldPerTurn',
          'duration',
          'resource',
          'offered',
          'requested',
          'topic',
        },
        localize: l10n.diplomacyText,
        fallback: l10n.diplomacyText('__missing__'),
      );
    }
  });

  test('every current domain value used in copy has an ARB translation', () {
    for (final l10n in localizations) {
      _expectSelectCases(
        WorldArtifactKindView.values,
        localize: (value) => l10n.artifactName(value.name),
        fallback: l10n.artifactName('__missing__'),
      );
      _expectSelectCases(
        TechnologyIdView.values,
        localize: (value) => l10n.technologyName(value.name),
        fallback: l10n.technologyName('__missing__'),
      );
      _expectSelectCases(
        TechnologyAvailabilityView.values,
        localize: (value) => l10n.researchAvailability(value.name),
        fallback: l10n.researchAvailability('__missing__'),
      );
      _expectNamedCases(l10n, FieldImprovementKind.values);
      _expectNamedCases(l10n, MapResource.values);
      _expectNamedCases(l10n, VisibleUnitKind.values);
      _expectNamedCases(l10n, TechnologyUnlockKindView.values);
      _expectNamedCases(l10n, DiplomaticRelationStatusView.values);
      _expectNamedCases(l10n, DiplomaticMessageCategoryView.values);
      _expectNamedCases(l10n, DiplomaticMessageTopicView.values);
      _expectNamedCases(l10n, DiplomaticMessageResponseView.values);
      _expectNamedCases(l10n, LogisticsTroopKindView.values);
      _expectCityContentCases(l10n, AonwCityBuildingType.values);
      _expectCityContentCases(l10n, AonwCityProjectType.values);
      _expectCityContentCases(l10n, AonwWonderType.values);
      _expectCityContentCases(l10n, AonwCitySpecialization.values);
      _expectSelectCases(
        DiplomaticProposalKindView.values,
        localize: (value) => l10n.diplomaticProposalName(value.name),
        fallback: l10n.diplomaticProposalName('__missing__'),
      );
    }
  });

  test('every current engine rejection has localized copy', () {
    for (final l10n in localizations) {
      _expectFailureCases(
        CityRejectionCodeView.values,
        localize: (value) => l10n.cityFailure(value.name),
        fallback: l10n.cityFailure('__missing__'),
      );
      _expectFailureCases(
        WorkerRejectionCodeView.values,
        localize: (value) => l10n.workerFailure(value.name),
        fallback: l10n.workerFailure('__missing__'),
      );
      _expectFailureCases(
        ProductionRejectionCodeView.values,
        localize: (value) => l10n.productionFailure(value.name),
        fallback: l10n.productionFailure('__missing__'),
      );
      _expectFailureCases(
        ArtifactRejectionCodeView.values,
        localize: (value) => l10n.artifactFailure(value.name),
        fallback: l10n.artifactFailure('__missing__'),
      );
      _expectFailureCases(
        ResearchRejectionCodeView.values,
        localize: (value) => l10n.researchFailure(value.name),
        fallback: l10n.researchFailure('__missing__'),
      );
      _expectFailureCases(
        DiplomacyRejectionCodeView.values,
        localize: (value) => l10n.diplomacyFailure(value.name),
        fallback: l10n.diplomacyFailure('__missing__'),
      );
    }
  });
}

Set<String> _messageKeys(String path) {
  final catalog =
      jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
  return catalog.keys.where((key) => !key.startsWith('@')).toSet();
}

void _expectSelectCases<T extends Enum>(
  Iterable<T> values, {
  required String Function(T value) localize,
  required String fallback,
  Set<String> fallbackAllowedFor = const {},
}) {
  for (final value in values) {
    final copy = localize(value);
    expect(copy, isNotEmpty, reason: value.name);
    if (!fallbackAllowedFor.contains(value.name)) {
      expect(copy, isNot(fallback), reason: value.name);
    }
  }
}

void _expectStringSelectCases(
  Iterable<String> values, {
  required String Function(String value) localize,
  required String fallback,
}) {
  for (final value in values) {
    final copy = localize(value);
    expect(copy, isNotEmpty, reason: value);
    expect(copy, isNot(fallback), reason: value);
  }
}

void _expectNamedCases(AonwLocalizations l10n, Iterable<Enum> values) {
  final fallback = l10n.presentationName('__missing__');
  _expectSelectCases(
    values,
    localize: (value) => l10n.presentationName(value.name),
    fallback: fallback,
  );
}

void _expectCityContentCases(AonwLocalizations l10n, Iterable<Enum> values) {
  final fallback = l10n.cityContentName('__missing__');
  _expectSelectCases(
    values,
    localize: (value) => l10n.cityContentName(value.name),
    fallback: fallback,
  );
}

void _expectFailureCases<T extends Enum>(
  Iterable<T> values, {
  required String Function(T value) localize,
  required String fallback,
}) => _expectSelectCases(values, localize: localize, fallback: fallback);
