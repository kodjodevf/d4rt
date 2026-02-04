import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

/// Tests for Library Tracking - Source-based deduplication system.
void main() {
  group('SourceOrigin', () {
    test('creates origin from URI and name', () {
      final origin = SourceOrigin.fromUri(
        'package:my_pkg/src/utils.dart',
        'MyClass',
      );

      expect(origin.canonicalUri, equals('package:my_pkg/src/utils.dart'));
      expect(origin.elementName, equals('MyClass'));
      expect(origin.id, equals('package:my_pkg/src/utils.dart#MyClass'));
    });

    test('normalizes URIs consistently', () {
      final origin1 = SourceOrigin.fromUri('package:pkg/file.dart/', 'Foo');
      final origin2 = SourceOrigin.fromUri('package:pkg/file.dart', 'Foo');

      expect(origin1, equals(origin2));
    });

    test('different elements have different IDs', () {
      final origin1 = SourceOrigin.fromUri('package:pkg/file.dart', 'ClassA');
      final origin2 = SourceOrigin.fromUri('package:pkg/file.dart', 'ClassB');

      expect(origin1.id, isNot(equals(origin2.id)));
    });

    test('same element in different files have different IDs', () {
      final origin1 = SourceOrigin.fromUri('package:pkg/a.dart', 'Foo');
      final origin2 = SourceOrigin.fromUri('package:pkg/b.dart', 'Foo');

      expect(origin1.id, isNot(equals(origin2.id)));
    });

    test('compareTo orders by ID', () {
      final originA = SourceOrigin.fromUri('package:pkg/a.dart', 'A');
      final originB = SourceOrigin.fromUri('package:pkg/b.dart', 'B');

      expect(originA.compareTo(originB), lessThan(0));
    });
  });

  group('TrackedBridgedClass', () {
    late BridgedClass mockBridgedClass;

    setUp(() {
      mockBridgedClass = BridgedClass(
        nativeType: String,
        name: 'TestClass',
      );
    });

    test('wraps bridged class with origin', () {
      final origin = SourceOrigin.fromUri('package:pkg/src.dart', 'TestClass');
      final tracked = TrackedBridgedClass(mockBridgedClass, origin: origin);

      expect(tracked.name, equals('TestClass'));
      expect(tracked.hasOrigin, isTrue);
      expect(tracked.origin, equals(origin));
    });

    test('tracks multiple import paths', () {
      final tracked = TrackedBridgedClass(mockBridgedClass);

      tracked.addImportPath('package:pkg/pkg.dart');
      tracked.addImportPath('package:pkg/all.dart');
      tracked.addImportPath('package:pkg/pkg.dart'); // Duplicate

      expect(tracked.importPaths, hasLength(2));
      expect(tracked.importPaths, contains('package:pkg/pkg.dart'));
      expect(tracked.importPaths, contains('package:pkg/all.dart'));
    });

    test('hasSameOrigin detects duplicates', () {
      final origin = SourceOrigin.fromUri('package:pkg/src.dart', 'Foo');

      final tracked1 = TrackedBridgedClass(mockBridgedClass, origin: origin);
      final tracked2 = TrackedBridgedClass(mockBridgedClass, origin: origin);

      expect(tracked1.hasSameOrigin(tracked2), isTrue);
    });

    test('hasSameOrigin returns false for different origins', () {
      final origin1 = SourceOrigin.fromUri('package:pkg/a.dart', 'Foo');
      final origin2 = SourceOrigin.fromUri('package:pkg/b.dart', 'Foo');

      final tracked1 = TrackedBridgedClass(mockBridgedClass, origin: origin1);
      final tracked2 = TrackedBridgedClass(mockBridgedClass, origin: origin2);

      expect(tracked1.hasSameOrigin(tracked2), isFalse);
    });

    test('hasSameOrigin returns false when either has no origin', () {
      final origin = SourceOrigin.fromUri('package:pkg/src.dart', 'Foo');

      final withOrigin = TrackedBridgedClass(mockBridgedClass, origin: origin);
      final withoutOrigin = TrackedBridgedClass(mockBridgedClass);

      expect(withOrigin.hasSameOrigin(withoutOrigin), isFalse);
    });
  });

  group('TrackedFunction', () {
    test('wraps function with metadata', () {
      final origin = SourceOrigin.fromUri('package:pkg/utils.dart', 'doThing');
      final tracked = TrackedFunction(
        'doThing',
        () => null,
        origin: origin,
        signature: 'void doThing(int x)',
      );

      expect(tracked.name, equals('doThing'));
      expect(tracked.signature, equals('void doThing(int x)'));
      expect(tracked.hasOrigin, isTrue);
    });

    test('tracks import paths', () {
      final tracked = TrackedFunction('fn', () => null);

      tracked.addImportPath('package:a/a.dart');
      tracked.addImportPath('package:b/b.dart');

      expect(tracked.importPaths, hasLength(2));
    });
  });

  group('TrackedVariable', () {
    test('wraps variable value', () {
      final origin = SourceOrigin.fromUri('package:pkg/const.dart', 'VERSION');
      final tracked = TrackedVariable('VERSION', '1.0.0', origin: origin);

      expect(tracked.name, equals('VERSION'));
      expect(tracked.value, equals('1.0.0'));
      expect(tracked.hasOrigin, isTrue);
    });
  });

  group('TrackedGetter', () {
    test('wraps getter function', () {
      final origin = SourceOrigin.fromUri('package:pkg/config.dart', 'isDebug');
      final tracked = TrackedGetter('isDebug', () => true, origin: origin);

      expect(tracked.name, equals('isDebug'));
      expect(tracked.getter(), equals(true));
    });
  });

  group('LibraryRegistry', () {
    late LibraryRegistry registry;

    setUp(() {
      registry = LibraryRegistry();
    });

    group('addClass', () {
      test('registers new class and returns true', () {
        final bridged = BridgedClass(nativeType: String, name: 'MyString');
        final origin = SourceOrigin.fromUri('package:pkg/str.dart', 'MyString');

        final added = registry.addClass(
          bridged,
          'package:pkg/pkg.dart',
          origin: origin,
        );

        expect(added, isTrue);
        expect(registry.classes, hasLength(1));
        expect(registry.stats.classesRegistered, equals(1));
      });

      test('deduplicates by origin and returns false', () {
        final bridged = BridgedClass(nativeType: String, name: 'Foo');
        final origin = SourceOrigin.fromUri('package:pkg/foo.dart', 'Foo');

        // First registration
        final first =
            registry.addClass(bridged, 'package:a/a.dart', origin: origin);
        expect(first, isTrue);

        // Second registration with same origin from different import
        final second =
            registry.addClass(bridged, 'package:b/b.dart', origin: origin);
        expect(second, isFalse);

        expect(registry.classes, hasLength(1));
        expect(registry.stats.duplicatesSkipped, equals(1));

        // Both import paths should be tracked
        final tracked = registry.classes.first;
        expect(tracked.importPaths, contains('package:a/a.dart'));
        expect(tracked.importPaths, contains('package:b/b.dart'));
      });

      test('allows classes without origin (untracked)', () {
        final bridged1 = BridgedClass(nativeType: String, name: 'A');
        final bridged2 = BridgedClass(nativeType: int, name: 'B');

        registry.addClass(bridged1, 'package:x/x.dart');
        registry.addClass(bridged2, 'package:y/y.dart');

        expect(registry.classes, hasLength(2));
      });
    });

    group('addEnum', () {
      test('registers enum with deduplication', () {
        final enumDef = BridgedEnumDefinition<_TestEnum>(
          name: 'Status',
          values: _TestEnum.values,
        );
        final origin = SourceOrigin.fromUri('package:pkg/enums.dart', 'Status');

        final first =
            registry.addEnum(enumDef, 'package:a/a.dart', origin: origin);
        final second =
            registry.addEnum(enumDef, 'package:b/b.dart', origin: origin);

        expect(first, isTrue);
        expect(second, isFalse);
        expect(registry.enums, hasLength(1));
        expect(registry.stats.enumsRegistered, equals(1));
      });
    });

    group('addFunction', () {
      test('registers function with deduplication', () {
        final origin = SourceOrigin.fromUri('package:pkg/utils.dart', 'helper');

        final first =
            registry.addFunction('helper', () {}, 'pkg:a', origin: origin);
        final second =
            registry.addFunction('helper', () {}, 'pkg:b', origin: origin);

        expect(first, isTrue);
        expect(second, isFalse);
        expect(registry.functions, hasLength(1));
      });
    });

    group('addVariable', () {
      test('registers variable with deduplication', () {
        final origin = SourceOrigin.fromUri('package:pkg/const.dart', 'PI');

        final first = registry.addVariable('PI', 3.14, 'pkg:a', origin: origin);
        final second =
            registry.addVariable('PI', 3.14, 'pkg:b', origin: origin);

        expect(first, isTrue);
        expect(second, isFalse);
        expect(registry.variables, hasLength(1));
      });
    });

    group('addGetter', () {
      test('registers getter with deduplication', () {
        final origin = SourceOrigin.fromUri('package:pkg/config.dart', 'debug');

        final first =
            registry.addGetter('debug', () => true, 'pkg:a', origin: origin);
        final second =
            registry.addGetter('debug', () => true, 'pkg:b', origin: origin);

        expect(first, isTrue);
        expect(second, isFalse);
        expect(registry.getters, hasLength(1));
      });
    });

    group('lookup methods', () {
      test('getClass finds by name', () {
        final bridged = BridgedClass(nativeType: String, name: 'Target');
        registry.addClass(bridged, 'pkg:x');

        final found = registry.getClass('Target');
        expect(found, isNotNull);
        expect(found!.name, equals('Target'));
      });

      test('getClass returns null for unknown', () {
        expect(registry.getClass('Unknown'), isNull);
      });

      test('getEnum finds by name', () {
        final enumDef = BridgedEnumDefinition<_TestEnum>(
          name: 'MyEnum',
          values: _TestEnum.values,
        );
        registry.addEnum(enumDef, 'pkg:x');

        expect(registry.getEnum('MyEnum'), isNotNull);
      });

      test('getFunction finds by name', () {
        registry.addFunction('myFunc', () {}, 'pkg:x');

        expect(registry.getFunction('myFunc'), isNotNull);
      });
    });

    group('clear', () {
      test('removes all registrations', () {
        final bridged = BridgedClass(nativeType: String, name: 'X');
        registry.addClass(bridged, 'pkg:x');
        registry.addFunction('fn', () {}, 'pkg:x');
        registry.addVariable('v', 1, 'pkg:x');

        registry.clear();

        expect(registry.classes, isEmpty);
        expect(registry.functions, isEmpty);
        expect(registry.variables, isEmpty);
        expect(registry.stats.totalRegistered, equals(0));
      });

      test('resets statistics', () {
        final bridged = BridgedClass(nativeType: String, name: 'X');
        registry.addClass(bridged, 'pkg:x');

        expect(registry.stats.classesRegistered, equals(1));

        registry.clear();

        expect(registry.stats.classesRegistered, equals(0));
        expect(registry.stats.duplicatesSkipped, equals(0));
      });
    });

    group('statistics', () {
      test('tracks total registered', () {
        final bridged = BridgedClass(nativeType: String, name: 'C');
        final enumDef = BridgedEnumDefinition<_TestEnum>(
          name: 'E',
          values: _TestEnum.values,
        );

        registry.addClass(bridged, 'pkg:x');
        registry.addEnum(enumDef, 'pkg:x');
        registry.addFunction('f', () {}, 'pkg:x');
        registry.addVariable('v', 1, 'pkg:x');
        registry.addGetter('g', () => 1, 'pkg:x');

        expect(registry.stats.totalRegistered, equals(5));
        expect(registry.stats.classesRegistered, equals(1));
        expect(registry.stats.enumsRegistered, equals(1));
        expect(registry.stats.functionsRegistered, equals(1));
        expect(registry.stats.variablesRegistered, equals(1));
        expect(registry.stats.gettersRegistered, equals(1));
      });

      test('tracks duplicates skipped', () {
        final origin = SourceOrigin.fromUri('pkg:x/x.dart', 'Dup');
        final bridged = BridgedClass(nativeType: String, name: 'Dup');

        registry.addClass(bridged, 'pkg:a', origin: origin);
        registry.addClass(bridged, 'pkg:b', origin: origin);
        registry.addClass(bridged, 'pkg:c', origin: origin);

        expect(registry.stats.duplicatesSkipped, equals(2));
      });
    });
  });

  group('globalLibraryRegistry', () {
    tearDown(() {
      globalLibraryRegistry.clear();
    });

    test('is a singleton instance', () {
      expect(globalLibraryRegistry, isA<LibraryRegistry>());
    });

    test('can be used for application-wide tracking', () {
      final bridged = BridgedClass(nativeType: String, name: 'Global');
      final origin = SourceOrigin.fromUri('pkg:global/g.dart', 'Global');

      globalLibraryRegistry.addClass(bridged, 'pkg:a', origin: origin);
      globalLibraryRegistry.addClass(bridged, 'pkg:b', origin: origin);

      expect(globalLibraryRegistry.classes, hasLength(1));
      expect(globalLibraryRegistry.stats.duplicatesSkipped, equals(1));
    });
  });
}

/// Test enum for BridgedEnumDefinition tests.
enum _TestEnum { a, b, c }
