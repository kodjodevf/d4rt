import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

/// Tests for Bridge Annotations - Metadata system for bridge customization.
void main() {
  group('BridgeOverride Annotation', () {
    test('stores library path', () {
      const annotation = BridgeOverride(
        library: 'package:my_pkg/src/api.dart',
      );

      expect(annotation.library, equals('package:my_pkg/src/api.dart'));
      expect(annotation.targetClass, isNull);
      expect(annotation.priority, equals(0));
    });

    test('stores optional targetClass', () {
      const annotation = BridgeOverride(
        library: 'package:my_pkg/src/api.dart',
        targetClass: 'SpecificClass',
      );

      expect(annotation.targetClass, equals('SpecificClass'));
    });

    test('stores priority for override resolution', () {
      const annotation = BridgeOverride(
        library: 'package:my_pkg/src/api.dart',
        priority: 10,
      );

      expect(annotation.priority, equals(10));
    });
  });

  group('OverrideMethod Annotation', () {
    test('stores method name', () {
      const annotation = OverrideMethod('processData');

      expect(annotation.name, equals('processData'));
      expect(annotation.reason, isNull);
    });

    test('stores optional reason', () {
      const annotation = OverrideMethod(
        'complexOperation',
        reason: 'Generic type parameters require manual handling',
      );

      expect(annotation.reason, contains('Generic'));
    });
  });

  group('OverrideGetter Annotation', () {
    test('stores getter name', () {
      const annotation = OverrideGetter('value');

      expect(annotation.name, equals('value'));
    });

    test('stores optional reason', () {
      const annotation = OverrideGetter(
        'computedProperty',
        reason: 'Requires native interop',
      );

      expect(annotation.reason, isNotNull);
    });
  });

  group('OverrideSetter Annotation', () {
    test('stores setter name', () {
      const annotation = OverrideSetter('config');

      expect(annotation.name, equals('config'));
    });
  });

  group('OverrideConstructor Annotation', () {
    test('default constructor has empty name', () {
      const annotation = OverrideConstructor();

      expect(annotation.name, equals(''));
    });

    test('named constructor stores name', () {
      const annotation = OverrideConstructor('fromJson');

      expect(annotation.name, equals('fromJson'));
    });

    test('stores optional reason', () {
      const annotation =
          OverrideConstructor('create', 'Factory needs special handling');

      expect(annotation.reason, contains('Factory'));
    });
  });

  group('OverrideOperator Annotation', () {
    test('stores operator symbol', () {
      const annotation = OverrideOperator('+');

      expect(annotation.operator, equals('+'));
    });

    test('handles index operator', () {
      const annotation = OverrideOperator('[]');

      expect(annotation.operator, equals('[]'));
    });

    test('handles equality operator', () {
      const annotation = OverrideOperator('==');

      expect(annotation.operator, equals('=='));
    });

    test('stores optional reason', () {
      const annotation = OverrideOperator(
        '~/',
        reason: 'Integer division needs special handling',
      );

      expect(annotation.reason, isNotNull);
    });
  });

  group('NativeTypeNames Annotation', () {
    test('stores list of native type names', () {
      const annotation = NativeTypeNames([
        '_ControllerStream',
        '_BroadcastStream',
        '_MultiStream',
      ]);

      expect(annotation.names, hasLength(3));
      expect(annotation.names, contains('_ControllerStream'));
    });

    test('empty list is valid', () {
      const annotation = NativeTypeNames([]);

      expect(annotation.names, isEmpty);
    });
  });

  group('ExcludeMembers Annotation', () {
    test('stores list of excluded members', () {
      const annotation = ExcludeMembers(['_private', 'internalMethod']);

      expect(annotation.members, hasLength(2));
      expect(annotation.members, contains('_private'));
    });

    test('stores optional reason', () {
      const annotation = ExcludeMembers(
        ['debugOnly'],
        reason: 'Not needed in production bridges',
      );

      expect(annotation.reason, contains('production'));
    });
  });

  group('UseTypeErasure Annotation', () {
    test('default uses declared bounds', () {
      const annotation = UseTypeErasure();

      expect(annotation.typeMapping, isNull);
    });

    test('custom mapping overrides types', () {
      const annotation = UseTypeErasure({
        'T': 'Object',
        'E': 'num',
      });

      expect(annotation.typeMapping, isNotNull);
      expect(annotation.typeMapping!['T'], equals('Object'));
      expect(annotation.typeMapping!['E'], equals('num'));
    });
  });

  group('AsyncBridge Annotation', () {
    test('default enables auto-await', () {
      const annotation = AsyncBridge();

      expect(annotation.autoAwait, isTrue);
    });

    test('can disable auto-await', () {
      const annotation = AsyncBridge(autoAwait: false);

      expect(annotation.autoAwait, isFalse);
    });
  });

  group('BridgeDoc Annotation', () {
    test('stores description', () {
      const annotation = BridgeDoc('Handles data processing for the API.');

      expect(annotation.description, contains('data processing'));
    });

    test('stores optional example', () {
      const annotation = BridgeDoc(
        'Creates a new instance.',
        example: 'final obj = MyClass();',
      );

      expect(annotation.example, contains('MyClass'));
    });

    test('stores optional seeAlso references', () {
      const annotation = BridgeDoc(
        'Process items.',
        seeAlso: ['MyClass.items', 'processAll'],
      );

      expect(annotation.seeAlso, hasLength(2));
    });
  });

  group('DeprecatedBridge Annotation', () {
    test('stores deprecation message', () {
      const annotation = DeprecatedBridge('Use NewClass instead.');

      expect(annotation.message, contains('NewClass'));
    });

    test('stores optional replacement', () {
      const annotation = DeprecatedBridge(
        'Deprecated.',
        replaceWith: 'BetterClass',
      );

      expect(annotation.replaceWith, equals('BetterClass'));
    });

    test('stores optional since version', () {
      const annotation = DeprecatedBridge(
        'Old API.',
        since: '2.0.0',
      );

      expect(annotation.since, equals('2.0.0'));
    });
  });

  group('BridgeOverrideConfig', () {
    late BridgeOverrideConfig config;

    setUp(() {
      config = BridgeOverrideConfig();
    });

    test('registers override for library', () {
      config.register<_TestBridge>('package:test/test.dart');

      expect(config.hasOverrides('package:test/test.dart'), isTrue);
      expect(
          config.getOverrides('package:test/test.dart'), contains(_TestBridge));
    });

    test('returns empty list for unregistered library', () {
      expect(config.getOverrides('package:unknown/unknown.dart'), isEmpty);
    });

    test('hasOverrides returns false for unregistered', () {
      expect(config.hasOverrides('package:unknown/unknown.dart'), isFalse);
    });

    test('allows multiple overrides per library', () {
      config.register<_TestBridge>('package:test/test.dart');
      config.register<_AnotherBridge>('package:test/test.dart');

      final overrides = config.getOverrides('package:test/test.dart');
      expect(overrides, hasLength(2));
    });

    test('libraries returns all registered libraries', () {
      config.register<_TestBridge>('package:a/a.dart');
      config.register<_TestBridge>('package:b/b.dart');

      expect(config.libraries,
          containsAll(['package:a/a.dart', 'package:b/b.dart']));
    });
  });

  group('bridgeOverrideRegistry global', () {
    tearDown(() {
      // Note: We can't actually clear the global registry, so tests should be careful
    });

    test('is a BridgeOverrideConfig instance', () {
      expect(bridgeOverrideRegistry, isA<BridgeOverrideConfig>());
    });
  });
}

// Test bridge classes for annotation tests
class _TestBridge extends BaseBridge {
  @override
  String get sourceLibrary => 'package:test/test.dart';
}

class _AnotherBridge extends BaseBridge {
  @override
  String get sourceLibrary => 'package:test/test.dart';

  @override
  String? get targetClass => 'SpecificClass';
}
