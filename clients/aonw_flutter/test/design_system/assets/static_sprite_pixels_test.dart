import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/static_sprite_pixels.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'static atlas partitions preserve original pixels and geometry',
    () async {
      final expected =
          jsonDecode(
                File(
                  '../../docs/parity/static-sprite-pixels.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      expect(await readStaticSpritePixels(), expected['pixels']);
    },
  );
}
