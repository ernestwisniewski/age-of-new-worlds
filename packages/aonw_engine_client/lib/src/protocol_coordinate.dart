import 'package:aonw_engine_client/src/protocol_json.dart';

final class AonwCoordinate {
  const AonwCoordinate({required this.col, required this.row});

  factory AonwCoordinate.fromJson(Object? source) {
    final value = readObject(source, 'coordinate');
    requireKeys(value, const {'col', 'row'}, 'coordinate');
    return AonwCoordinate(
      col: readInt(value['col'], 'coordinate column'),
      row: readInt(value['row'], 'coordinate row'),
    );
  }

  final int col;
  final int row;
}
