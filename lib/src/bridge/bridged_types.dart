import '../runtime_interfaces.dart';
import '../exceptions.dart';
import '../interpreter_visitor.dart';
import 'registration.dart' hide BridgedMethodCallable;
import '../callable.dart';

/// Represents a natively defined class that is accessible to the interpreter.
///
/// BridgedClass allows native Dart classes to be used within interpreted code
/// by providing metadata and adapters for constructors, methods, getters, and setters.
/// This enables seamless integration between native and interpreted environments.
///
/// ## Example:
/// ```dart
/// final bridgedString = BridgedClass(
///   String,
///   name: 'String',
///   constructors: {
///     '': StringConstructor(),
///   },
///   methods: {
///     'toLowerCase': StringToLowerCaseMethod(),
///   },
/// );
/// ```
class BridgedClass implements RuntimeType {
  /// The native Dart type this bridge represents.
  final Type nativeType; // Keep nativeType for bridge logic

  @override

  /// The name of this class as it appears in interpreted code.
  final String name;

  /// Additional native class names that should map to this bridged class.
  /// This is essential for mapping Dart's internal implementation classes to their public interfaces.
  ///
  /// For example, Stream has many internal implementations like '_MultiStream', '_ControllerStream',
  /// '_BroadcastStream', etc. When the interpreter encounters these native objects at runtime,
  /// it needs to know they should be treated as 'Stream' instances.
  ///
  /// Without nativeNames:
  /// - runtime error: "No registered bridged class found for native type _MultiStream"
  ///
  /// With nativeNames: ['_MultiStream', '_ControllerStream', ...]:
  /// - The environment can map these internal types to the Stream bridge
  /// - Methods like toList(), listen(), etc. become available on these objects
  ///
  /// Used by Environment.toBridgedClass() to perform fallback lookups when
  /// the exact nativeType doesn't match any registered bridge.
  final List<String>? nativeNames;

  /// A function that determines if the current runtime type is a subtype of another runtime type.
  ///
  /// This function is used to perform subtype checking at runtime, which is essential
  /// for type safety and polymorphism in the bridge system.
  ///
  /// Parameters:
  /// - [other]: The runtime type to check against for subtype relationship
  /// - [value]: Optional value that can be used for additional context during subtype checking
  ///
  /// Returns:
  /// - `true` if this type is a subtype of [other]
  /// - `false` if this type is not a subtype of [other]
  ///
  /// The function can be null if subtype checking is not supported or not needed
  /// for this particular runtime type.
  final bool Function(BridgedClass other, {Object? value})? isSubtypeOfFunc;
  // Number of expected type parameters
  final int typeParameterCount;

  // Support for mixin usage
  final bool canBeUsedAsMixin;

  // Adapters for constructors
  Map<String, BridgedConstructorCallable> constructors = {};
  // Adapters for instance methods
  Map<String, BridgedMethodAdapter> methods = {};
  // Adapters for static members and getters/setters
  Map<String, BridgedStaticMethodAdapter> staticMethods = {};
  Map<String, BridgedStaticGetterAdapter> staticGetters = {};
  Map<String, BridgedStaticSetterAdapter> staticSetters = {};
  Map<String, BridgedInstanceGetterAdapter> getters = {};
  Map<String, BridgedInstanceSetterAdapter> setters = {};

  BridgedClass(
      {required this.nativeType,
      required this.name,
      this.nativeNames,
      this.typeParameterCount = 0,
      this.canBeUsedAsMixin = false,
      this.constructors = const {},
      this.staticMethods = const {},
      this.staticGetters = const {},
      this.staticSetters = const {},
      this.methods = const {},
      this.getters = const {},
      this.setters = const {},
      this.isSubtypeOfFunc});

  @override
  bool isSubtypeOf(RuntimeType other, {Object? value}) {
    if (other is BridgedClass) {
      if (isSubtypeOfFunc != null) {
        return isSubtypeOfFunc!.call(other, value: value);
      }
      if (name == 'num') {
        final isSubtype = switch (other.name) {
          'num' => true,
          'int' => true,
          'double' => true,
          _ => false,
        };
        return isSubtype;
      }

      return nativeType == other.nativeType;
    }

    return false;
  }

  // Method to find a constructor adapter
  BridgedConstructorCallable? findConstructorAdapter(String name) {
    return constructors[name];
  }

  // Method to find an instance method adapter
  BridgedMethodAdapter? findInstanceMethodAdapter(String name) {
    return methods[name];
  }

  // Finders for other adapters
  BridgedStaticMethodAdapter? findStaticMethodAdapter(String name) {
    return staticMethods[name];
  }

  BridgedStaticGetterAdapter? findStaticGetterAdapter(String name) {
    return staticGetters[name];
  }

  BridgedStaticSetterAdapter? findStaticSetterAdapter(String name) {
    return staticSetters[name];
  }

  BridgedInstanceGetterAdapter? findInstanceGetterAdapter(String name) {
    return getters[name];
  }

  BridgedInstanceSetterAdapter? findInstanceSetterAdapter(String name) {
    return setters[name];
  }
}

/// Represents an instance of a bridged native class.
class BridgedInstance<T extends Object> implements RuntimeValue {
  final BridgedClass bridgedClass;
  final T nativeObject;
  // Stores the type arguments provided at creation
  final List<RuntimeType> typeArguments;

  // Main constructor
  BridgedInstance(this.bridgedClass, this.nativeObject,
      {this.typeArguments = const []}); // Removed local initialization

  @override
  RuntimeType get valueType => bridgedClass;

  @override
  Object? get(String name) {
    // 1. Check if it's a BRIDGED instance METHOD
    final methodAdapter = bridgedClass.findInstanceMethodAdapter(name);
    if (methodAdapter != null) {
      // Return a Callable bound to this instance and the adapter
      return BridgedMethodCallable(this, methodAdapter, name);
    }

    // This should be handled by visitors (PrefixedIdentifier, PropertyAccess)
    // for them to have access to the visitor if necessary.
    // The logic here is simplified and could be incorrect if a getter
    // would need to be returned as a value.

    // 3. If neither method nor getter found, throw an error
    throw RuntimeError(
        "Undefined property or method '$name' on bridged instance of '${bridgedClass.name}'");
  }

  @override
  void set(String name, Object? value, [InterpreterVisitor? visitor]) {
    // Visitor is optional
    throw UnimplementedError(
        "set('$name', ...) not implemented for BridgedInstance of '${bridgedClass.name}'");
  }

  @override
  String toString() {
    // Delegate to the native toString() method? Or just a representation?
    try {
      return nativeObject.toString();
    } catch (_) {
      return "Instance of native '${bridgedClass.name}'";
    }
  }
}

/// Represents a generic type parameter like T, U, etc.
class TypeParameter implements RuntimeType {
  @override
  final String name;
  final RuntimeType?
      bound; // The extends clause if any (e.g., T extends Object)

  TypeParameter(this.name, {this.bound});

  @override
  bool isSubtypeOf(RuntimeType other, {Object? value}) {
    // For now, type parameters accept any type as a subtype
    // This is because we don't have full generic type inference yet
    // In a real type system, this would be more sophisticated
    return true;
  }

  @override
  String toString() => name;
}
