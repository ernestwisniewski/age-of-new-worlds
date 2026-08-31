import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:test/test.dart';

import '../hook/build.dart' as build_hook;

void main() {
  test('rust_backend true rejects a cross-OS build instead of using stub', () {
    final targetOS = OS.values.firstWhere(
      (candidate) => candidate != OS.current,
    );
    return expectLater(
      _runHook(targetOS: targetOS, targetArchitecture: Architecture.current),
      _throwsRefusedStub(targetOS, Architecture.current),
    );
  });

  test(
    'rust_backend true rejects a cross-architecture build instead of stub',
    () {
      final targetArchitecture = Architecture.values.firstWhere(
        (candidate) => candidate != Architecture.current,
      );
      return expectLater(
        _runHook(targetOS: OS.current, targetArchitecture: targetArchitecture),
        _throwsRefusedStub(OS.current, targetArchitecture),
      );
    },
  );

  test('rust_backend rejects non-boolean configuration before any build', () {
    return expectLater(
      _runHook(
        targetOS: OS.current,
        targetArchitecture: Architecture.current,
        rustBackend: 'true',
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('rust_backend must be a boolean'),
        ),
      ),
    );
  });
}

Future<void> _runHook({
  required OS targetOS,
  required Architecture targetArchitecture,
  Object? rustBackend = true,
}) {
  return testCodeBuildHook(
    mainMethod: build_hook.main,
    targetOS: targetOS,
    targetArchitecture: targetArchitecture,
    userDefines: PackageUserDefines(
      workspacePubspec: PackageUserDefinesSource(
        defines: {'rust_backend': rustBackend},
        basePath: Directory.current.uri,
      ),
    ),
    check: (_, _) => fail('A refused Rust build must not produce an asset.'),
  );
}

Matcher _throwsRefusedStub(OS targetOS, Architecture targetArchitecture) {
  return throwsA(
    isA<UnsupportedError>()
        .having(
          (error) => error.message,
          'message',
          contains('$targetOS/$targetArchitecture'),
        )
        .having(
          (error) => error.message,
          'message',
          contains('Refusing to substitute the unavailable C stub'),
        ),
  );
}
