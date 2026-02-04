import 'package:test/test.dart';
import 'package:d4rt/d4rt.dart';

// Test enum for use in tests
enum TestEnum { value1, value2 }

void main() {
  group('BridgeRegistryIntegration', () {
    late D4rt interpreter;

    setUp(() {
      interpreter = D4rt();
    });

    test('D4rt initializes with bridge manager', () {
      expect(interpreter.bridgeManager, isNotNull);
      expect(interpreter.registryStats.totalRegistered, equals(0));
    });

    test('registerBridgedClass tracks in manager', () {
      final bridgedClass = BridgedClass(
        name: 'TestClass',
        nativeType: String,
        constructors: {},
        methods: {},
        getters: {},
      );

      interpreter.registerBridgedClass(bridgedClass, 'package:test/test.dart');

      expect(interpreter.registryStats.totalRegistered, equals(1));
      expect(interpreter.trackedClasses, hasLength(1));
    });

    test('registerBridgedEnum tracks in manager', () {
      final enumDef = BridgedEnumDefinition<TestEnum>(
        name: 'TestEnum',
        values: TestEnum.values,
        getters: {},
        methods: {},
      );

      interpreter.registerBridgedEnum(enumDef, 'package:test/test.dart');

      expect(interpreter.registryStats.totalRegistered, equals(1));
      expect(interpreter.trackedEnums, hasLength(1));
    });

    test('registertopLevelFunction tracks in manager', () {
      interpreter.registertopLevelFunction(
        'testFunc',
        (visitor, args, namedArgs, typeArgs) => 'result',
      );

      expect(interpreter.registryStats.totalRegistered, equals(1));
      expect(interpreter.trackedFunctions, hasLength(1));
    });

    test('multiple registrations tracked separately', () {
      final bridgedClass = BridgedClass(
        name: 'TestClass',
        nativeType: String,
        constructors: {},
        methods: {},
        getters: {},
      );

      final enumDef = BridgedEnumDefinition<TestEnum>(
        name: 'TestEnum',
        values: TestEnum.values,
        getters: {},
        methods: {},
      );

      interpreter.registerBridgedClass(bridgedClass, 'package:test/test.dart');
      interpreter.registerBridgedEnum(enumDef, 'package:test/test.dart');
      interpreter.registertopLevelFunction(
        'testFunc',
        (visitor, args, namedArgs, typeArgs) => 'result',
      );

      expect(interpreter.registryStats.totalRegistered, equals(3));
      expect(interpreter.trackedClasses, hasLength(1));
      expect(interpreter.trackedEnums, hasLength(1));
      expect(interpreter.trackedFunctions, hasLength(1));
    });

    test('registry stats include deduplication info', () {
      final bridgedClass = BridgedClass(
        name: 'TestClass',
        nativeType: String,
        constructors: {},
        methods: {},
        getters: {},
      );

      interpreter.registerBridgedClass(
        bridgedClass,
        'package:test/test.dart',
        sourceUri: 'package:test/src/test.dart',
      );

      final stats = interpreter.registryStats;
      expect(stats.totalRegistered, isNotNull);
      expect(stats.totalRegistered, equals(1));
    });

    test('can create registration context from manager', () {
      final sourceUri = 'package:test/src/bridges.dart';
      final context = RegistrationContext(
        sourceUri: sourceUri,
        manager: interpreter.bridgeManager,
      );

      expect(context, isNotNull);
      expect(context.sourceUri, equals(sourceUri));
    });

    test('clearBridgeRegistry resets all registrations', () {
      final bridgedClass = BridgedClass(
        name: 'TestClass',
        nativeType: String,
        constructors: {},
        methods: {},
        getters: {},
      );

      interpreter.registerBridgedClass(bridgedClass, 'package:test/test.dart');
      expect(interpreter.registryStats.totalRegistered, equals(1));

      interpreter.clearBridgeRegistry();

      expect(interpreter.registryStats.totalRegistered, equals(0));
      expect(interpreter.trackedClasses, isEmpty);
    });

    test('source URI tracking works with explicit URI', () {
      final bridgedClass = BridgedClass(
        name: 'TestClass',
        nativeType: String,
        constructors: {},
        methods: {},
        getters: {},
      );

      interpreter.registerBridgedClass(
        bridgedClass,
        'package:test/main.dart',
        sourceUri: 'package:test/src/bridges.dart',
      );

      final tracked = interpreter.trackedClasses.first;
      expect(tracked.origin, isNotNull);
      expect(tracked.origin?.canonicalUri, contains('bridges.dart'));
    });

    test('source URI inferred from library path when not provided', () {
      final bridgedClass = BridgedClass(
        name: 'TestClass',
        nativeType: String,
        constructors: {},
        methods: {},
        getters: {},
      );

      interpreter.registerBridgedClass(
        bridgedClass,
        'package:test/test.dart',
      );

      final tracked = interpreter.trackedClasses.first;
      expect(tracked.origin?.elementName, equals('TestClass'));
    });

    test('registration context usage pattern', () {
      final bridgedClass = BridgedClass(
        name: 'TestClass',
        nativeType: String,
        constructors: {},
        methods: {},
        getters: {},
      );

      final enumDef = BridgedEnumDefinition<TestEnum>(
        name: 'TestEnum',
        values: TestEnum.values,
        getters: {},
        methods: {},
      );

      final manager = interpreter.bridgeManager;
      manager.registerClass(bridgedClass, 'package:test/test.dart',
          sourceUri: 'package:test/src/bridges.dart');
      manager.registerEnum(enumDef, 'package:test/test.dart',
          sourceUri: 'package:test/src/bridges.dart');

      expect(interpreter.trackedClasses, hasLength(1));
      expect(interpreter.trackedEnums, hasLength(1));
    });

    test('backward compatibility with old API signatures', () {
      // Ensure old code without sourceUri still works
      final bridgedClass = BridgedClass(
        name: 'TestClass',
        nativeType: String,
        constructors: {},
        methods: {},
        getters: {},
      );

      // Should not throw
      expect(
        () => interpreter.registerBridgedClass(
            bridgedClass, 'package:test/test.dart'),
        returnsNormally,
      );

      // Verify it was registered
      expect(interpreter.registryStats.totalRegistered, equals(1));
    });

    test('stats show pattern of registrations', () {
      // Register same class from different libraries (simulating re-exports)
      final bridgedClass = BridgedClass(
        name: 'TestClass',
        nativeType: String,
        constructors: {},
        methods: {},
        getters: {},
      );

      interpreter.registerBridgedClass(
        bridgedClass,
        'package:test/test.dart',
        sourceUri: 'package:test/src/core.dart',
      );

      interpreter.registerBridgedClass(
        bridgedClass,
        'package:test/re_export.dart',
        sourceUri: 'package:test/src/core.dart',
      );

      final stats = interpreter.registryStats;
      expect(stats.totalRegistered, greaterThan(0));
    });

    test('complex registration workflow', () {
      // Simulate registering multiple bridges from different sources
      final classes = [
        BridgedClass(
          name: 'ClassA',
          nativeType: String,
          constructors: {},
          methods: {},
          getters: {},
        ),
        BridgedClass(
          name: 'ClassB',
          nativeType: int,
          constructors: {},
          methods: {},
          getters: {},
        ),
      ];

      final manager = interpreter.bridgeManager;

      // Register from source A
      for (final cls in classes) {
        manager.registerClass(
          cls,
          'package:test/a.dart',
          sourceUri: 'package:test/src/source_a.dart',
        );
      }

      // Register from source B (same classes)
      for (final cls in classes) {
        manager.registerClass(
          cls,
          'package:test/b.dart',
          sourceUri: 'package:test/src/source_b.dart',
        );
      }

      expect(interpreter.trackedClasses, isNotEmpty);
      final stats = interpreter.registryStats;
      expect(stats.totalRegistered, greaterThan(0));
    });
  });
}
