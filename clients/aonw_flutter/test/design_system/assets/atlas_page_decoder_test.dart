import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:aonw_flutter/design_system/assets/atlas_page_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'releases the encoded buffer while leaving decoded pixels usable',
    () async {
      final original = await createTestImage(width: 3, height: 2, cache: false);
      addTearDown(original.dispose);
      final png = (await original.toByteData(format: ui.ImageByteFormat.png))!;
      final buffer = await ui.ImmutableBuffer.fromUint8List(
        png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes),
      );
      final decoded = await decodeAtlasPage(buffer);
      addTearDown(decoded.dispose);
      expect(buffer.debugDisposed, isTrue);
      expect(decoded.width, 3);
      expect(decoded.height, 2);
      expect(decoded.debugDisposed, isFalse);
      expect(
        (await decoded.toByteData())!.buffer.asUint8List(),
        (await original.toByteData())!.buffer.asUint8List(),
      );
    },
  );

  test('releases the encoded buffer when image metadata is invalid', () async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(
      Uint8List.fromList([1, 2, 3]),
    );
    await expectLater(decodeAtlasPage(buffer), throwsException);
    expect(buffer.debugDisposed, isTrue);
  });
}
