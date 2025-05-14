import 'package:analyzer/dart/ast/ast.dart';
import 'package:d4rt/d4rt.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:d4rt/src/stdlib/convert.dart';
import 'package:d4rt/src/stdlib/math.dart';
import 'package:d4rt/src/stdlib/stdlib_io.dart'
    if (dart.library.html) 'package:d4rt/src/stdlib/stdlib_web.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:analyzer/error/error.dart';

// Represent an module of source code loaded and parsed.
class LoadedModule {
  final Uri uri; // The canonical URI of the module
  final CompilationUnit ast; // The AST of the module
  final Environment environment; // The environment of this module
  final Environment
      exportedEnvironment; // The environment of the exported symbols

  LoadedModule(this.uri, this.ast, this.environment, this.exportedEnvironment);
}

class ModuleLoader {
  final Environment globalEnvironment;
  final Map<String, String> sources;
  final Map<Uri, LoadedModule> _moduleCache = {};
  final List<Map<String, BridgedEnumDefinition>> bridgedEnumDefinitions;
  final List<Map<String, BridgedClassDefinition>> bridgedClassDefinitions;
  Uri?
      currentlibrary; // Keep for the initial relative URI resolution in _fetchModuleSource and for relative imports

  ModuleLoader(this.globalEnvironment, this.sources,
      this.bridgedEnumDefinitions, this.bridgedClassDefinitions) {
    Logger.debug(
        "[ModuleLoader] Initialized with ${sources.length} preloaded sources.");
  }

  LoadedModule loadModule(Uri uri) {
    // Save the current source URI for resolving relative exports of this module
    Uri? previouslibraryForRecursiveLoad = currentlibrary;
    currentlibrary = uri;
    Logger.debug(
        "[ModuleLoader loadModule for $uri] Setting currentlibrary to: $uri");

    if (_moduleCache.containsKey(uri)) {
      Logger.debug(
          "[ModuleLoader loadModule for $uri] Module '${uri.toString()}' found in cache.");
      // Restore the source URI before returning for parent calls
      currentlibrary = previouslibraryForRecursiveLoad;
      return _moduleCache[uri]!;
    }
    Logger.debug(
        "[ModuleLoader loadModule for $uri] Loading module: ${uri.toString()}");
    String sourceCode = _fetchModuleSource(
        uri); // Use this.currentlibrary (which is `uri` here)
    CompilationUnit ast = _parseSource(uri, sourceCode);

    Environment moduleEnvironment = Environment(enclosing: globalEnvironment);

    DeclarationVisitor declarationVisitor =
        DeclarationVisitor(moduleEnvironment);
    // Only declarations are visited to populate the local environment
    for (var declaration in ast.declarations) {
      declaration.accept(declarationVisitor);
    }

    // Interpretation of top-level initializers
    // Create an InterpreterVisitor for this specific module.
    // It will use moduleEnvironment to resolve types and execute initializers.
    // The moduleLoader is passed for potentially resolved imports by initializers (less common).
    InterpreterVisitor moduleInterpreter = InterpreterVisitor(
        globalEnvironment:
            moduleEnvironment, // Important: use the module's local environment as base
        moduleLoader: this, // Pass the current loader
        initiallibrary: uri // The URI of the module being interpreted
        );

    Logger.debug(
        "[ModuleLoader loadModule for $uri] Executing InterpreterVisitor pass for initializers...");
    for (final declaration in ast.declarations) {
      // We only care about the evaluation of TopLevelVariableDeclaration for their initializers.
      // Functions and classes are already "declared" by DeclarationVisitor.
      // The InterpreterVisitor also handles function/class declarations but
      // here, we want to make sure that the `define` of variables are done with the correct values.
      if (declaration is TopLevelVariableDeclaration) {
        declaration.accept(moduleInterpreter);
      }
      // We could also want to execute other types of declarations if they have global side effects at the time of the module initialization,
      // but for variables, this is the most crucial.
      // Functions and classes are already "declared" (as Callable/InterpretedClass objects)
      // by the DeclarationVisitor in moduleEnvironment. InterpreterVisitor would redefine them
      // with the same objects (or similar objects if the logic differs slightly).
      // For now, let's focus on variables.
    }
    Logger.debug(
        "[ModuleLoader loadModule for $uri] Finished InterpreterVisitor pass for initializers.");

    // PREPARATION OF THE EXPORTED ENVIRONMENT
    Environment exportedEnvironment = Environment(
        enclosing: globalEnvironment); // Must also enclose globalEnvironment
    // Now, moduleEnvironment should contain the variables with their initialized values.
    exportedEnvironment.importEnvironment(moduleEnvironment);
    Logger.debug(
        "[ModuleLoader loadModule for $uri] Initialized exportedEnvironment with local declarations (post-initialization).");

    // Process the export directives of this module to populate its exportedEnvironment
    // Must be done before caching to avoid recursion problems if A exports B and B exports A.
    // The cache is checked at the beginning of the function.
    Logger.debug(
        "[ModuleLoader loadModule for $uri] Processing export directives for ${uri.toString()}...");
    for (final directive in ast.directives) {
      if (directive is ExportDirective) {
        final exportedUriString = directive.uri.stringValue;
        if (exportedUriString == null) {
          Logger.warn(
              "[ModuleLoader loadModule for $uri] Export directive with null URI string in ${uri.toString()}");
          continue;
        }
        try {
          Uri resolvedExportUri = uri.resolve(
              exportedUriString); // Resolve relative to the current module's URI
          Logger.debug(
              "[ModuleLoader loadModule for $uri]   Exporting from ${uri.toString()}: URI '$exportedUriString', resolved to '${resolvedExportUri.toString()}'");
          LoadedModule subModule =
              loadModule(resolvedExportUri); // Recursive call

          // Get the show/hide combinators
          Set<String>? showNames;
          Set<String>? hideNames;

          for (final combinator in directive.combinators) {
            if (combinator is ShowCombinator) {
              showNames ??= {}; // Initialize if it's the first show combinator
              showNames.addAll(
                  combinator.shownNames.map((id) => id.name)); // Use id.name
              Logger.debug(
                  "[ModuleLoader loadModule for $uri]   Export combinator: show ${combinator.shownNames.map((id) => id.name).join(', ')}");
            } else if (combinator is HideCombinator) {
              hideNames ??= {}; // Initialize if it's the first hide combinator
              hideNames.addAll(
                  combinator.hiddenNames.map((id) => id.name)); // Use id.name
              Logger.debug(
                  "[ModuleLoader loadModule for $uri]   Export combinator: hide ${combinator.hiddenNames.map((id) => id.name).join(', ')}");
            }
          }

          // Import the environment of the sub-module by applying the show/hide filters
          exportedEnvironment.importEnvironment(
            subModule.exportedEnvironment,
            show: showNames,
            hide: hideNames,
          );
          Logger.debug(
              "[ModuleLoader loadModule for $uri]   Successfully merged exported environment from ${resolvedExportUri.toString()} into ${uri.toString()} (show: ${showNames?.join(", ")}, hide: ${hideNames?.join(", ")}).");
        } catch (e, s) {
          Logger.error(
              "[ModuleLoader loadModule for $uri] Error processing export directive for '$exportedUriString' from ${uri.toString()}: $e\nStackTrace: $s");
          rethrow;
        }
      }
    }
    Logger.debug(
        "[ModuleLoader loadModule for $uri] Finished processing export directives for ${uri.toString()}.");

    try {
      final testGetSymbol = moduleEnvironment.get('getMessage');
      Logger.debug(
          "[ModuleLoader loadModule for $uri] Test get 'getMessage' from module env for $uri: SUCCESS, value: ${testGetSymbol?.runtimeType}");
    } catch (e) {
      // Silently ignore if not found
    }

    final loadedModule =
        LoadedModule(uri, ast, moduleEnvironment, exportedEnvironment);
    _moduleCache[uri] = loadedModule;
    Logger.debug(
        "[ModuleLoader loadModule for $uri] Module '${uri.toString()}' chargé et mis en cache.");

    // Restore the source URI before returning
    currentlibrary = previouslibraryForRecursiveLoad;
    Logger.debug(
        "[ModuleLoader loadModule for $uri] Restored currentlibrary to: $currentlibrary");
    return loadedModule;
  }

  String _fetchModuleSource(Uri uri) {
    final uriString = uri.toString();
    Logger.debug(
        "[ModuleLoader] Récupération de la source pour: $uriString depuis sources.");

    // First check if the exact URI is in the preloaded sources
    if (sources.containsKey(uriString)) {
      Logger.debug("[ModuleLoader] Source found for $uriString in sources.");
      return sources[uriString]!;
    }

    // Then handle the known Dart libraries provided by Stdlib
    if (uri.scheme == 'dart') {
      final knownStdlibDartLibs = [
        'core',
        'math',
        'async',
        'convert',
        'io',
      ];
      if (knownStdlibDartLibs.contains(uri.path)) {
        if (uri.path == 'convert') {
          registerConvertLibs(globalEnvironment);
          return '';
        }
        if (uri.path == 'math') {
          registerMathLibs(globalEnvironment);
          return '';
        }
        if (uri.path == 'io') {
          StdlibIo.registerStdIoLibs(globalEnvironment);
          return '';
        }
        Logger.info(
            "[ModuleLoader] The Dart library '${uri.toString()}' is provided natively by Stdlib. Returning an empty module.");
        return ""; // Empty source to allow the import to succeed
      } else {
        Logger.error(
            "[ModuleLoader] Dart library '${uri.toString()}' not supported or recognized by Stdlib.");
        throw SourceCodeException(
            "Dart library '${uri.toString()}' not supported.");
      }
    }
    for (var bridgedEnumDefinition in bridgedEnumDefinitions) {
      if (bridgedEnumDefinition.containsKey(uriString)) {
        final definition = bridgedEnumDefinition[uriString]!;
        try {
          final bridgedEnum = definition.buildBridgedEnum();
          globalEnvironment.defineBridgedEnum(bridgedEnum);
          Logger.debug(
              " [execute] Registered bridged enum: ${definition.name}");
          return '';
        } catch (e) {
          Logger.error("registering bridged enum '${definition.name}': $e");
          throw Exception(
              "Failed to register bridged enum '${definition.name}': $e");
        }
      }
    }
    for (var bridgedClassDefinition in bridgedClassDefinitions) {
      if (bridgedClassDefinition.containsKey(uriString)) {
        final definition = bridgedClassDefinition[uriString]!;
        try {
          globalEnvironment.defineBridge(definition);
          Logger.debug(
              " [execute] Registered bridged class: ${definition.name}");
          return '';
        } catch (e) {
          Logger.error("registering bridged class '${definition.name}': $e");
          throw Exception(
              "Failed to register bridged class '${definition.name}': $e");
        }
      }
    }

    // If it's neither explicitly preloaded nor a known Dart library, it's an error.
    Logger.error(
        "[ModuleLoader] Source not preloaded and not a recognized Dart standard library for URI: $uriString");
    throw SourceCodeException(
        "Module source not preloaded for URI: $uriString, and not a recognized Dart standard library.");
  }

  CompilationUnit _parseSource(Uri uri, String sourceCode) {
    Logger.debug("[ModuleLoader] Parsing source for module: ${uri.toString()}");
    // Ensure the path passed to parseString is meaningful for errors.
    // If the URI is opaque (ex: custom scheme), toFilePath may fail.
    // Use uri.path or uri.toString() as a fallback.
    String pathToReport =
        uri.isScheme('file') ? uri.toFilePath() : uri.toString();

    final result = parseString(
      content: sourceCode,
      throwIfDiagnostics: false,
      path: pathToReport,
      featureSet: FeatureSet.fromEnableFlags2(
        sdkLanguageVersion: Version(3, 0, 0), // Keep a SDK version
        flags: ['null-aware-elements'],
      ),
    );

    final errors = result.errors
        .where((e) => e.errorCode.errorSeverity == ErrorSeverity.ERROR)
        .toList();
    if (errors.isNotEmpty) {
      final errorMessages = errors.map((e) {
        final location = result.lineInfo.getLocation(e.offset);
        return "- ${e.message} (ligne ${location.lineNumber}, colonne ${location.columnNumber})";
      }).join("\\n");
      Logger.error(
          "[ModuleLoader] Parsing errors for $pathToReport:\\n$errorMessages");
      throw SourceCodeException(
          "Parsing errors in module $pathToReport:\\n$errorMessages");
    }
    Logger.debug(
        "[ModuleLoader] Module ${uri.toString()} parsed successfully.");
    return result.unit;
  }
}
