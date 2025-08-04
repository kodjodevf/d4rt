import '../interpreter_visitor.dart'; // Import InterpreterVisitor for adapters
import 'bridged_enum.dart';

// The idea is that these functions will encapsulate the native call
// and type conversion.

/// Calls a native constructor.
typedef BridgedConstructorCallable = Object? Function(
    InterpreterVisitor
        visitor, // For potential evaluation of args or access env
    List<Object?> positionalArgs, // Interpretted arguments
    Map<String, Object?> namedArgs // Interpretted arguments
    );

/// Calls a native method/getter/setter.
typedef BridgedMethodCallable = Object? Function(
    InterpreterVisitor visitor,
    Object
        target, // The native target object (for instance methods/getters/setters)
    List<Object?> positionalArgs,
    Map<String, Object?> namedArgs);

typedef BridgedMethodAdapter = Object? Function(
    InterpreterVisitor visitor, // The current visitor
    Object target, // The native target object to call the method on
    List<Object?> positionalArguments, // Interpretted arguments
    Map<String, Object?> namedArguments // Interpretted arguments
    );

/// Adapter for bridged static methods.
/// Takes interpreter context, positional args, named args.
/// Returns the result of the native static method call.
typedef BridgedStaticMethodAdapter = Object? Function(
    InterpreterVisitor visitor,
    List<Object?> positionalArguments,
    Map<String, Object?> namedArguments);

/// Adapter for bridged static getters.
/// Takes interpreter context.
/// Returns the result of the native static getter.
typedef BridgedStaticGetterAdapter = Object? Function(
    InterpreterVisitor visitor);

/// Adapter for bridged static setters.
/// Takes interpreter context, the value to set.
typedef BridgedStaticSetterAdapter = void Function(
    InterpreterVisitor visitor, Object? value);

/// Adapter for bridged instance getters.
/// Takes interpreter context, the native target object.
/// Returns the result of the native instance getter.
typedef BridgedInstanceGetterAdapter = Object? Function(
    InterpreterVisitor? visitor, Object target);

/// Adapter for bridged instance setters.
/// Takes interpreter context, the native target object, the value to set.
typedef BridgedInstanceSetterAdapter = void Function(
    InterpreterVisitor? visitor, Object target, Object? value);

class BridgedEnumDefinition<T extends Enum> {
  /// The name under which the enum will be known in the interpreter.
  final String name;

  /// The list of native enum values (e.g. `MyEnum.values`).
  final List<T> values;

  /// Adapters for instance getters on enum values.
  /// The key is the getter name.
  final Map<String, BridgedInstanceGetterAdapter> getters;

  /// Adapters for instance methods on enum values.
  /// The key is the method name.
  final Map<String, BridgedMethodAdapter> methods;

  BridgedEnumDefinition({
    required this.name,
    required this.values,
    this.getters = const {},
    this.methods = const {},
  }) {
    // Validation: Ensure the value list is not empty
    if (values.isEmpty) {
      throw ArgumentError('Cannot bridge an enum with no values: $name');
    }
  }

  /// Builds the [BridgedEnum] object from this definition.
  BridgedEnum buildBridgedEnum() {
    // Placeholder for the main enum, will be replaced by the real instance after creation.
    // This is necessary because BridgedEnumValue needs a reference to its type,
    // but the full type (BridgedEnum) needs the value list.
    final placeholderEnum = BridgedEnum(name, {});
    final bridgedValues = <String, BridgedEnumValue>{};

    // Share instance adapters with all created values
    placeholderEnum.getters = getters;
    placeholderEnum.methods = methods;

    for (final nativeValue in values) {
      final valueName = nativeValue.name; // Use the .name getter of Dart enums
      final index = nativeValue.index;

      // Create the bridged value for this enum element, using the placeholder
      // Note: Adapters are also passed here
      final bridgedValue = BridgedEnumValue(
        placeholderEnum, // Pass the placeholder initially
        valueName,
        index,
        nativeValue, // Store the native value
        getters: getters, // Pass the adapters
        methods: methods, // Pass the adapters
      );

      bridgedValues[valueName] = bridgedValue;
    }

    // Create the main BridgedEnum object with the finalized value map.
    final bridgedEnum = BridgedEnum(name, bridgedValues);

    // Copy adapters into the final instance as well
    bridgedEnum.getters = getters;
    bridgedEnum.methods = methods;

    final finalBridgedValues = <String, BridgedEnumValue>{};
    for (final nativeValue in values) {
      final valueName = nativeValue.name;
      final index = nativeValue.index;
      finalBridgedValues[valueName] = BridgedEnumValue(
        bridgedEnum,
        valueName,
        index,
        nativeValue,
        getters: getters,
        methods: methods,
      );
    }

    // Update the value map in the final BridgedEnum.
    bridgedEnum.values.clear();
    bridgedEnum.values.addAll(finalBridgedValues);

    return bridgedEnum;
  }
}
