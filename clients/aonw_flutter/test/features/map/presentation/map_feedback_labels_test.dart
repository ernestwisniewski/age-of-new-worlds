import 'package:aonw_flutter/features/cities/read_model/city_view.dart';
import 'package:aonw_flutter/features/map/presentation/map_feedback_labels.dart';
import 'package:aonw_flutter/features/map/read_model/map_feedback_view.dart';
import 'package:aonw_flutter/features/map/read_model/pending_action_view.dart';
import 'package:aonw_flutter/l10n/generated/aonw_localizations_en.dart';
import 'package:aonw_flutter/l10n/generated/aonw_localizations_pl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'formats exact yields and all status messages in English and Polish',
    () {
      final cues = <MapFeedbackCueView>[
        _cue(
          0,
          const MapImprovementYieldTextView(
            improvement: FieldImprovementKind.farm,
            yieldDelta: YieldValueView(
              food: 2,
              production: 3,
              gold: 4,
              defense: 5,
            ),
          ),
        ),
        _cue(
          1,
          const MapImprovementYieldTextView(
            improvement: FieldImprovementKind.farm,
            yieldDelta: YieldValueView(
              food: 0,
              production: 0,
              gold: 0,
              defense: 0,
            ),
          ),
        ),
        for (final message in MapFeedbackMessageView.values)
          _cue(message.index + 2, MapMessageTextView(message)),
      ];
      final en = buildMapFeedbackLabels(cues, AonwLocalizationsEn());
      final pl = buildMapFeedbackLabels(cues, AonwLocalizationsPl());
      expect(
        [for (final cue in cues) en.labelFor(cue.identity)],
        [
          '+2 FOOD +3 PROD +4 GOLD +5 DEF',
          '+Farm',
          '+Road',
          'KO',
          'Retreat',
          'Excavate',
          'Artifact carried',
          'Artifact stored',
        ],
      );
      expect(
        [for (final cue in cues) pl.labelFor(cue.identity)],
        [
          '+2 ŻYW +3 PROD +4 ZŁ +5 DEF',
          '+Gospodarstwo',
          '+Droga',
          'KO',
          'Odwrót',
          'Wykop',
          'Artefakt przenoszony',
          'Artefakt w mieście',
        ],
      );
      expect(en.labelFor((revision: 5, eventIndex: 0)), isNull);
    },
  );
}

MapFloatingTextCueView _cue(int index, MapFeedbackTextView content) =>
    MapFloatingTextCueView(
      identity: (revision: 1, eventIndex: index),
      coordinate: (col: 0, row: 0),
      content: content,
      colorValue: 0xffffffff,
    );
