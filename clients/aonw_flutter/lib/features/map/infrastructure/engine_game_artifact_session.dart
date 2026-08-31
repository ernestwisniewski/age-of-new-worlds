part of 'engine_game_session_gateway.dart';

final class _EngineGameArtifactSession implements ArtifactSessionPort {
  const _EngineGameArtifactSession(this._owner);

  final EngineGameSessionGateway _owner;

  @override
  Future<ArtifactCommandResultView> executeArtifactAction({
    required int expectedRevision,
    required ArtifactActionView action,
  }) => _owner._serialize(
    () => _owner._artifactGateway.execute(
      readContext: _owner._context,
      expectedRevision: expectedRevision,
      action: action,
      send: _owner._send,
      applyPatch: _owner._applyCommandPatch,
    ),
  );
}
