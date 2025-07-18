import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/error/error.dart';
import 'package:d4rt/src/bridge/bridged_enum.dart';
import 'package:d4rt/src/utils/logger/logger.dart';
import 'package:pub_semver/pub_semver.dart';
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

class D4rt {
  final List<Map<String, BridgedEnumDefinition>> _bridgedEnumDefinitions = [];
  final List<Map<String, BridgedClassDefinition>> _bridgedClassDefinitions = [];
  InterpretedInstance? _interpretedInstance;
  InterpreterVisitor? _visitor;
  final Map<Type, BridgedClassDefinition> _bridgedDefLookupByType = {};
  InterpreterVisitor? get visitor => _visitor;
  final List<NativeFunction> _nativeFunctions = [];

  late ModuleLoader _moduleLoader;

  void registerBridgedEnum(BridgedEnumDefinition definition, String library) {
    _bridgedEnumDefinitions.add({library: definition});
  }

  void registerBridgedClass(BridgedClassDefinition definition, String library) {
    _bridgedClassDefinitions.add({library: definition});
    _bridgedDefLookupByType[definition.nativeType] = definition;
  }

  void registertopLevelFunction(String? name, NativeFunctionImpl function) {
    _nativeFunctions.add(NativeFunction(function, name: name, arity: 0));
  }

  ModuleLoader _initModule(Map<String, String>? sources) {
    final moduleLoader = ModuleLoader(Environment(), sources ?? {},
        _bridgedEnumDefinitions, _bridgedClassDefinitions);
    _visitor = InterpreterVisitor(
        globalEnvironment: moduleLoader.globalEnvironment,
        moduleLoader: moduleLoader);
    Stdlib(moduleLoader.globalEnvironment).register();
    return moduleLoader;
  }

  void setDebug(bool enabled) => Logger.setDebug(enabled);

  /// Execute the given source code.
  ///
  /// String? source : The source code to execute. If not provided, the main source will be loaded from the given library.
  ///
  /// String name = 'main' : The name of the function to call.
  ///
  /// Object? args : The arguments to pass to the name function.
  ///
  /// String? library : The URI of the named function source to load. example: 'package:my_package/main.dart' (if provided, the source parameter will be ignored).
  ///
  /// Map&lt;String, String&gt;? sources : The sources to load. example: {'package:my_package/main.dart': 'main() { return "Hello, World!"; }'}
  dynamic execute({
    String? source,
    String name = 'main',
    Object? args,
    String? library,
    Map<String, String>? sources,
  }) {
    _moduleLoader = _initModule(sources);
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
        featureSet: FeatureSet.fromEnableFlags2(
          sdkLanguageVersion: Version(3, 0, 0),
          flags: [
            'non-nullable',
            'null-aware-elements',
            'triple-shift',
            'spread-collections',
            'control-flow-collections',
            'extension-methods',
            'extension-types',
          ],
        ),
      );

      final errors = result.errors
          .where((e) => e.errorCode.errorSeverity == ErrorSeverity.ERROR)
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
        List<dynamic> interpreterArgs = [];
        bool functionAcceptsArgs = false;

        if (functionCallable.arity == 1) {
          functionAcceptsArgs = true;
          Logger.debug(
              "[execute] Detected '$name' function has arity 1, assuming it accepts arguments.");
        }

        if (args != null) {
          if (functionAcceptsArgs) {
            interpreterArgs = [args];
            Logger.debug(" [execute] Passing provided args: [$args]");
          } else {
            throw RuntimeError(
                "'$name' function does not accept arguments (arity 0), but arguments were provided: $args");
          }
        } else {
          if (functionAcceptsArgs) {
            Logger.debug(
                " [execute] '$name' accepts arguments (arity 1), but none provided. Passing [[]] (list containing empty list).");
            interpreterArgs = [[]];
          } else {
            interpreterArgs = [];
          }
        }

        functionResult = functionCallable.call(_visitor!, interpreterArgs, {});
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
    return resultValue;
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
