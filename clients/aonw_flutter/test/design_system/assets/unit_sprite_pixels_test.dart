import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/unit_sprite_pixels.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('unit atlas packing preserves every original logical pixel', () async {
    final expected =
        jsonDecode(
              File(
                '../../docs/parity/unit-sprite-pixels.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    expect(await readUnitSpritePixels(), expected['pixels']);
  });
}
