import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

const _assetName = 'aonw_server_native_bindings.dart';
const _rustCrateName = 'aonw_server_native';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;
    _requireNativeHostTarget(input.config.code);
    await _buildRust(input, output);
  });
}

void _requireNativeHostTarget(CodeConfig code) {
  if (code.targetOS == OS.current &&
      code.targetArchitecture == Architecture.current) {
    return;
  }
  throw UnsupportedError(
    'Unsupported Serverpod Rust host target: '
    '${code.targetOS}/${code.targetArchitecture}. '
    'The server package has no stub or Dart fallback.',
  );
}

Future<void> _buildRust(
  BuildInput input,
  BuildOutputBuilder output,
) async {
  final engineRoot = input.packageRoot.resolve('../../engine/');
  final code = input.config.code;
  final target = _rustTarget(code);
  final environment = Map<String, String>.of(Platform.environment);
  final cargoTarget = target.toUpperCase().replaceAll('-', '_');
  if (code.cCompiler case final compiler?) {
    environment['CARGO_TARGET_${cargoTarget}_LINKER'] = compiler.compiler
        .toFilePath();
  }
  if (code.targetOS == OS.macOS) {
    environment['MACOSX_DEPLOYMENT_TARGET'] = '${code.macOS.targetVersion}.0';
  }
  final result = await Process.run(
    'cargo',
    [
      'build',
      '--release',
      '--locked',
      '-p',
      _rustCrateName,
      '--target',
      target,
    ],
    workingDirectory: engineRoot.toFilePath(),
    environment: environment,
  );
  if (result.exitCode != 0) {
    throw BuildError(
      message:
          'Rust Serverpod host build for $target failed. No fallback is '
          'available:\n${result.stderr}',
    );
  }
  final linkMode = switch (code.linkModePreference) {
    LinkModePreference.static ||
    LinkModePreference.preferStatic => StaticLinking(),
    _ => DynamicLoadingBundled(),
  };
  final libraryName = switch (linkMode) {
    StaticLinking() => code.targetOS.staticlibFileName(_rustCrateName),
    _ => code.targetOS.dylibFileName(_rustCrateName),
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

String _rustTarget(CodeConfig code) => switch ((
  code.targetOS,
  code.targetArchitecture,
)) {
  (OS.macOS, Architecture.arm64) => 'aarch64-apple-darwin',
  (OS.macOS, Architecture.x64) => 'x86_64-apple-darwin',
  (OS.linux, Architecture.arm64) => 'aarch64-unknown-linux-gnu',
  (OS.linux, Architecture.x64) => 'x86_64-unknown-linux-gnu',
  (OS.windows, Architecture.arm64) => 'aarch64-pc-windows-msvc',
  (OS.windows, Architecture.x64) => 'x86_64-pc-windows-msvc',
  _ => throw UnsupportedError(
    'Unsupported Serverpod Rust host target: '
    '${code.targetOS}/${code.targetArchitecture}.',
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
