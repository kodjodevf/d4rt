import '../runtime_interfaces.dart';
import '../exceptions.dart';
import '../interpreter_visitor.dart';
import 'registration.dart' hide BridgedMethodCallable;
import '../callable.dart';

/// Represents a natively defined class but accessible to the interpreter.
class BridgedClass implements RuntimeType {
  final Type nativeType; // Keep nativeType for bridge logic
  @override
  final String name;
  // Number of expected type parameters
  final int typeParameterCount;

  // Support for mixin usage
  final bool canBeUsedAsMixin;

  // Adapters for constructors
  Map<String, BridgedConstructorCallable> constructorAdapters = {};
  // Adapters for instance methods
  Map<String, BridgedMethodAdapter> instanceMethodAdapters = {};
  // Adapters for static members and getters/setters
  Map<String, BridgedStaticMethodAdapter> staticMethodAdapters = {};
  Map<String, BridgedStaticGetterAdapter> staticGetterAdapters = {};
  Map<String, BridgedStaticSetterAdapter> staticSetterAdapters = {};
  Map<String, BridgedInstanceGetterAdapter> instanceGetterAdapters = {};
  Map<String, BridgedInstanceSetterAdapter> instanceSetterAdapters = {};

  BridgedClass(this.nativeType,
      {required this.name,
      this.typeParameterCount = 0,
      this.canBeUsedAsMixin = false});

  @override
  bool isSubtypeOf(RuntimeType other) {
    if (other is BridgedClass) {
      // Current simplification: only checks native type equality.
      // A real check would require more complex logic.
      return nativeType == other.nativeType;
    }

    return false;
  }

  // Method to find a constructor adapter
  BridgedConstructorCallable? findConstructorAdapter(String name) {
    return constructorAdapters[name];
  }

  // Method to find an instance method adapter
  BridgedMethodAdapter? findInstanceMethodAdapter(String name) {
    return instanceMethodAdapters[name];
  }

  // Finders for other adapters
  BridgedStaticMethodAdapter? findStaticMethodAdapter(String name) {
    return staticMethodAdapters[name];
  }

  BridgedStaticGetterAdapter? findStaticGetterAdapter(String name) {
    return staticGetterAdapters[name];
  }

  BridgedStaticSetterAdapter? findStaticSetterAdapter(String name) {
    return staticSetterAdapters[name];
  }

  BridgedInstanceGetterAdapter? findInstanceGetterAdapter(String name) {
    return instanceGetterAdapters[name];
  }

  BridgedInstanceSetterAdapter? findInstanceSetterAdapter(String name) {
    return instanceSetterAdapters[name];
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
