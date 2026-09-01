part of 'map_coordinator_save_test.dart';

final class _ReplayCapture implements ReplayCapture {
  final entries = <LocalGameCatalogEntryView>[];

  @override
  Future<void> captureReplay(LocalGameCatalogEntryView entry) async {
    entries.add(entry);
  }
}
