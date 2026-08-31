import 'package:aonw_flutter/features/map/presentation/input/map_input.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/map_test_fixture.dart';

void main() {
  test('starts in the map center and keeps navigation inside bounds', () {
    final map = testMapScene(cols: 5, rows: 3).map;

    expect(MapInputCursor.initial(map), (col: 2, row: 1));
    expect(
      MapInputCursor.move(map, (col: 0, row: 0), MapInputCommand.cursorLeft),
      (col: 0, row: 0),
    );
    expect(
      MapInputCursor.move(map, (col: 2, row: 1), MapInputCommand.cursorUp),
      (col: 2, row: 0),
    );
    expect(
      MapInputCursor.move(map, (col: 2, row: 1), MapInputCommand.cursorRight),
      (col: 3, row: 1),
    );
  });
}
