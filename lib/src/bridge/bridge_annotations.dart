/// Bridge Annotations - Metadata annotations for customizing bridge generation.
///
/// Provides annotations that can be applied to classes extending D4rt bridges
/// to customize their behavior, override specific members, or provide
/// additional configuration.
///
/// ## Usage:
/// ```dart
/// @BridgeOverride(library: 'package:my_pkg/src/api.dart')
/// class MyApiBridge extends BaseBridge {
///   @OverrideMethod('complexOperation')
///   static Object? handleComplexOperation(
///     InterpreterVisitor visitor,
///     Object? target,
///     List<Object?> args,
///     Map<String, Object?> namedArgs,
///   ) {
///     // Custom implementation
///   }
/// }
/// ```
library;

// =============================================================================
// PRIMARY BRIDGE ANNOTATIONS
// =============================================================================

/// Marks a class or enum to be automatically bridged by the generator.
///
/// When using `build_runner`, classes annotated with `@D4rtBridge()` will have
/// their bridge code generated in a `.bridge.g.dart` file.
class D4rtBridge {
  /// Whether to include private members in the bridge.
  final bool includePrivate;

  /// Custom name for the generated bridge variable.
  final String? bridgeName;

  /// Custom library URI for the bridge registration.
  /// If not provided, the generator uses the source filename.
  final String? libraryUri;

  const D4rtBridge({
    this.includePrivate = false,
    this.bridgeName,
    this.libraryUri,
  });
}

/// Marks a class as a bridge override provider.
///
/// Apply this to classes that provide custom implementations for bridge
/// members that cannot be auto-generated correctly.
///
/// ## Parameters:
/// - [library]: The full package URI of the source library.
///   Format: `package:package_name/path/to/file.dart`
/// - [targetClass]: Optional specific class name to override.
///   Use when multiple libraries have classes with the same name.
/// - [priority]: Override priority when multiple overrides exist.
///   Higher values take precedence (default: 0).
///
/// ## Example:
/// ```dart
/// // Override all generated bridges for a library
/// @BridgeOverride(library: 'package:my_pkg/src/complex.dart')
/// class ComplexBridge extends BaseBridge { ... }
///
/// // Override a specific class in a library
/// @BridgeOverride(
///   library: 'package:my_pkg/src/utils.dart',
///   targetClass: 'StringHelper',
/// )
/// class StringHelperBridge extends BaseBridge { ... }
/// ```
class BridgeOverride {
  /// The package URI of the library containing elements to override.
  final String library;

  /// Optional specific class name to override.
  final String? targetClass;

  /// Priority for override resolution (higher = takes precedence).
  final int priority;

  const BridgeOverride({
    required this.library,
    this.targetClass,
    this.priority = 0,
  });
}

// =============================================================================
// MEMBER-LEVEL ANNOTATIONS
// =============================================================================

/// Marks a static method as an override for a specific bridge method.
///
/// Apply to static methods within a [BridgeOverride] class to provide
/// custom implementations for specific methods.
///
/// The method signature should match:
/// ```dart
/// static Object? methodName(
///   InterpreterVisitor visitor,
///   Object? target,
///   List<Object?> positionalArgs,
///   Map<String, Object?> namedArgs,
/// )
/// ```
class OverrideMethod {
  /// The name of the method to override in the target class.
  final String name;

  /// Optional reason for the override (for documentation).
  final String? reason;

  const OverrideMethod(this.name, {this.reason});
}

/// Marks a static method as an override for a getter.
class OverrideGetter {
  /// The name of the getter to override.
  final String name;

  /// Optional reason for the override.
  final String? reason;

  const OverrideGetter(this.name, {this.reason});
}

/// Marks a static method as an override for a setter.
class OverrideSetter {
  /// The name of the setter to override.
  final String name;

  /// Optional reason for the override.
  final String? reason;

  const OverrideSetter(this.name, {this.reason});
}

/// Marks a static method as an override for a constructor.
class OverrideConstructor {
  /// The constructor name (empty string for default constructor).
  final String name;

  /// Optional reason for the override.
  final String? reason;

  const OverrideConstructor([this.name = '', this.reason]);
}

/// Marks a static method as an override for an operator.
class OverrideOperator {
  /// The operator symbol (e.g., '+', '[]', '==').
  final String operator;

  /// Optional reason for the override.
  final String? reason;

  const OverrideOperator(this.operator, {this.reason});
}

// =============================================================================
// CONFIGURATION ANNOTATIONS
// =============================================================================

/// Configures additional native type names for a bridged class.
///
/// Use this when a class has internal implementation types that should
/// be mapped to the public bridge (e.g., Stream's internal implementations).
///
/// ## Example:
/// ```dart
/// @BridgeOverride(library: 'dart:async')
/// @NativeTypeNames(['_ControllerStream', '_BroadcastStream', '_MultiStream'])
/// class StreamBridge extends BaseBridge { ... }
/// ```
class NativeTypeNames {
  /// List of native type names to map to this bridge.
  final List<String> names;

  const NativeTypeNames(this.names);
}

/// Excludes specific members from bridge generation.
///
/// Apply to a bridge override class to prevent certain members
/// from being generated at all.
class ExcludeMembers {
  /// List of member names to exclude.
  final List<String> members;

  /// Optional reason for exclusion.
  final String? reason;

  const ExcludeMembers(this.members, {this.reason});
}

/// Specifies that a class should use type erasure for generics.
///
/// When applied, generic type parameters in the class will be
/// replaced with their bounds (or dynamic) during bridge generation.
class UseTypeErasure {
  /// Map of type parameter name to its erased type.
  /// If null, uses the declared bound or dynamic.
  final Map<String, String>? typeMapping;

  const UseTypeErasure([this.typeMapping]);
}

/// Marks a member as requiring special async handling.
class AsyncBridge {
  /// Whether the result should be awaited automatically.
  final bool autoAwait;

  const AsyncBridge({this.autoAwait = true});
}

// =============================================================================
// DOCUMENTATION ANNOTATIONS
// =============================================================================

/// Provides additional documentation for generated bridges.
class BridgeDoc {
  /// Description to include in generated code.
  final String description;

  /// Example usage code.
  final String? example;

  /// See also references.
  final List<String>? seeAlso;

  const BridgeDoc(this.description, {this.example, this.seeAlso});
}

/// Marks a bridge as deprecated.
class DeprecatedBridge {
  /// Deprecation message.
  final String message;

  /// Suggested replacement.
  final String? replaceWith;

  /// Version when deprecated.
  final String? since;

  const DeprecatedBridge(this.message, {this.replaceWith, this.since});
}

// =============================================================================
// ABSTRACT BASE BRIDGE CLASS
// =============================================================================

/// Base class for bridge override implementations.
///
/// Extend this class and annotate with [BridgeOverride] to provide
/// custom implementations for specific bridge members.
///
/// ## Example:
/// ```dart
/// @BridgeOverride(library: 'package:my_pkg/src/api.dart')
/// class MyApiBridge extends BaseBridge {
///   @override
///   String get sourceLibrary => 'package:my_pkg/src/api.dart';
///
///   @OverrideMethod('fetchData')
///   static Object? handleFetchData(
///     InterpreterVisitor visitor,
///     Object? target,
///     List<Object?> positional,
///     Map<String, Object?> named,
///   ) {
///     // Custom implementation for methods that can't be auto-generated
///     return null;
///   }
/// }
/// ```
abstract class BaseBridge {
  /// The source library this bridge overrides.
  String get sourceLibrary;

  /// Optional: The specific class this bridge overrides.
  String? get targetClass => null;

  const BaseBridge();
}

// =============================================================================
// REGISTRATION HELPERS
// =============================================================================

/// Configuration for bridge override registration.
class BridgeOverrideConfig {
  /// Map of library URI to override classes.
  final Map<String, List<Type>> _overrides = {};

  /// Registers an override class for a library.
  void register<T extends BaseBridge>(String library) {
    _overrides.putIfAbsent(library, () => []).add(T);
  }

  /// Gets all registered overrides for a library.
  List<Type> getOverrides(String library) {
    return _overrides[library] ?? [];
  }

  /// Checks if any overrides are registered for a library.
  bool hasOverrides(String library) {
    return _overrides.containsKey(library) && _overrides[library]!.isNotEmpty;
  }

  /// Gets all registered libraries.
  Iterable<String> get libraries => _overrides.keys;
}

/// Global registry for bridge overrides.
final bridgeOverrideRegistry = BridgeOverrideConfig();
