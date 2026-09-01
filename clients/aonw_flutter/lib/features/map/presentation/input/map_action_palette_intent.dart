import '../../read_model/pending_action_view.dart';

sealed class MapActionPaletteIntent {
  const MapActionPaletteIntent();
}

final class ConfirmMapMovePaletteIntent extends MapActionPaletteIntent {
  const ConfirmMapMovePaletteIntent();
}

sealed class MapWorkerImprovementPaletteIntent extends MapActionPaletteIntent {
  const MapWorkerImprovementPaletteIntent({
    required this.unitId,
    required this.improvement,
  });

  final String unitId;
  final FieldImprovementKind improvement;
}

final class PreviewWorkerImprovementPaletteIntent
    extends MapWorkerImprovementPaletteIntent {
  const PreviewWorkerImprovementPaletteIntent({
    required super.unitId,
    required super.improvement,
  });
}

final class ConfirmWorkerImprovementPaletteIntent
    extends MapWorkerImprovementPaletteIntent {
  const ConfirmWorkerImprovementPaletteIntent({
    required super.unitId,
    required super.improvement,
  });
}

typedef MapActionPaletteIntentSink =
    void Function(MapActionPaletteIntent intent);
