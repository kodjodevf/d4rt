/// Library Management Integration - Connects LibraryRegistry with D4rt.
///
/// Provides a bridge between D4rt's registration system and the deduplication
/// tracking offered by LibraryRegistry. Enables automatic tracking of all
/// bridged classes, enums, and functions with source origin information.
library;

import 'bridged_types.dart';
import 'library_tracking.dart';

// =============================================================================
// BRIDGE REGISTRY MANAGER
// =============================================================================

/// Manages bridge registrations with automatic deduplication and source tracking.
///
/// This class acts as a facade between D4rt's registration methods and the
/// LibraryRegistry deduplication system. It ensures that all bridges are
/// tracked with their canonical sources and automatically prevents duplicates.
class BridgeRegistryManager {
  /// The underlying registry for tracking and deduplication.
  final LibraryRegistry registry;

  /// Constructor with optional custom registry.
  BridgeRegistryManager([LibraryRegistry? customRegistry])
      : registry = customRegistry ?? LibraryRegistry();

  /// Registers a bridged class with automatic deduplication.
  ///
  /// Tracks the source origin and import path for later deduplication.
  /// Returns true if this is a new registration, false if it was a duplicate.
  ///
  /// [bridgedClass] - The BridgedClass to register
  /// [libraryPath] - The import path where this class is available
  /// [sourceUri] - Optional canonical source URI (auto-detected if not provided)
  bool registerClass(
    BridgedClass bridgedClass,
    String libraryPath, {
    String? sourceUri,
  }) {
    final origin = sourceUri != null
        ? SourceOrigin.fromUri(sourceUri, bridgedClass.name)
        : _inferOrigin(libraryPath, bridgedClass.name);

    return registry.addClass(bridgedClass, libraryPath, origin: origin);
  }

  /// Registers a bridged enum with automatic deduplication.
  bool registerEnum(
    dynamic enumDefinition,
    String libraryPath, {
    String? sourceUri,
  }) {
    final name = enumDefinition.name as String;
    final origin = sourceUri != null
        ? SourceOrigin.fromUri(sourceUri, name)
        : _inferOrigin(libraryPath, name);

    return registry.addEnum(enumDefinition, libraryPath, origin: origin);
  }

  /// Registers a bridged function with automatic deduplication.
  bool registerFunction(
    String name,
    dynamic function,
    String libraryPath, {
    String? sourceUri,
    String? signature,
  }) {
    final origin = sourceUri != null
        ? SourceOrigin.fromUri(sourceUri, name)
        : _inferOrigin(libraryPath, name);

    return registry.addFunction(
      name,
      function,
      libraryPath,
      origin: origin,
      signature: signature,
    );
  }

  /// Infers the canonical source URI from library path and element name.
  ///
  /// For re-export detection, this derives a probable source based on
  /// common patterns (e.g., 'package:foo/foo.dart', 'src/internals.dart').
  SourceOrigin _inferOrigin(String libraryPath, String elementName) {
    // Try to infer from common patterns
    if (libraryPath.startsWith('package:')) {
      // Extract package name
      final parts = libraryPath.split('/');
      if (parts.length >= 2) {
        // Assume source is typically in src/ or at package root
        final inferredSource =
            'package:${parts[0].split(':')[1]}/src/$elementName.dart';
        return SourceOrigin.fromUri(inferredSource, elementName);
      }
    }

    // Fallback: use library path as-is
    return SourceOrigin.fromUri(libraryPath, elementName);
  }

  /// Gets all registered classes.
  Iterable<TrackedBridgedClass> get classes => registry.classes;

  /// Gets all registered enums.
  Iterable<TrackedBridgedEnum> get enums => registry.enums;

  /// Gets all registered functions.
  Iterable<TrackedFunction> get functions => registry.functions;

  /// Gets registry statistics.
  RegistryStats get stats => registry.stats;

  /// Clears all registrations.
  void clear() => registry.clear();

  @override
  String toString() => 'BridgeRegistryManager($registry)';
}

// =============================================================================
// REGISTRATION CONTEXT
// =============================================================================

/// Context for bulk bridge registration with source tracking.
///
/// Simplifies registering multiple bridges from the same source with
/// automatic source origin inference.
///
/// ## Usage:
/// ```dart
/// final context = RegistrationContext(
///   sourceUri: 'package:my_pkg/src/bridges.dart',
///   manager: myManager,
/// );
///
/// context.addClass(myClass, 'package:my_pkg/my_pkg.dart');
/// context.addEnum(myEnum, 'package:my_pkg/my_pkg.dart');
/// context.addFunction('helper', helperFunc, 'package:my_pkg/my_pkg.dart');
/// ```
class RegistrationContext {
  /// The canonical source URI for all registrations in this context.
  final String sourceUri;

  /// The registry manager to use for registrations.
  final BridgeRegistryManager manager;

  /// Number of successful registrations in this context.
  int _registered = 0;

  /// Number of duplicate registrations skipped.
  int _duplicatesSkipped = 0;

  RegistrationContext({
    required this.sourceUri,
    required this.manager,
  });

  /// Registers a class with source context.
  void addClass(BridgedClass bridgedClass, String libraryPath) {
    final added = manager.registerClass(
      bridgedClass,
      libraryPath,
      sourceUri: sourceUri,
    );
    if (added) {
      _registered++;
    } else {
      _duplicatesSkipped++;
    }
  }

  /// Registers an enum with source context.
  void addEnum(dynamic enumDefinition, String libraryPath) {
    final added = manager.registerEnum(
      enumDefinition,
      libraryPath,
      sourceUri: sourceUri,
    );
    if (added) {
      _registered++;
    } else {
      _duplicatesSkipped++;
    }
  }

  /// Registers a function with source context.
  void addFunction(
    String name,
    dynamic function,
    String libraryPath, {
    String? signature,
  }) {
    final added = manager.registerFunction(
      name,
      function,
      libraryPath,
      sourceUri: sourceUri,
      signature: signature,
    );
    if (added) {
      _registered++;
    } else {
      _duplicatesSkipped++;
    }
  }

  /// Gets summary of registrations in this context.
  String getSummary() {
    return 'Registered: $_registered, Duplicates skipped: $_duplicatesSkipped';
  }

  @override
  String toString() => 'RegistrationContext($sourceUri) - ${getSummary()}';
}

// =============================================================================
// GLOBAL MANAGER INSTANCE
// =============================================================================

/// Global bridge registry manager for application-wide bridge management.
final globalBridgeManager = BridgeRegistryManager(globalLibraryRegistry);
