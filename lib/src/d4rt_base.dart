import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/error/error.dart';
import 'package:d4rt/src/bridge/bridged_enum.dart';
import 'package:d4rt/src/utils/logger/logger.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:d4rt/src/bridge/bridged_types.dart';
import 'package:d4rt/src/runtime_types.dart';

import 'environment.dart';
import 'exceptions.dart';
import 'callable.dart';
import 'declaration_visitor.dart';
import 'interpreter_visitor.dart';
import 'stdlib/stdlib.dart';
import 'bridge/registration.dart';

class D4rt {
  final List<BridgedEnumDefinition> _bridgedEnumDefinitions = [];
  final List<BridgedClassDefinition> _bridgedClassDefinitions = [];
  InterpretedInstance? _interpretedInstance;
  InterpreterVisitor? _visitor;
  final Map<Type, BridgedClassDefinition> _bridgedDefLookupByType = {};

  final List<NativeFunction> _nativeFunctions = [];

  void registerBridgedEnum(BridgedEnumDefinition definition) {
    _bridgedEnumDefinitions.add(definition);
  }

  void setInterpretedInstance(InterpretedInstance instance) {
    _interpretedInstance = instance;
  }

  void registerBridgedClass(BridgedClassDefinition definition) {
    _bridgedClassDefinitions.add(definition);
    _bridgedDefLookupByType[definition.nativeType] = definition;
  }

  void registertopLevelFunction(String? name, NativeFunctionImpl function) {
    _nativeFunctions.add(NativeFunction(function, name: name, arity: 0));
  }

  void setDebug(bool enabled) => Logger.setDebug(enabled);

  dynamic execute(String source, {Object? mainArgs}) {
    final result = parseString(
      content: source,
      throwIfDiagnostics: false,
      featureSet: FeatureSet.fromEnableFlags2(
        sdkLanguageVersion: Version(3, 6, 0),
        flags: ['null-aware-elements'],
      ),
    );

    final errors = result.errors
        .where((e) => e.errorCode.errorSeverity == ErrorSeverity.ERROR)
        .toList();
    if (errors.isNotEmpty) {
      Logger.error("Erreurs de parsing:");
      for (var error in errors) {
        Logger.error(
            "- ${error.message} (ligne ${result.lineInfo.getLocation(error.offset).lineNumber})");
      }
      throw Exception('Erreur de parsing fatale: ${errors.first.message}');
    }

    final compilationUnit = result.unit;

    final environment = Environment();

    Logger.debug("[execute] Registering bridged classes...");
    for (final definition in _bridgedClassDefinitions) {
      try {
        environment.defineBridge(definition);
        Logger.debug(" [execute] Registered bridged class: ${definition.name}");
      } catch (e) {
        Logger.error("registering bridged class '${definition.name}': $e");
        throw Exception(
            "Failed to register bridged class '${definition.name}': $e");
      }
    }
    Logger.debug("[execute] Finished registering bridged classes.");
    registertopLevelFunction(
        'print',
        NativeFunction((visitor, arguments, _, __) {
          if (arguments.length != 1) {
            throw RuntimeError(
                "Native 'print' expects exactly 1 argument, got ${arguments.length}.");
          }
          print(arguments.first);
          return null;
        }, arity: 1, name: 'print')
            .call);
    Logger.debug("[execute] Registering bridged enums...");
    for (final definition in _bridgedEnumDefinitions) {
      try {
        final bridgedEnum = definition.buildBridgedEnum();
        environment.defineBridgedEnum(bridgedEnum);
        Logger.debug(" [execute] Registered bridged enum: ${definition.name}");
      } catch (e) {
        Logger.error("registering bridged enum '${definition.name}': $e");
        throw Exception(
            "Failed to register bridged enum '${definition.name}': $e");
      }
    }
    Logger.debug("[execute] Finished registering bridged enums.");
    for (var function in _nativeFunctions) {
      environment.define(function.name, function);
    }
    Stdlib(environment).register();
    Logger.debug("[execute] Starting Pass 1: Declaration");
    final declarationVisitor = DeclarationVisitor(environment);
    for (final declaration in compilationUnit.declarations) {
      declaration.accept<void>(declarationVisitor);
    }
    Logger.debug("[execute] Finished Pass 1: Declaration");

    _visitor = InterpreterVisitor(globalEnvironment: environment);
    Object? mainResult;
    try {
      Logger.debug(" [execute] Starting Pass 2: Interpretation");
      Logger.debug(" [execute] Processing ALL declarations sequentially");
      for (final declaration in compilationUnit.declarations) {
        declaration.accept<Object?>(_visitor!);
      }
      Logger.debug(" [execute] Finished processing declarations");
      Logger.debug("[execute] Looking for main function");
      final mainCallable = environment.get('main');
      if (mainCallable is Callable) {
        List<dynamic> interpreterArgs = [];
        bool mainAcceptsArgs = false;

        if (mainCallable.arity == 1) {
          mainAcceptsArgs = true;
          Logger.debug(
              "[execute] Detected 'main' function has arity 1, assuming it accepts arguments.");
        }

        if (mainArgs != null) {
          if (mainAcceptsArgs) {
            interpreterArgs = [mainArgs];
            Logger.debug(" [execute] Passing provided mainArgs: [$mainArgs]");
          } else {
            throw RuntimeError(
                "'main' function does not accept arguments (arity 0), but arguments were provided: $mainArgs");
          }
        } else {
          if (mainAcceptsArgs) {
            Logger.debug(
                " [execute] 'main' accepts arguments (arity 1), but none provided. Passing [[]] (list containing empty list).");
            interpreterArgs = [[]];
          } else {
            interpreterArgs = [];
          }
        }

        mainResult = mainCallable.call(_visitor!, interpreterArgs, {});
      } else {
        throw Exception(
            "No callable 'main' function found in the test source code.");
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
    if (mainResult is InterpretedInstance) {
      _interpretedInstance = mainResult;
    }
    final resultValue = _bridgeInterpreterValueToNative(mainResult);
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

  dynamic invoke(
    String methodName,
    List<Object?> positionalArgs, [
    Map<String, Object?> namedArgs = const {},
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
    interpretedFunction = klass.findInstanceMethod(methodName);
    interpretedFunction ??= klass.findInstanceGetter(methodName);
    interpretedFunction ??= klass.findStaticMethod(methodName);
    interpretedFunction ??= klass.findStaticGetter(methodName);
    interpretedFunction ??= klass.findInstanceSetter(methodName);
    interpretedFunction ??= klass.findStaticSetter(methodName);
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
        }, "Error invoking interpreted Method or getter '$methodName' on '${klass.name}'");
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
              bridgedSuperclass.findInstanceMethodAdapter(methodName);

          if (methodAdapter != null) {
            return _tryFunction(() {
              return methodAdapter.call(_visitor!, nativeSuperObject,
                  interpreterPositionalArgs, interpreterNamedArgs);
            }, "Error invoking bridged method '$methodName' on superclass '${bridgedSuperclass.name}'");
          }

          final getterAdapter =
              bridgedSuperclass.findInstanceGetterAdapter(methodName);
          if (getterAdapter != null) {
            return _tryFunction(() {
              return getterAdapter.call(_visitor!, nativeSuperObject);
            }, "Error invoking bridged getter '$methodName' on superclass '${bridgedSuperclass.name}'");
          }
          final setterAdapter =
              bridgedSuperclass.findInstanceSetterAdapter(methodName);
          if (setterAdapter != null) {
            return _tryFunction(() {
              setterAdapter.call(
                  _visitor!, nativeSuperObject, interpreterPositionalArgs[0]);
              return null;
            }, "Error invoking bridged setter '$methodName' on superclass '${bridgedSuperclass.name}'");
          }
        }

        final staticMethodAdapter =
            bridgedSuperclass.findStaticMethodAdapter(methodName);
        if (staticMethodAdapter != null) {
          return _tryFunction(() {
            return staticMethodAdapter.call(
                _visitor!, interpreterPositionalArgs, interpreterNamedArgs);
          }, "Error invoking bridged static method '$methodName' on superclass '${bridgedSuperclass.name}'");
        }

        final getterStaticAdapter =
            bridgedSuperclass.findStaticGetterAdapter(methodName);
        if (getterStaticAdapter != null) {
          return _tryFunction(() {
            return getterStaticAdapter.call(_visitor!);
          }, "Error invoking bridged static getter '$methodName' on superclass '${bridgedSuperclass.name}'");
        }

        final staticSetterAdapter =
            bridgedSuperclass.findStaticSetterAdapter(methodName);
        if (staticSetterAdapter != null) {
          return _tryFunction(() {
            staticSetterAdapter.call(_visitor!, interpreterPositionalArgs[0]);
            return null;
          }, "Error invoking bridged staticsetter '$methodName' on superclass '${bridgedSuperclass.name}'");
        }
      }

      throw RuntimeError(
          'Method or getter "$methodName" not found on instance of class "${klass.name}" or its bridged superclass.');
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
