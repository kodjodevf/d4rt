/// Library Tracking - Canonical source tracking for bridge deduplication.
///
/// Provides a mixin-based system for tracking the canonical source of
/// library elements, enabling automatic deduplication when the same
/// element is re-exported through multiple barrel files.
///
/// ## Problem Solved:
/// When `package_a` exports a class `Foo`, and both `package_b` and
/// `package_c` re-export it, we need to recognize that all three
/// refer to the same `Foo` and not register it multiple times.
///
/// ## Usage:
/// ```dart
/// // Wrap library elements with source tracking
/// final trackedClass = BridgedClassEntry(
///   myBridgedClass,
///   origin: SourceOrigin.fromUri('package:my_pkg/src/foo.dart'),
/// );
///
/// // Use the registry to deduplicate
/// final registry = LibraryRegistry();
/// registry.addClass(trackedClass, 'package:my_pkg/my_pkg.dart');
/// ```
library;

// =============================================================================
// SOURCE ORIGIN
// =============================================================================

/// Represents the canonical origin of a library element.
///
/// Two elements from different import paths that share the same
/// [SourceOrigin] are considered duplicates.
class SourceOrigin implements Comparable<SourceOrigin> {
  /// The canonical package URI where this element is defined.
  /// Format: `package:pkg_name/path/to/source.dart`
  final String canonicalUri;

  /// The element name within the source file.
  final String elementName;

  /// Creates a source origin.
  const SourceOrigin({
    required this.canonicalUri,
    required this.elementName,
  });

  /// Creates from a full URI string.
  factory SourceOrigin.fromUri(String uri, String elementName) {
    // Normalize the URI
    final normalized = _normalizeUri(uri);
    return SourceOrigin(canonicalUri: normalized, elementName: elementName);
  }

  /// Unique identifier for this origin.
  String get id => '$canonicalUri#$elementName';

  /// Normalizes a URI for consistent comparison.
  static String _normalizeUri(String uri) {
    // Remove trailing slashes and normalize path separators
    var normalized = uri.replaceAll(r'\', '/');
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SourceOrigin && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  int compareTo(SourceOrigin other) => id.compareTo(other.id);

  @override
  String toString() => 'SourceOrigin($id)';
}

// =============================================================================
// TRACKED ENTRY MIXIN
// =============================================================================

/// Mixin that adds source tracking to any library element.
mixin SourceTracked {
  /// The canonical source origin of this element.
  SourceOrigin? get origin;

  /// Whether this element has source tracking.
  bool get hasOrigin => origin != null;

  /// Checks if this element has the same origin as another.
  bool hasSameOrigin(SourceTracked other) {
    if (!hasOrigin || !other.hasOrigin) return false;
    return origin == other.origin;
  }
}

// =============================================================================
// TRACKED WRAPPER CLASSES
// =============================================================================

/// Wrapper for tracked bridged classes.
class TrackedBridgedClass with SourceTracked {
  /// The wrapped bridged class.
  final dynamic bridgedClass;

  @override
  final SourceOrigin? origin;

  /// Import paths where this class is accessible.
  final Set<String> importPaths = {};

  TrackedBridgedClass(this.bridgedClass, {this.origin});

  /// Adds an import path where this class is accessible.
  void addImportPath(String path) => importPaths.add(path);

  /// The class name.
  String get name => bridgedClass.name as String;

  @override
  String toString() => 'TrackedBridgedClass($name, origin: $origin)';
}

/// Wrapper for tracked bridged enums.
class TrackedBridgedEnum with SourceTracked {
  /// The wrapped bridged enum definition.
  final dynamic enumDefinition;

  @override
  final SourceOrigin? origin;

  /// Import paths where this enum is accessible.
  final Set<String> importPaths = {};

  TrackedBridgedEnum(this.enumDefinition, {this.origin});

  /// Adds an import path where this enum is accessible.
  void addImportPath(String path) => importPaths.add(path);

  /// The enum name.
  String get name => enumDefinition.name as String;

  @override
  String toString() => 'TrackedBridgedEnum($name, origin: $origin)';
}

/// Wrapper for tracked library functions.
class TrackedFunction with SourceTracked {
  /// The function name.
  final String name;

  /// The native function implementation.
  final dynamic function;

  @override
  final SourceOrigin? origin;

  /// Import paths where this function is accessible.
  final Set<String> importPaths = {};

  /// Optional function signature for documentation.
  final String? signature;

  TrackedFunction(
    this.name,
    this.function, {
    this.origin,
    this.signature,
  });

  void addImportPath(String path) => importPaths.add(path);

  @override
  String toString() => 'TrackedFunction($name, origin: $origin)';
}

/// Wrapper for tracked library variables.
class TrackedVariable with SourceTracked {
  /// The variable name.
  final String name;

  /// The variable value.
  final Object? value;

  @override
  final SourceOrigin? origin;

  /// Import paths where this variable is accessible.
  final Set<String> importPaths = {};

  TrackedVariable(this.name, this.value, {this.origin});

  void addImportPath(String path) => importPaths.add(path);

  @override
  String toString() => 'TrackedVariable($name, origin: $origin)';
}

/// Wrapper for tracked library getters.
class TrackedGetter with SourceTracked {
  /// The getter name.
  final String name;

  /// The getter function.
  final Object? Function() getter;

  @override
  final SourceOrigin? origin;

  /// Import paths where this getter is accessible.
  final Set<String> importPaths = {};

  TrackedGetter(this.name, this.getter, {this.origin});

  void addImportPath(String path) => importPaths.add(path);

  @override
  String toString() => 'TrackedGetter($name, origin: $origin)';
}

// =============================================================================
// LIBRARY REGISTRY
// =============================================================================

/// Registry for tracking and deduplicating library elements.
///
/// Maintains a global view of all registered elements and their
/// canonical sources to prevent duplicate registrations.
class LibraryRegistry {
  /// Tracked classes by their origin ID.
  final Map<String, TrackedBridgedClass> _classes = {};

  /// Tracked enums by their origin ID.
  final Map<String, TrackedBridgedEnum> _enums = {};

  /// Tracked functions by their origin ID.
  final Map<String, TrackedFunction> _functions = {};

  /// Tracked variables by their origin ID.
  final Map<String, TrackedVariable> _variables = {};

  /// Tracked getters by their origin ID.
  final Map<String, TrackedGetter> _getters = {};

  /// Statistics about deduplication.
  final _stats = RegistryStats._();

  /// Registers a bridged class, returning whether it was newly added.
  bool addClass(
    dynamic bridgedClass,
    String importPath, {
    SourceOrigin? origin,
  }) {
    final name = bridgedClass.name as String;
    final key = origin?.id ?? 'untracked:$importPath#$name';

    if (_classes.containsKey(key)) {
      _classes[key]!.addImportPath(importPath);
      _stats._duplicatesSkipped++;
      return false;
    }

    final tracked = TrackedBridgedClass(bridgedClass, origin: origin);
    tracked.addImportPath(importPath);
    _classes[key] = tracked;
    _stats._classesRegistered++;
    return true;
  }

  /// Registers a bridged enum, returning whether it was newly added.
  bool addEnum(
    dynamic enumDefinition,
    String importPath, {
    SourceOrigin? origin,
  }) {
    final name = enumDefinition.name as String;
    final key = origin?.id ?? 'untracked:$importPath#$name';

    if (_enums.containsKey(key)) {
      _enums[key]!.addImportPath(importPath);
      _stats._duplicatesSkipped++;
      return false;
    }

    final tracked = TrackedBridgedEnum(enumDefinition, origin: origin);
    tracked.addImportPath(importPath);
    _enums[key] = tracked;
    _stats._enumsRegistered++;
    return true;
  }

  /// Registers a function, returning whether it was newly added.
  bool addFunction(
    String name,
    dynamic function,
    String importPath, {
    SourceOrigin? origin,
    String? signature,
  }) {
    final key = origin?.id ?? 'untracked:$importPath#$name';

    if (_functions.containsKey(key)) {
      _functions[key]!.addImportPath(importPath);
      _stats._duplicatesSkipped++;
      return false;
    }

    final tracked =
        TrackedFunction(name, function, origin: origin, signature: signature);
    tracked.addImportPath(importPath);
    _functions[key] = tracked;
    _stats._functionsRegistered++;
    return true;
  }

  /// Registers a variable, returning whether it was newly added.
  bool addVariable(
    String name,
    Object? value,
    String importPath, {
    SourceOrigin? origin,
  }) {
    final key = origin?.id ?? 'untracked:$importPath#$name';

    if (_variables.containsKey(key)) {
      _variables[key]!.addImportPath(importPath);
      _stats._duplicatesSkipped++;
      return false;
    }

    final tracked = TrackedVariable(name, value, origin: origin);
    tracked.addImportPath(importPath);
    _variables[key] = tracked;
    _stats._variablesRegistered++;
    return true;
  }

  /// Registers a getter, returning whether it was newly added.
  bool addGetter(
    String name,
    Object? Function() getter,
    String importPath, {
    SourceOrigin? origin,
  }) {
    final key = origin?.id ?? 'untracked:$importPath#$name';

    if (_getters.containsKey(key)) {
      _getters[key]!.addImportPath(importPath);
      _stats._duplicatesSkipped++;
      return false;
    }

    final tracked = TrackedGetter(name, getter, origin: origin);
    tracked.addImportPath(importPath);
    _getters[key] = tracked;
    _stats._gettersRegistered++;
    return true;
  }

  /// Gets all registered classes.
  Iterable<TrackedBridgedClass> get classes => _classes.values;

  /// Gets all registered enums.
  Iterable<TrackedBridgedEnum> get enums => _enums.values;

  /// Gets all registered functions.
  Iterable<TrackedFunction> get functions => _functions.values;

  /// Gets all registered variables.
  Iterable<TrackedVariable> get variables => _variables.values;

  /// Gets all registered getters.
  Iterable<TrackedGetter> get getters => _getters.values;

  /// Gets a class by name (first match).
  TrackedBridgedClass? getClass(String name) {
    return _classes.values.where((c) => c.name == name).firstOrNull;
  }

  /// Gets an enum by name (first match).
  TrackedBridgedEnum? getEnum(String name) {
    return _enums.values.where((e) => e.name == name).firstOrNull;
  }

  /// Gets a function by name (first match).
  TrackedFunction? getFunction(String name) {
    return _functions.values.where((f) => f.name == name).firstOrNull;
  }

  /// Gets registration statistics.
  RegistryStats get stats => _stats;

  /// Clears all registrations.
  void clear() {
    _classes.clear();
    _enums.clear();
    _functions.clear();
    _variables.clear();
    _getters.clear();
    _stats._reset();
  }

  @override
  String toString() {
    return 'LibraryRegistry('
        'classes: ${_classes.length}, '
        'enums: ${_enums.length}, '
        'functions: ${_functions.length}, '
        'variables: ${_variables.length}, '
        'getters: ${_getters.length}'
        ')';
  }
}

// =============================================================================
// REGISTRY STATISTICS
// =============================================================================

/// Statistics about library registry operations.
class RegistryStats {
  int _classesRegistered = 0;
  int _enumsRegistered = 0;
  int _functionsRegistered = 0;
  int _variablesRegistered = 0;
  int _gettersRegistered = 0;
  int _duplicatesSkipped = 0;

  RegistryStats._();

  int get classesRegistered => _classesRegistered;
  int get enumsRegistered => _enumsRegistered;
  int get functionsRegistered => _functionsRegistered;
  int get variablesRegistered => _variablesRegistered;
  int get gettersRegistered => _gettersRegistered;
  int get duplicatesSkipped => _duplicatesSkipped;

  int get totalRegistered =>
      _classesRegistered +
      _enumsRegistered +
      _functionsRegistered +
      _variablesRegistered +
      _gettersRegistered;

  void _reset() {
    _classesRegistered = 0;
    _enumsRegistered = 0;
    _functionsRegistered = 0;
    _variablesRegistered = 0;
    _gettersRegistered = 0;
    _duplicatesSkipped = 0;
  }

  @override
  String toString() {
    return 'RegistryStats('
        'registered: $totalRegistered, '
        'duplicatesSkipped: $duplicatesSkipped'
        ')';
  }
}

// =============================================================================
// GLOBAL REGISTRY INSTANCE
// =============================================================================

/// Global library registry for application-wide deduplication.
final globalLibraryRegistry = LibraryRegistry();
