import 'package:aonw_flutter/design_system/assets/sprite_frame_id.dart';
import 'package:aonw_flutter/design_system/assets/sprite_frames.dart';
import 'package:aonw_flutter/features/research/read_model/research_view.dart';
import 'package:aonw_flutter/l10n/generated/aonw_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'every technology has a decoded illustration and six descriptions',
    () async {
      final scope = SpriteFrames.createScope();
      addTearDown(scope.dispose);
      for (final technology in TechnologyIdView.values) {
        final frame = await scope.load(
          SpriteFrameId('technology.${technology.name}'),
        );
        expect(frame.source.isEmpty, isFalse);
        for (final locale in AonwLocalizations.supportedLocales) {
          final l10n = lookupAonwLocalizations(locale);
          expect(
            l10n.technologyDescription(technology.name),
            isNotEmpty,
            reason: '$locale ${technology.name}',
          );
        }
      }
      expect(SpriteFrames.debugAtlasBytes.keys, ['technologies']);
    },
  );
}
