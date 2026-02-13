import 'dart:async';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'metadata_collector.dart';
import 'transform_pipeline.dart';
import 'code_emitter.dart';
import 'generator_config.dart';

class BridgeGeneratorHandler {
  final _checker = const TypeChecker.fromUrl(
      'package:d4rt/src/bridge/bridge_annotations.dart#D4rtBridge');

  Future<String?> generateForLibrary(
      LibraryReader library, BuildStep buildStep) async {
    final buffer = StringBuffer();
    final sourceCode = await buildStep.readAsString(buildStep.inputId);

    // Check if the library has any @D4rtBridge annotations
    final annotatedElements = library.annotatedWith(_checker);

    if (annotatedElements.isEmpty) {
      return null;
    }

    final config = GeneratorConfig(
      inputPaths: [], // Not used in this context
      outputPath: '', // Not used in this context
      includeAbstractClasses:
          true, // Allow generating bridges for abstract classes if annotated
    );

    final collector = MetadataCollector(config: config);
    final pipeline = TransformPipeline(config: config);
    final emitter = CodeEmitter(config: config);

    // We can collect from source directly for now to reuse existing logic
    final metadata = collector.collectFromSource(sourceCode);

    // Filter metadata to only include annotated classes/enums
    final filteredClasses = metadata.classes.where((c) {
      return annotatedElements.any((a) => a.element.name == c.name);
    }).toList();

    final filteredEnums = metadata.enums.where((e) {
      return annotatedElements.any((a) => a.element.name == e.name);
    }).toList();

    final transformed = pipeline.transform(CollectedMetadata(
      classes: filteredClasses,
      enums: filteredEnums,
      functions: metadata.functions,
      variables: metadata.variables,
      imports: metadata.imports,
      sourcePath: buildStep.inputId.path,
    ));

    if (transformed.classes.isEmpty && transformed.enums.isEmpty) {
      return null;
    }

    final Map<String, String?> generatedClassBridges = {};
    final Map<String, String?> generatedEnumBridges = {};

    for (final cls in transformed.classes) {
      final code = emitter.emitSingleClass(cls);
      generatedClassBridges[cls.name] = cls.libraryUri;
      // Strip header/imports as source_gen handles that
      buffer.writeln(_stripBoilerplate(code));
    }

    for (final enm in transformed.enums) {
      final code = emitter.emitSingleEnum(enm);
      generatedEnumBridges[enm.name] = enm.libraryUri;
      buffer.writeln(_stripBoilerplate(code));
    }

    // Add registration function
    final inputId = buildStep.inputId;
    final sourceFileName = inputId.pathSegments.last;
    final baseName = sourceFileName.split('.').first;

    // Convert snake_case or kebab-case to PascalCase for the function name
    final pascalName = baseName
        .split(RegExp(r'[-_]'))
        .where((s) => s.isNotEmpty)
        .map((s) => s[0].toUpperCase() + s.substring(1))
        .join('');

    buffer.writeln();
    buffer.writeln(
        '/// Register all $baseName bridges from this file with the interpreter.');
    buffer.writeln('void register${pascalName}Bridges(D4rt interpreter) {');
    buffer.writeln("  // ignore: unused_local_variable");
    buffer.writeln("  const defaultUri = '$sourceFileName';");
    buffer.writeln();

    for (final entry in generatedClassBridges.entries) {
      final clsName = entry.key;
      final libraryUri = entry.value;
      final varName = clsName[0].toLowerCase() + clsName.substring(1);
      final uriStr = libraryUri != null ? "'$libraryUri'" : 'defaultUri';
      buffer.writeln(
          "  interpreter.registerBridgedClass(${varName}Bridge, $uriStr);");
    }

    for (final entry in generatedEnumBridges.entries) {
      final enmName = entry.key;
      final libraryUri = entry.value;
      final varName = enmName[0].toLowerCase() + enmName.substring(1);
      final uriStr = libraryUri != null ? "'$libraryUri'" : 'defaultUri';
      buffer.writeln(
          "  interpreter.registerBridgedEnum(${varName}Bridge, $uriStr);");
    }

    buffer.writeln('}');

    if (buffer.isEmpty) return null;
    return buffer.toString();
  }

  String _stripBoilerplate(String code) {
    // Basic stripping of generated headers and imports
    final lines = code.split('\n');
    return lines.where((line) {
      if (line.trim().isEmpty) return true;
      if (line.startsWith('///')) {
        // Keep docs for classes but maybe not the file header
        if (line.contains('auto-generated')) return false;
        return true;
      }
      if (line.startsWith('import ')) return false;
      if (line.startsWith('library ')) return false;
      if (line.startsWith('part ')) return false;
      return true;
    }).join('\n');
  }
}
