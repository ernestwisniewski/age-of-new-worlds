import 'package:aonw_rust_client/aonw_rust_client.dart';

import '../read_model/player_map_view.dart';
import 'rust_game_session_context.dart';

typedef RustRequestSender =
    Future<AonwClientResponse> Function(
      AonwRustSession session,
      AonwClientRequest request,
    );
typedef RustPatchApplier =
    Future<PlayerMapView> Function(
      RustGameSessionContext context,
      AonwCommandResult command,
    );
