import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/assets/compile/sprite_partition_source.dart';

const _atlas = '''page_0.webp
size:8,8
format:RGBA8888
filter:Linear,Linear
repeat:none
city.test.0
bounds:2,2,4,4
offsets:1,2,6,7
index:-1
''';

void main() {
  late Directory directory;
  late File atlas;
  setUp(() {
    directory = Directory.systemTemp.createTempSync('aonw-partition-test-');
    atlas = File('${directory.path}/source.atlas');
  });
  tearDown(() => directory.deleteSync(recursive: true));

  test('preserves trim metadata while translating padded region bounds', () {
    atlas.writeAsStringSync(_atlas);
    final region = readPartitionRegions(atlas).single;
    expect(
      region.descriptor(2, 1),
      'city.test.0\nbounds:0,1,4,4\noffsets:1,2,6,7\nindex:-1\n',
    );
  });

  for (final invalid in {
    'rotation': _atlas.replaceFirst('bounds:', 'rotate:90\nbounds:'),
    'missing extrusion': _atlas.replaceFirst('bounds:2,2', 'bounds:1,2'),
    'page overflow': _atlas.replaceFirst('size:8,8', 'size:7,8'),
    'animation index': _atlas.replaceFirst('index:-1', 'index:0'),
    'duplicate region': '$_atlas\n$_atlas',
    'page traversal': _atlas.replaceFirst('page_0.webp', '../page_0.webp'),
  }.entries) {
    test('rejects ${invalid.key}', () {
      atlas.writeAsStringSync(invalid.value);
      expect(() => readPartitionRegions(atlas), throwsFormatException);
    });
  }
}
