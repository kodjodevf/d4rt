import 'package:d4rt/d4rt.dart';

/// Requires [DangerousPermission.developerTools] before exposing VM-service
/// debugging, inspection and extension capabilities.
void checkDeveloperToolsPermission(InterpreterVisitor visitor) {
  final d4rt = visitor.moduleLoader.d4rt;
  if (d4rt == null) return;

  if (!d4rt.checkPermission({
    'type': 'dangerous',
    'operation': 'developer tools',
  })) {
    throw RuntimeError(
      'Access to dart:developer requires DangerousPermission.developerTools. '
      'Grant it explicitly to allow developer and VM-service APIs.',
    );
  }
}

/// Wraps every constructor, method and property of a `dart:developer` bridge
/// with a runtime permission check.
///
/// Import-time checks alone are insufficient: permissions may be revoked after
/// a library has been loaded, while native objects created earlier remain
/// reachable from interpreted code.
BridgedClass guardDeveloperToolsBridge(BridgedClass definition) {
  final constructors = <String, BridgedConstructorCallable>{};
  for (final entry in definition.constructors.entries) {
    final callback = entry.value;
    constructors[entry.key] = (visitor, positionalArgs, namedArgs) {
      checkDeveloperToolsPermission(visitor);
      return callback(visitor, positionalArgs, namedArgs);
    };
  }

  final methods = <String, BridgedMethodAdapter>{};
  for (final entry in definition.methods.entries) {
    final callback = entry.value;
    methods[entry.key] = (visitor, target, positionalArgs, namedArgs) {
      checkDeveloperToolsPermission(visitor);
      return callback(visitor, target, positionalArgs, namedArgs);
    };
  }

  final staticMethods = <String, BridgedStaticMethodAdapter>{};
  for (final entry in definition.staticMethods.entries) {
    final callback = entry.value;
    staticMethods[entry.key] = (visitor, positionalArgs, namedArgs) {
      checkDeveloperToolsPermission(visitor);
      return callback(visitor, positionalArgs, namedArgs);
    };
  }

  final staticGetters = <String, BridgedStaticGetterAdapter>{};
  for (final entry in definition.staticGetters.entries) {
    final callback = entry.value;
    staticGetters[entry.key] = (visitor) {
      checkDeveloperToolsPermission(visitor);
      return callback(visitor);
    };
  }

  final staticSetters = <String, BridgedStaticSetterAdapter>{};
  for (final entry in definition.staticSetters.entries) {
    final callback = entry.value;
    staticSetters[entry.key] = (visitor, value) {
      checkDeveloperToolsPermission(visitor);
      callback(visitor, value);
    };
  }

  final getters = <String, BridgedInstanceGetterAdapter>{};
  for (final entry in definition.getters.entries) {
    final callback = entry.value;
    getters[entry.key] = (visitor, target) {
      if (visitor == null) {
        throw RuntimeError(
          'Access to dart:developer requires an interpreter context.',
        );
      }
      checkDeveloperToolsPermission(visitor);
      return callback(visitor, target);
    };
  }

  final setters = <String, BridgedInstanceSetterAdapter>{};
  for (final entry in definition.setters.entries) {
    final callback = entry.value;
    setters[entry.key] = (visitor, target, value) {
      if (visitor == null) {
        throw RuntimeError(
          'Access to dart:developer requires an interpreter context.',
        );
      }
      checkDeveloperToolsPermission(visitor);
      callback(visitor, target, value);
    };
  }

  return BridgedClass(
    nativeType: definition.nativeType,
    name: definition.name,
    nativeNames: definition.nativeNames,
    typeParameterCount: definition.typeParameterCount,
    canBeUsedAsMixin: definition.canBeUsedAsMixin,
    isSubtypeOfFunc: definition.isSubtypeOfFunc,
    constructors: constructors,
    methods: methods,
    staticMethods: staticMethods,
    staticGetters: staticGetters,
    staticSetters: staticSetters,
    getters: getters,
    setters: setters,
  );
}
