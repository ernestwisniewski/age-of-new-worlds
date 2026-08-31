part of 'rust_game_session_gateway.dart';

final class _RustGameArtifactSession implements ArtifactSessionPort {
  const _RustGameArtifactSession(this._owner);

  final RustGameSessionGateway _owner;

  @override
  Future<ArtifactCommandResultView> executeArtifactAction({
    required int expectedRevision,
    required ArtifactActionView action,
  }) => _owner._serialize(
    () => _owner._artifactGateway.execute(
      context: _owner._context(),
      expectedRevision: expectedRevision,
      action: action,
      send: RustGameSessionGateway._send,
      applyPatch: _owner._applyCommandPatch,
    ),
  );
}
