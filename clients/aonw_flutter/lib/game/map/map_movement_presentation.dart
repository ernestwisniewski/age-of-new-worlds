/// A movement can wait for presentation preparation without advancing its path.
/// Interruption releases preparation but never changes the authoritative result.
abstract interface class MapMovementPresentation {
  bool get ready;
  void complete({required bool interrupted});
}
