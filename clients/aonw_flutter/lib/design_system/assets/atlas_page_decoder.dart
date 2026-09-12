import 'dart:ui' as ui;

/// Consumes the encoded buffer and releases native decoding resources eagerly.
Future<ui.Image> decodeAtlasPage(ui.ImmutableBuffer buffer) async {
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  try {
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    codec = await descriptor.instantiateCodec();
    return (await codec.getNextFrame()).image;
  } finally {
    codec?.dispose();
    descriptor?.dispose();
    buffer.dispose();
  }
}
