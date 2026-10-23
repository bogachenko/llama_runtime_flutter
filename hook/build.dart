import 'dart:io';

import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_cmake/native_toolchain_cmake.dart';
import 'package:code_assets/code_assets.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    final builder = CMakeBuilder.create(
      name: input.packageName,
      sourceDir: Directory.fromUri(input.packageRoot).uri,
      generator: Generator.ninja,
      androidArgs: const AndroidBuilderArgs(androidAPI: 26),
      defines: {
        'CMAKE_INSTALL_PREFIX': input.outputDirectory
            .resolve('install/')
            .toFilePath(),
      },
      targets: ['install'],
      logger: Logger('llama_runtime_flutter'),
    );

    await builder.run(
      input: input,
      output: output,
      logger: Logger('llama_runtime_flutter'),
    );
    final libraryPath = switch (input.config.code.targetOS) {
      OS.android || OS.linux => 'install/lib/libllama_runtime_flutter.so',
      OS.macOS || OS.iOS => 'install/lib/libllama_runtime_flutter.dylib',
      OS.windows => 'install/lib/llama_runtime_flutter.dll',
      _ => throw UnsupportedError('Unsupported platform'),
    };

    final libraryUri = input.outputDirectory.resolve(libraryPath);

    if (!File.fromUri(libraryUri).existsSync()) {
      throw StateError('Native library not found: $libraryUri');
    }

    output.assets.code.add(
      CodeAsset(
        package: input.packageName,
        name: 'llama_runtime_flutter_bindings_generated.dart',
        linkMode: DynamicLoadingBundled(),
        file: libraryUri,
      ),
    );
  });
}
