# Unit sprite packing

The 408 animation frames keep their semantic IDs, original logical dimensions,
content bounds and authored animation adjustments. Only fully transparent margins
are removed from storage. Each region retains two transparent sample pixels where
available, in addition to the original two-pixel atlas extrusion. TexturePacker
trim offsets place the cropped pixels back into their original logical canvas.

The offline tool decodes the existing pages using dwebp 1.6.0 and repacks exact
pixels without resizing. cwebp 1.6.0 uses lossless encoding and preserves transparent
RGB values. Deterministic shelf packing tests candidate widths up to 2048 pixels;
all pages stay within the existing size limit. The tool writes only unit atlas
files into a fresh external directory and never changes its input.

```sh
dart --packages=clients/aonw_flutter/.dart_tool/package_config.json \
  tool/assets/compile/trim_unit_sprites.dart SOURCE_DIRECTORY OUTPUT_DIRECTORY
```

The original unit files exist at revision `c134438`. Export that revision's
`assets/runtime/sprites` to reproduce the conversion. Ship matching canonical and
Flutter copies and refresh their size/hash entries in the runtime manifest.

`unit-sprite-pixels.json` was captured through Flutter's native decoder before
conversion. Its regression reconstructs every frame in its original transparent
canvas and compares premultiplied RGBA hashes and dimensions exactly. Do not
regenerate the baseline to accept a packing change. Separate tests cover preserved
extrusion, trim offsets, invalid input, deterministic placement, overlap and bounds.

Crops and packed positions align to 32 pixels so mipmap sampling keeps the source
atlas phase through five levels. An initial unaligned packing was rejected by
rendered goldens despite exact source pixels. With alignment, map/replay changes
are limited to 2–37 pixels per image, each by one RGB unit. The two route-ghost
figures differ at 13/71 pixels, with maximum channel deltas 11/24 at scaled edges.
All seven affected images were visually reviewed and updated. Comparator limits
were not changed; the exact logical-pixel baseline remains the original one.
