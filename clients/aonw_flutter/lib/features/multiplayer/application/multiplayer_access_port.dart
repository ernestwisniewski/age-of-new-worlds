enum MultiplayerAccessStatus { current, updateRequired }

abstract interface class MultiplayerAccessPort {
  Future<MultiplayerAccessStatus> check();
}
