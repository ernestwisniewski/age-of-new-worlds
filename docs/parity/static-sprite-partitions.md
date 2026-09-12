# Static sprite atlas partitions

City frames are grouped by visual profile and level and field improvements by era. A visible
city no longer loads every future level, and an improvement no longer loads all
four eras. Semantic frame IDs and all presentation geometry remain unchanged.
There are 64 atlases and 711 frames; 100 static frames moved between atlas pages.
Components release their old scope when changing city level or improvement era.

The partitioner crops the existing decoded pages, including their two-pixel
extrusion. It does not resize or regenerate artwork. Both WebP tools must be
version 1.6.0; encoding uses lossless mode with exact transparent RGB preservation.
The source must be the original five static atlases, before partitioning.

From the repository root, with Flutter dependencies installed:

```sh
dart --packages=clients/aonw_flutter/.dart_tool/package_config.json \
  tool/assets/compile/partition_static_sprites.dart SOURCE_DIRECTORY OUTPUT_DIRECTORY
```

The output directory must be new and outside the source. Unaffected files are
copied unchanged. Commit `0fff0ce` contains the original source under
`assets/runtime/sprites`; export it to a separate directory to reproduce the
transformation. The shipped Flutter copy, pubspec directories and runtime manifest
must match the canonical output.

`static-sprite-pixels.json` records the 100 original frames before transformation,
using Flutter's native decoder independently of the partitioner. The regression
compares premultiplied RGBA bytes, including extrusion, plus dimensions and trim
geometry. Do not regenerate this baseline to accept an atlas conversion change.

Two rendered map goldens changed by nine pixels each, with a one-unit difference
in one RGB channel per pixel and unchanged alpha. Both runs produced exactly the
same differences, localized to the scaled city. The native source-pixel test
remains exact; smaller texture coordinates change interpolation rounding. The two
visually reviewed goldens were updated, without changing comparator tolerances.

City profiles are independently owned as well as levels: a growth/civic frame
loads 668,736 decoded bytes instead of 2,674,944 for all four profiles. All original
profile IDs remain available. The additional height change affected three pixels
in the loaded-map golden, each by one RGB channel unit; that reviewed image was
updated while the exact source-pixel baseline remained unchanged.
