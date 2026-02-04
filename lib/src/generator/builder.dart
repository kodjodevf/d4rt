import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'bridge_generator_handler.dart';

/// The entry point for the D4rt bridge generator.
Builder d4rtBridgeBuilder(BuilderOptions options) {
  return SharedPartBuilder(
    [D4rtBridgeGenerator()],
    'd4rt_bridge',
  );
}

class D4rtBridgeGenerator extends Generator {
  final _handler = BridgeGeneratorHandler();

  @override
  Future<String?> generate(LibraryReader library, BuildStep buildStep) async {
    return await _handler.generateForLibrary(library, buildStep);
  }
}
