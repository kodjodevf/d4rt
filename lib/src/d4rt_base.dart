import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/error/error.dart';
import 'package:d4rt/src/bridge/bridged_enum.dart';
import 'package:d4rt/src/utils/logger/logger.dart';
import 'package:d4rt/src/bridge/bridged_types.dart';
import 'package:d4rt/src/runtime_types.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/module_loader.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/declaration_visitor.dart';
import 'package:d4rt/src/stdlib/stdlib.dart';
import 'package:d4rt/src/bridge/registration.dart';
import 'package:d4rt/src/security/permissions.dart';
import 'package:d4rt/src/introspection.dart';

/// The main D4rt interpreter class.
///
/// This class provides the primary interface for executing Dart code at runtime.
/// It manages the interpretation environment, handles bridged types, and provides
/// methods for code execution with proper error handling and debugging support.
///
/// ## Example:
/// ```dart
/// final interpreter = D4rt();
///
/// // Register a bridged class to make native types available in interpreted code
/// interpreter.registerBridgedClass(myBridgedClass, 'my_library');
///
/// // Execute Dart code
/// final result = await interpreter.execute(source: '''
///   void main() {
///     print("Hello from D4rt!");
///   }
/// ''');
/// ```
class D4rt {
  final List<Map<String, BridgedEnumDefinition>> _bridgedEnumDefinitions = [];
  final List<Map<String, BridgedClass>> _bridgedClases = [];
  InterpretedInstance? _interpretedInstance;
  InterpreterVisitor? _visitor;
  final Map<Type, BridgedClass> _bridgedDefLookupByType = {};
  final Set<Permission> _grantedPermissions = {};

  /// Gets the current interpreter visitor instance.
  ///
  /// Returns null if no execution is currently in progress.
  InterpreterVisitor? get visitor => _visitor;
  final List<NativeFunction> _nativeFunctions = [];

  late ModuleLoader _moduleLoader;
  bool _hasExecutedOnce = false;

  /// Registers a bridged enum definition for use in interpreted code.
  ///
  /// [definition] The enum definition containing the native enum type and its values.
  /// [library] The library identifier where this enum should be available.
  void registerBridgedEnum(BridgedEnumDefinition definition, String library) {
    _bridgedEnumDefinitions.add({library: definition});
  }

  /// Registers a bridged class definition for use in interpreted code.
  ///
  /// This allows native Dart classes to be accessible and instantiable
  /// from within interpreted code, enabling seamless integration between
  /// native and interpreted environments.
  ///
  /// [definition] The class definition containing constructors, methods, and properties.
  /// [library] The library identifier where this class should be available.
  void registerBridgedClass(BridgedClass definition, String library) {
    _bridgedClases.add({library: definition});
    _bridgedDefLookupByType[definition.nativeType] = definition;
  }

  /// Registers a top-level native function for use in interpreted code.
  ///
  /// [name] The name by which the function will be accessible in interpreted code.
  /// [function] The native function implementation to be called.
  void registertopLevelFunction(String? name, NativeFunctionImpl function) {
    _nativeFunctions.add(NativeFunction(function, name: name, arity: 0));
  }

  ModuleLoader _initModule(Map<String, String>? sources,
      {String? basePath, bool allowFileSystemImports = false}) {
    final moduleLoader = ModuleLoader(
      Environment(),
      sources ?? {},
      _bridgedEnumDefinitions,
      _bridgedClases,
      d4rt: this,
    );
    _visitor = InterpreterVisitor(
        globalEnvironment: moduleLoader.globalEnvironment,
        moduleLoader: moduleLoader);
    Stdlib(moduleLoader.globalEnvironment).register();
    return moduleLoader;
  }

  /// Enables or disables debug logging for the interpreter.
  ///
  /// When enabled, the interpreter will output detailed information about
  /// execution flow, variable lookups, method calls, and other internal operations.
  ///
  /// [enabled] Whether to enable debug logging.
  void setDebug(bool enabled) => Logger.setDebug(enabled);

  /// Grants a permission for security-sensitive operations.
  ///
  /// This method allows granting specific permissions that are required for
  /// accessing dangerous modules like dart:io, dart:isolate, or performing
  /// file system operations, network access, or process execution.
  ///
  /// [permission] The permission to grant.
  ///
  /// ## Example:
  /// ```dart
  /// final interpreter = D4rt();
  /// interpreter.grant(FilesystemPermission.any);
  /// interpreter.grant(NetworkPermission.any);
  /// ```
  void grant(Permission permission) {
    _grantedPermissions.add(permission);
    Logger.debug("[D4rt.grant] Granted permission: ${permission.description}");
  }

  /// Revokes a previously granted permission.
  ///
  /// [permission] The permission to revoke.
  void revoke(Permission permission) {
    _grantedPermissions.remove(permission);
    Logger.debug("[D4rt.revoke] Revoked permission: ${permission.description}");
  }

  /// Checks if a specific permission is granted.
  ///
  /// [permission] The permission to check.
  /// Returns true if the permission is granted, false otherwise.
  bool hasPermission(Permission permission) {
    return _grantedPermissions.contains(permission);
  }

  /// Checks if any permission in the granted set allows the given operation.
  ///
  /// [operation] The operation to check permissions for.
  /// Returns true if any granted permission allows the operation.
  bool checkPermission(dynamic operation) {
    for (final permission in _grantedPermissions) {
      if (permission.allows(operation)) {
        return true;
      }
    }
    return false;
  }

  /// Execute the given source code.
  ///
  /// [source] The source code to execute. If not provided, the main source will be loaded from the given library.
  ///
  /// [name] The name of the function to call. Defaults to 'main'.
  ///
  /// [positionalArgs] The positional arguments to pass to the function.
  ///
  /// [namedArgs] The named arguments to pass to the function.
  ///
  /// [args] @deprecated Use [positionalArgs] instead. Legacy argument passing (will be wrapped in a list).
  ///
  /// [library] The URI of the named function source to load. example: 'package:my_package/main.dart' (if provided, the source parameter will be ignored).
  ///
  /// [sources] The sources to load. example: {'package:my_package/main.dart': 'main() { return "Hello, World!"; }'}
  ///
  /// [basePath] Base directory path for resolving relative imports from the filesystem.
  /// When provided, relative imports (e.g., './utils.dart', '../models/user.dart')
  /// will be resolved against this path.
  ///
  /// [allowFileSystemImports] Whether to allow loading modules from the filesystem.
  /// When true, relative imports and file:// URIs will be resolved and loaded from disk.
  /// Requires FilesystemPermission when using D4rt's permission system.
  ///
  /// ## Example:
  /// ```dart
  /// final d4rt = D4rt();
  ///
  /// // Simple execution
  /// d4rt.execute(source: 'main() => "Hello";');
  ///
  /// // With positional arguments
  /// d4rt.execute(
  ///   source: 'greet(String name, int age) => "Hello \$name, you are \$age";',
  ///   name: 'greet',
  ///   positionalArgs: ['John', 25],
  /// );
  ///
  /// // With named arguments
  /// d4rt.execute(
  ///   source: 'greet({required String name, int age = 0}) => "Hello \$name, \$age";',
  ///   name: 'greet',
  ///   namedArgs: {'name': 'John', 'age': 30},
  /// );
  ///
  /// // Mixed positional and named arguments
  /// d4rt.execute(
  ///   source: 'greet(String greeting, {required String name}) => "\$greeting \$name";',
  ///   name: 'greet',
  ///   positionalArgs: ['Hello'],
  ///   namedArgs: {'name': 'World'},
  /// );
  ///
  /// // With relative imports from filesystem
  /// d4rt.grant(FilesystemPermission.any);
  /// d4rt.execute(
  ///   source: '''
  ///     import './utils.dart';
  ///     main() => greetFromUtils();
  ///   ''',
  ///   basePath: '/path/to/project/lib',
  ///   allowFileSystemImports: true,
  /// );
  /// ```
  dynamic execute({
    String? source,
    String name = 'main',
    List<Object?>? positionalArgs,
    Map<String, Object?>? namedArgs,
    @Deprecated('Use positionalArgs instead') Object? args,
    String? library,
    Map<String, String>? sources,
    String? basePath,
    bool allowFileSystemImports = false,
  }) {
    // Handle deprecated args parameter
    if (args != null && positionalArgs != null) {
      throw ArgumentError(
          'Cannot use both "args" (deprecated) and "positionalArgs". Use only "positionalArgs".');
    }
    if (args != null) {
      Logger.warn(
          '[D4rt.execute] The "args" parameter is deprecated. Use "positionalArgs" instead.');
      positionalArgs = [args];
    }
    _moduleLoader = _initModule(sources,
        basePath: basePath, allowFileSystemImports: allowFileSystemImports);
    Logger.debug("[D4rt.execute] Starting execution. library: $library");
    CompilationUnit compilationUnit;

    if (library != null) {
      Logger.debug(
          "[D4rt.execute] Attempting to load the $name source via ModuleLoader for URI: $library");

      if (!_moduleLoader.sources.containsKey(library.toString())) {
        final errorMessage =
            "[D4rt.execute] The $name source URI '$library' was not found in sources.";
        Logger.error(errorMessage);
        throw SourceCodeException(errorMessage);
      }

      if (source?.isNotEmpty ?? false) {
        Logger.warn(
            "[D4rt.execute] The 'source' parameter is not empty but 'library' ($library) is used to load from sources. The 'source' string will be ignored.");
      }

      try {
        final loadedRootModule = _moduleLoader.loadModule(Uri.parse(library));
        compilationUnit = loadedRootModule.ast;
        Logger.debug(
            "[D4rt.execute] $name source loaded and parsed successfully via ModuleLoader for $library.");
      } catch (e) {
        Logger.error(
            "[D4rt.execute] Failed to load $name source $library via ModuleLoader: $e");
        if (e is SourceCodeException || e is RuntimeError) {
          rethrow;
        } else {
          throw Exception(
              "Unexpected failure to load initial module $library: $e");
        }
      }
    } else {
      if (source == null) {
        throw Exception('Source content must be provide');
      }
      Logger.debug(
          "[D4rt.execute] Executing the provided source string directly (no source URI).");
      final result = parseString(
        content: source,
        throwIfDiagnostics: false,
        featureSet: FeatureSet.latestLanguageVersion(),
      );

      final errors = result.errors
          .where((e) => e.diagnosticCode.severity == DiagnosticSeverity.ERROR)
          .toList();
      if (errors.isNotEmpty) {
        final errorMessages = errors.map((e) {
          final location = result.lineInfo.getLocation(e.offset);
          return "- ${e.message} (ligne ${location.lineNumber}, colonne ${location.columnNumber})";
        }).join("\n");
        Logger.error("Parsing errors for the direct source:\n$errorMessages");
        throw SourceCodeException(
            'Fatal parsing errors for the direct source:\n$errorMessages');
      }
      compilationUnit = result.unit;
      Logger.debug("[D4rt.execute] Direct source string parsed successfully.");
    }

    final Environment executionEnvironment = _moduleLoader.globalEnvironment;
    for (var function in _nativeFunctions) {
      executionEnvironment.define(function.name, function);
    }
    Logger.debug("[execute] Starting Pass 1: Declaration");
    final declarationVisitor = DeclarationVisitor(executionEnvironment);
    for (final declaration in compilationUnit.declarations) {
      declaration.accept<void>(declarationVisitor);
    }
    Logger.debug("[execute] Finished Pass 1: Declaration");

    _visitor = InterpreterVisitor(
        globalEnvironment: executionEnvironment,
        moduleLoader: _moduleLoader,
        initiallibrary: library != null ? Uri.parse(library) : null);
    Object? functionResult;
    try {
      Logger.debug(" [execute] Starting Pass 2: Interpretation");
      Logger.debug(
          " [execute] Processing directives (imports, exports, etc.)...");
      for (final directive in compilationUnit.directives) {
        if (directive is ImportDirective) {
          Logger.debug(
              " [execute]   - Processing ImportDirective: ${directive.uri.stringValue}");
          _visitor!.visitImportDirective(directive);
        } else {
          Logger.debug(
              " [execute]   - Skipping directive of type: ${directive.runtimeType}");
        }
      }
      Logger.debug(" [execute] Finished processing directives.");

      Logger.debug(" [execute] Processing ALL declarations sequentially");

      Logger.debug(" [execute] Top-level declarations for Pass 2:");
      for (final declaration in compilationUnit.declarations) {
        Logger.debug(" [execute]   - ${declaration.runtimeType}");
      }

      for (final declaration in compilationUnit.declarations) {
        declaration.accept<Object?>(_visitor!);
      }
      Logger.debug(" [execute] Finished processing declarations");
      Logger.debug("[execute] Looking for $name function");
      final functionCallable = executionEnvironment.get(name);
      if (functionCallable is Callable) {
        List<Object?> interpreterArgs = positionalArgs ?? [];
        final Map<String, Object?> interpreterNamedArgs = namedArgs ?? {};

        // Special handling for 'main' function: if it expects args but none provided,
        // pass an empty list automatically (standard Dart behavior)
        final expectedArity = functionCallable.arity;
        if (name == 'main' &&
            expectedArity > 0 &&
            interpreterArgs.isEmpty &&
            namedArgs?.isEmpty != false) {
          // main expects args but none were provided - pass empty list
          interpreterArgs = [<String>[]];
          Logger.debug(
              "[execute] 'main' expects arguments but none provided. Passing empty list.");
        }

        // Validate arity (only for positional args, named args are validated by the function itself)
        if (interpreterArgs.length > expectedArity) {
          throw RuntimeError(
              "'$name' function accepts at most $expectedArity positional argument(s), but ${interpreterArgs.length} were provided.");
        }

        Logger.debug(
            "[execute] Calling '$name' with positionalArgs: $interpreterArgs, namedArgs: $interpreterNamedArgs");

        functionResult = functionCallable.call(
            _visitor!, interpreterArgs, interpreterNamedArgs);
      } else {
        throw Exception(
            "No callable '$name' function found in the test source code.");
      }
      Logger.debug(" [execute] Finished Pass 2: Interpretation");
    } on InternalInterpreterException catch (e) {
      if (e.originalThrownValue is RuntimeError) {
        throw e.originalThrownValue as RuntimeError;
      } else {
        throw e.originalThrownValue!;
      }
    } catch (e) {
      if (e is RuntimeError) {
        rethrow;
      } else {
        throw RuntimeError('Unexpected error: $e');
      }
    }
    if (functionResult is InterpretedInstance) {
      _interpretedInstance = functionResult;
    }
    final resultValue = _bridgeInterpreterValueToNative(functionResult);
    if (resultValue is Future) {
      try {
        _hasExecutedOnce = true;
        return resultValue
            .then((value) => _bridgeInterpreterValueToNative(value));
      } on InternalInterpreterException catch (e) {
        if (e.originalThrownValue is RuntimeError) {
          throw e.originalThrownValue as RuntimeError;
        } else {
          throw e.originalThrownValue!;
        }
      } catch (e) {
        if (e is RuntimeError) {
          rethrow;
        } else {
          throw RuntimeError('Unexpected error: $e');
        }
      }
    }
    _hasExecutedOnce = true;
    return resultValue;
  }

  /// Analyzes the given source code and returns introspection information
  /// about all declared functions, classes, variables, enums, and extensions.
  ///
  /// This method parses and processes the source code without executing any function,
  /// allowing you to inspect what declarations are available.
  ///
  /// [source] The source code to analyze.
  ///
  /// [sources] Additional sources for multi-file analysis.
  ///
  /// [includeBuiltins] Whether to include built-in types and functions in the result.
  ///
  /// ## Example:
  /// ```dart
  /// final d4rt = D4rt();
  /// final result = d4rt.analyze(source: '''
  ///   class Person {
  ///     String name;
  ///     int age;
  ///     Person(this.name, this.age);
  ///     String greet() => "Hello, I'm \$name";
  ///   }
  ///
  ///   int add(int a, int b) => a + b;
  ///
  ///   final greeting = "Hello";
  /// ''');
  ///
  /// print(result.classes); // [ClassInfo(Person)]
  /// print(result.functions); // [FunctionInfo(add)]
  /// print(result.variables); // [VariableInfo(greeting)]
  /// ```
  IntrospectionResult analyze({
    required String source,
    Map<String, String>? sources,
    bool includeBuiltins = false,
  }) {
    Logger.debug("[D4rt.analyze] Starting analysis...");

    _moduleLoader = _initModule(sources);

    final parseResult = parseString(
      content: source,
      throwIfDiagnostics: false,
      featureSet: FeatureSet.latestLanguageVersion(),
    );

    final errors = parseResult.errors
        .where((e) => e.diagnosticCode.severity == DiagnosticSeverity.ERROR)
        .toList();
    if (errors.isNotEmpty) {
      final errorMessages = errors.map((e) {
        final location = parseResult.lineInfo.getLocation(e.offset);
        return "- ${e.message} (line ${location.lineNumber}, column ${location.columnNumber})";
      }).join("\n");
      throw SourceCodeException('Parsing errors:\n$errorMessages');
    }

    final compilationUnit = parseResult.unit;
    final Environment executionEnvironment = _moduleLoader.globalEnvironment;

    // Register native functions
    for (var function in _nativeFunctions) {
      executionEnvironment.define(function.name, function);
    }

    // Pass 1: Declaration
    final declarationVisitor = DeclarationVisitor(executionEnvironment);
    for (final declaration in compilationUnit.declarations) {
      declaration.accept<void>(declarationVisitor);
    }

    // Pass 2: Process imports and interpret declarations (for variable values)
    _visitor = InterpreterVisitor(
        globalEnvironment: executionEnvironment, moduleLoader: _moduleLoader);

    for (final directive in compilationUnit.directives) {
      if (directive is ImportDirective) {
        _visitor!.visitImportDirective(directive);
      }
    }

    for (final declaration in compilationUnit.declarations) {
      declaration.accept<Object?>(_visitor!);
    }

    Logger.debug("[D4rt.analyze] Analysis complete.");
    return IntrospectionBuilder.buildFromEnvironment(
      executionEnvironment,
      includeBuiltins: includeBuiltins,
      compilationUnit: compilationUnit,
    );
  }

  /// Evaluates an expression or statement in the context of previously executed code.
  ///
  /// This method allows you to execute additional code in the same environment
  /// as a previous `execute()` call, similar to a REPL experience.
  ///
  /// **Important**: You must call `execute()` at least once before calling `eval()`
  /// to establish the execution context.
  ///
  /// [expression] The Dart expression or statement to evaluate.
  ///
  /// ## Example:
  /// ```dart
  /// final d4rt = D4rt();
  ///
  /// // First, set up the context
  /// d4rt.execute(source: '''
  ///   var counter = 0;
  ///   void increment() { counter++; }
  ///   int getCounter() => counter;
  /// ''', name: 'getCounter');
  ///
  /// // Now use eval to interact with the established context
  /// d4rt.eval('increment()');
  /// d4rt.eval('increment()');
  /// final result = d4rt.eval('getCounter()'); // Returns 2
  ///
  /// // You can also define new functions
  /// d4rt.eval('int double(int x) => x * 2;');
  /// final doubled = d4rt.eval('double(counter)'); // Returns 4
  /// ```
  dynamic eval(String expression) {
    if (_visitor == null || !_hasExecutedOnce) {
      throw RuntimeError(
          'eval() requires an existing execution context. Call execute() first.');
    }

    Logger.debug("[D4rt.eval] Evaluating: $expression");
    final executionEnvironment = _moduleLoader.globalEnvironment;

    // First, try to parse as a top-level declaration (function, class, variable)
    final declarationParseResult = parseString(
      content: expression,
      throwIfDiagnostics: false,
      featureSet: FeatureSet.latestLanguageVersion(),
    );

    // Check if it parses as valid declaration(s)
    final declErrors = declarationParseResult.errors
        .where((e) => e.diagnosticCode.severity == DiagnosticSeverity.ERROR)
        .toList();

    if (declErrors.isEmpty &&
        declarationParseResult.unit.declarations.isNotEmpty) {
      // It's a declaration - process it directly in the global environment
      final compilationUnit = declarationParseResult.unit;

      // Declaration pass
      final declarationVisitor = DeclarationVisitor(executionEnvironment);
      for (final declaration in compilationUnit.declarations) {
        declaration.accept<void>(declarationVisitor);
      }

      // Interpretation pass
      for (final declaration in compilationUnit.declarations) {
        declaration.accept<Object?>(_visitor!);
      }

      Logger.debug("[D4rt.eval] Processed declaration(s)");
      return null;
    }

    // Try wrapping as expression to get return value
    final wrappedSource = '''
      dynamic __eval__() {
        return $expression;
      }
    ''';

    final parseResult = parseString(
      content: wrappedSource,
      throwIfDiagnostics: false,
      featureSet: FeatureSet.latestLanguageVersion(),
    );

    if (parseResult.errors.isEmpty) {
      // Execute as expression with return value
      final compilationUnit = parseResult.unit;

      final declarationVisitor = DeclarationVisitor(executionEnvironment);
      for (final declaration in compilationUnit.declarations) {
        declaration.accept<void>(declarationVisitor);
      }

      for (final declaration in compilationUnit.declarations) {
        declaration.accept<Object?>(_visitor!);
      }

      // Call the __eval__ function
      final evalFunc = executionEnvironment.get('__eval__');
      Object? result;
      if (evalFunc is Callable) {
        try {
          result = evalFunc.call(_visitor!, [], {});
        } on InternalInterpreterException catch (e) {
          if (e.originalThrownValue is RuntimeError) {
            throw e.originalThrownValue as RuntimeError;
          }
          throw e.originalThrownValue ?? e;
        }
      }

      final bridgedResult = _bridgeInterpreterValueToNative(result);
      Logger.debug("[D4rt.eval] Result: $bridgedResult");

      if (bridgedResult is Future) {
        return bridgedResult
            .then((value) => _bridgeInterpreterValueToNative(value));
      }

      return bridgedResult;
    }

    // Try parsing as a statement (no return value expected)
    final statementSource = '''
      void __eval__() {
        $expression
      }
    ''';

    final statementParseResult = parseString(
      content: statementSource,
      throwIfDiagnostics: false,
      featureSet: FeatureSet.latestLanguageVersion(),
    );

    if (statementParseResult.errors.isEmpty) {
      final compilationUnit = statementParseResult.unit;

      final declarationVisitor = DeclarationVisitor(executionEnvironment);
      for (final declaration in compilationUnit.declarations) {
        declaration.accept<void>(declarationVisitor);
      }

      for (final declaration in compilationUnit.declarations) {
        declaration.accept<Object?>(_visitor!);
      }

      // Call the __eval__ function
      final evalFunc = executionEnvironment.get('__eval__');
      if (evalFunc is Callable) {
        try {
          evalFunc.call(_visitor!, [], {});
        } on InternalInterpreterException catch (e) {
          if (e.originalThrownValue is RuntimeError) {
            throw e.originalThrownValue as RuntimeError;
          }
          throw e.originalThrownValue ?? e;
        }
      }

      Logger.debug("[D4rt.eval] Executed statement");
      return null;
    }

    // All parsing attempts failed
    final errorMessages = declErrors.map((e) {
      final location = declarationParseResult.lineInfo.getLocation(e.offset);
      return "- ${e.message} (line ${location.lineNumber}, column ${location.columnNumber})";
    }).join("\n");
    throw SourceCodeException('Failed to parse expression:\n$errorMessages');
  }

  /// Invoke a property or method on the given instance.
  ///
  /// String name : The name of the property or method to invoke.
  ///
  /// List&lt;Object?&gt; positionalArgs : The positional arguments to pass to the property or method.
  ///
  /// Map&lt;String, Object?&gt; namedArgs = const {} : The named arguments to pass to the property or method.
  ///
  /// Map&lt;String, String&gt;? sources : The sources to load. example: {'package:my_package/main.dart': 'main() { return "Hello, World!"; }'}
  dynamic invoke(
    String name,
    List<Object?> positionalArgs, [
    Map<String, Object?> namedArgs = const {},
    Map<String, String>? sources,
  ]) {
    if (_interpretedInstance == null) {
      throw RuntimeError(
          "No interpreted instance found. Call setInterpretedInstance first.");
    }
    if (_visitor == null) {
      throw RuntimeError("No visitor found. Call setVisitor first.");
    }
    final globalEnv = _visitor!.globalEnvironment;
    final instance = _interpretedInstance!;
    final klass = instance.klass;

    InterpretedFunction? interpretedFunction;
    interpretedFunction = klass.findInstanceMethod(name);
    interpretedFunction ??= klass.findInstanceGetter(name);
    interpretedFunction ??= klass.findStaticMethod(name);
    interpretedFunction ??= klass.findStaticGetter(name);
    interpretedFunction ??= klass.findInstanceSetter(name);
    interpretedFunction ??= klass.findStaticSetter(name);
    result() {
      if (interpretedFunction != null) {
        final interpreterPositionalArgs = positionalArgs
            .map((v) => _bridgeNativeValueToInterpreter(v, globalEnv))
            .toList();

        final interpreterNamedArgs = namedArgs.map((key, value) =>
            MapEntry(key, _bridgeNativeValueToInterpreter(value, globalEnv)));
        return _tryFunction(() {
          return interpretedFunction!
              .bind(instance)
              .call(_visitor!, interpreterPositionalArgs, interpreterNamedArgs);
        }, "Error invoking interpreted Method or getter '$name' on '${klass.name}'");
      }

      final bridgedSuperclass = klass.bridgedSuperclass;
      final nativeSuperObject = instance.bridgedSuperObject;

      if (bridgedSuperclass != null) {
        final interpreterPositionalArgs = positionalArgs
            .map((v) => _bridgeNativeValueToInterpreter(v, globalEnv))
            .toList();
        final interpreterNamedArgs = namedArgs.map((key, value) =>
            MapEntry(key, _bridgeNativeValueToInterpreter(value, globalEnv)));

        if (nativeSuperObject != null) {
          final methodAdapter =
              bridgedSuperclass.findInstanceMethodAdapter(name);

          if (methodAdapter != null) {
            return _tryFunction(() {
              return methodAdapter.call(_visitor!, nativeSuperObject,
                  interpreterPositionalArgs, interpreterNamedArgs);
            }, "Error invoking bridged method '$name' on superclass '${bridgedSuperclass.name}'");
          }

          final getterAdapter =
              bridgedSuperclass.findInstanceGetterAdapter(name);
          if (getterAdapter != null) {
            return _tryFunction(() {
              return getterAdapter.call(_visitor!, nativeSuperObject);
            }, "Error invoking bridged getter '$name' on superclass '${bridgedSuperclass.name}'");
          }
          final setterAdapter =
              bridgedSuperclass.findInstanceSetterAdapter(name);
          if (setterAdapter != null) {
            return _tryFunction(() {
              setterAdapter.call(
                  _visitor!, nativeSuperObject, interpreterPositionalArgs[0]);
              return null;
            }, "Error invoking bridged setter '$name' on superclass '${bridgedSuperclass.name}'");
          }
        }

        final staticMethodAdapter =
            bridgedSuperclass.findStaticMethodAdapter(name);
        if (staticMethodAdapter != null) {
          return _tryFunction(() {
            return staticMethodAdapter.call(
                _visitor!, interpreterPositionalArgs, interpreterNamedArgs);
          }, "Error invoking bridged static method '$name' on superclass '${bridgedSuperclass.name}'");
        }

        final getterStaticAdapter =
            bridgedSuperclass.findStaticGetterAdapter(name);
        if (getterStaticAdapter != null) {
          return _tryFunction(() {
            return getterStaticAdapter.call(_visitor!);
          }, "Error invoking bridged static getter '$name' on superclass '${bridgedSuperclass.name}'");
        }

        final staticSetterAdapter =
            bridgedSuperclass.findStaticSetterAdapter(name);
        if (staticSetterAdapter != null) {
          return _tryFunction(() {
            staticSetterAdapter.call(_visitor!, interpreterPositionalArgs[0]);
            return null;
          }, "Error invoking bridged staticsetter '$name' on superclass '${bridgedSuperclass.name}'");
        }
      }

      throw RuntimeError(
          'Method or getter "$name" not found on instance of class "${klass.name}" or its bridged superclass.');
    }

    return result();
  }

  Object? _bridgeNativeValueToInterpreter(
      Object? nativeValue, Environment globalEnv) {
    if (nativeValue == null ||
        nativeValue is String ||
        nativeValue is num ||
        nativeValue is bool) {
      return nativeValue;
    }
    if (nativeValue is List) {
      return nativeValue
          .map((v) => _bridgeNativeValueToInterpreter(v, globalEnv))
          .toList();
    }
    if (nativeValue is Map) {
      return nativeValue.map((key, value) => MapEntry(
          _bridgeNativeValueToInterpreter(key, globalEnv),
          _bridgeNativeValueToInterpreter(value, globalEnv)));
    }

    final nativeType = nativeValue.runtimeType;
    final bridgedDef = _bridgedDefLookupByType[nativeType];

    if (bridgedDef != null) {
      final bridgedClass = globalEnv.get(bridgedDef.name);
      if (bridgedClass is BridgedClass) {
        return BridgedInstance(bridgedClass, nativeValue);
      } else {
        Logger.warn(
            "BridgedClass '${bridgedDef.name}' not found in global env during bridging.");
        return nativeValue;
      }
    }

    if (nativeValue is Function || nativeValue is Callable) {
      return nativeValue;
    }

    Logger.warn(
        "Passing unknown native type $nativeType directly to interpreter.");
    return nativeValue;
  }

  Object? _bridgeInterpreterValueToNative(Object? interpreterValue) {
    if (interpreterValue == null ||
        interpreterValue is String ||
        interpreterValue is num ||
        interpreterValue is bool) {
      return interpreterValue;
    }
    if (interpreterValue is BridgedInstance) {
      return interpreterValue.nativeObject;
    }

    if (interpreterValue is BridgedEnumValue) {
      return interpreterValue.nativeValue;
    }
    if (interpreterValue is List) {
      return interpreterValue.map(_bridgeInterpreterValueToNative).toList();
    }
    if (interpreterValue is Map) {
      return interpreterValue.map((key, value) => MapEntry(
          _bridgeInterpreterValueToNative(key),
          _bridgeInterpreterValueToNative(value)));
    }
    if (interpreterValue is InterpretedInstance ||
        interpreterValue is InterpretedFunction ||
        interpreterValue is NativeFunction ||
        interpreterValue is Callable) {
      return interpreterValue;
    }

    return interpreterValue;
  }

  dynamic _tryFunction(dynamic Function() fn, String error) {
    try {
      final result = fn.call();
      if (result is Future) {
        return result.then((value) => _bridgeInterpreterValueToNative(value));
      }
      return _bridgeInterpreterValueToNative(result);
    } catch (e) {
      if (e is ReturnException) {
        return _bridgeInterpreterValueToNative(e.value);
      }
      if (e is InternalInterpreterException && e.originalThrownValue != null) {
        throw e.originalThrownValue!;
      }
      throw "$error : $e";
    }
  }
}
