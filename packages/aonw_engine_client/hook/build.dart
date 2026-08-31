import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

const _assetName = 'aonw_engine_client_bindings.dart';
const _engineCrateName = 'aonw_flutter';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;
    if (_engineBuildEnabled(input)) {
      await _buildEngine(input, output);
      return;
    }
    await CBuilder.library(
      name: _engineCrateName,
      assetName: _assetName,
      sources: const ['src/aonw_engine_client_stub.c'],
    ).run(input: input, output: output, logger: _logger());
  });
}

bool _engineBuildEnabled(BuildInput input) {
  final enabled = input.userDefines['engine_backend'];
  if (enabled is! bool?) {
    throw const FormatException(
      'hooks.user_defines.aonw_engine_client.engine_backend must be a boolean.',
    );
  }
  if (enabled != true) return false;
  _requireNativeHostTarget(input.config.code);
  _engineTarget(input.config.code);
  return true;
}

void _requireNativeHostTarget(CodeConfig code) {
  final targetOS = code.targetOS;
  final targetArchitecture = code.targetArchitecture;
  if (targetOS == OS.current && targetArchitecture == Architecture.current) {
    return;
  }
  throw UnsupportedError(
    'Unsupported engine host target: $targetOS/$targetArchitecture. '
    'Refusing to substitute the unavailable C stub.',
  );
}

Future<void> _buildEngine(BuildInput input, BuildOutputBuilder output) async {
  final engineRoot = input.packageRoot.resolve('../../engine/');
  final code = input.config.code;
  final target = _engineTarget(code);
  final environment = Map<String, String>.of(Platform.environment);
  final cargoTarget = target.toUpperCase().replaceAll('-', '_');
  if (code.cCompiler case final compiler?) {
    environment['CARGO_TARGET_${cargoTarget}_LINKER'] = compiler.compiler
        .toFilePath();
  }
  if (code.targetOS == OS.iOS) {
    environment['IPHONEOS_DEPLOYMENT_TARGET'] = '${code.iOS.targetVersion}.0';
  } else if (code.targetOS == OS.macOS) {
    environment['MACOSX_DEPLOYMENT_TARGET'] = '${code.macOS.targetVersion}.0';
  }
  final result = await Process.run(
    'cargo',
    [
      'build',
      '--release',
      '--locked',
      '-p',
      _engineCrateName,
      '--target',
      target,
    ],
    workingDirectory: engineRoot.toFilePath(),
    environment: environment,
  );
  if (result.exitCode != 0) {
    throw BuildError(
      message:
          'Engine Flutter adapter build for $target failed. Install the '
          'engine target and target linker before retrying:\n${result.stderr}',
    );
  }
  final linkMode = _linkMode(code.linkModePreference);
  final libraryName = switch (linkMode) {
    StaticLinking() => code.targetOS.staticlibFileName(_engineCrateName),
    _ => code.targetOS.dylibFileName(_engineCrateName),
  };
  final source = engineRoot.resolve('target/$target/release/$libraryName');
  final destination = input.outputDirectory.resolve(libraryName);
  await File.fromUri(source).copy(destination.toFilePath());
  await _addEngineDependencies(engineRoot, output);
  output.assets.code.add(
    CodeAsset(
      package: input.packageName,
      name: _assetName,
      linkMode: linkMode,
      file: destination,
    ),
  );
}

LinkMode _linkMode(LinkModePreference preference) => switch (preference) {
  LinkModePreference.static ||
  LinkModePreference.preferStatic => StaticLinking(),
  _ => DynamicLoadingBundled(),
};

String _engineTarget(CodeConfig code) {
  final os = code.targetOS;
  final architecture = code.targetArchitecture;
  if (os == OS.android) return _androidEngineTarget(architecture);
  if (os == OS.iOS) return _iosEngineTarget(code, architecture);
  if (os == OS.macOS) return _macosEngineTarget(architecture);
  if (os == OS.linux) return _linuxEngineTarget(architecture);
  if (os == OS.windows) return _windowsEngineTarget(architecture);
  throw UnsupportedError('Unsupported engine target: $os/$architecture');
}

String _androidEngineTarget(Architecture architecture) =>
    switch (architecture) {
      Architecture.arm => 'armv7-linux-androideabi',
      Architecture.arm64 => 'aarch64-linux-android',
      Architecture.ia32 => 'i686-linux-android',
      Architecture.x64 => 'x86_64-linux-android',
      _ => throw UnsupportedError(
        'Unsupported Android engine architecture: $architecture',
      ),
    };

String _iosEngineTarget(CodeConfig code, Architecture architecture) {
  if (code.iOS.targetSdk == IOSSdk.iPhoneSimulator) {
    return switch (architecture) {
      Architecture.arm64 => 'aarch64-apple-ios-sim',
      Architecture.x64 => 'x86_64-apple-ios',
      _ => throw UnsupportedError(
        'Unsupported iOS simulator architecture: $architecture',
      ),
    };
  }
  if (architecture == Architecture.arm64) return 'aarch64-apple-ios';
  throw UnsupportedError('Unsupported iOS device architecture: $architecture');
}

String _macosEngineTarget(Architecture architecture) => switch (architecture) {
  Architecture.arm64 => 'aarch64-apple-darwin',
  Architecture.x64 => 'x86_64-apple-darwin',
  _ => throw UnsupportedError(
    'Unsupported macOS engine architecture: $architecture',
  ),
};

String _linuxEngineTarget(Architecture architecture) => switch (architecture) {
  Architecture.arm => 'armv7-unknown-linux-gnueabihf',
  Architecture.arm64 => 'aarch64-unknown-linux-gnu',
  Architecture.ia32 => 'i686-unknown-linux-gnu',
  Architecture.riscv64 => 'riscv64gc-unknown-linux-gnu',
  Architecture.x64 => 'x86_64-unknown-linux-gnu',
  _ => throw UnsupportedError(
    'Unsupported Linux engine architecture: $architecture',
  ),
};

String _windowsEngineTarget(Architecture architecture) =>
    switch (architecture) {
      Architecture.arm64 => 'aarch64-pc-windows-msvc',
      Architecture.ia32 => 'i686-pc-windows-msvc',
      Architecture.x64 => 'x86_64-pc-windows-msvc',
      _ => throw UnsupportedError(
        'Unsupported Windows engine architecture: $architecture',
      ),
    };

Future<void> _addEngineDependencies(
  Uri engineRoot,
  BuildOutputBuilder output,
) async {
  for (final relative in ['Cargo.toml', 'Cargo.lock', 'rust-toolchain.toml']) {
    output.dependencies.add(engineRoot.resolve(relative));
  }
  await for (final entry in Directory.fromUri(
    engineRoot.resolve('crates/'),
  ).list(recursive: true)) {
    if (entry is File &&
        (entry.path.endsWith('.rs') || entry.path.endsWith('Cargo.toml'))) {
      output.dependencies.add(entry.uri);
    }
  }
}

Logger _logger() => Logger.root..level = Level.ALL;
