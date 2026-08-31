import '../../local_game/application/local_game_catalog.dart';

abstract interface class ReplayCapture {
  Future<void> captureReplay(LocalGameCatalogEntryView entry);
}
