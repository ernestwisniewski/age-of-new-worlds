import 'package:aonw_flutter/features/map/application/map_session_port.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';

final class CountingMapSession implements MapSessionPort {
  CountingMapSession(this.delegate);
  final MapSessionPort delegate;
  var loadCalls = 0;

  @override
  Future<MapScene> load(MapAssetPaths assets) {
    loadCalls++;
    return delegate.load(assets);
  }

  @override
  Future<void> close() => delegate.close();
}
