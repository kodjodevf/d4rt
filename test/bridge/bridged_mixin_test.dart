import 'package:test/test.dart';
import 'package:d4rt/d4rt.dart';

/// Native class to be used as a bridged mixin
class TestMixin {
  void mixinMethod(String input) {
    print('Mixin method called with: $input');
  }

  String get mixinProperty => 'from mixin';

  int calculate(int a, int b) => a + b;
}

void main() {
  group('Bridged Mixins', () {
    late D4rt d4rt;

    setUp(() {
      d4rt = D4rt();

      // Register TestMixin as a bridged class that can be used as a mixin
      d4rt.registerBridgedClass(
        BridgedClassDefinition(
          nativeType: TestMixin,
          name: 'TestMixin',
          canBeUsedAsMixin: true,
          methods: {
            'mixinMethod': (visitor, instance, positionalArgs, namedArgs) {
              final input = positionalArgs[0].toString();
              return 'Mixin called with: $input';
            },
            'calculate': (visitor, instance, positionalArgs, namedArgs) {
              final a = positionalArgs[0] as int;
              final b = positionalArgs[1] as int;
              return a + b;
            },
          },
          getters: {
            'mixinProperty': (visitor, instance) => 'from bridged mixin',
          },
        ),
        'package:test/mixin.dart',
      );
    });

    test('can use bridged class as mixin', () async {
      const code = '''
        import 'package:test/mixin.dart';
        
        class MyClass with TestMixin {
          String name;
          
          MyClass(this.name);
          
          String testMixin() {
            return mixinMethod('test input');
          }
        }
        
        main() {
          final obj = MyClass('test');
          return obj.testMixin();
        }
      ''';

      final result = await d4rt.execute(
        library: 'package:test/main.dart',
        sources: {'package:test/main.dart': code},
      );

      expect(result, equals('Mixin called with: test input'));
    });

    test('can access bridged mixin properties', () async {
      const code = '''
        import 'package:test/mixin.dart';
        
        class MyClass with TestMixin {
          MyClass();
          
          String getProperty() {
            return mixinProperty;
          }
        }
        
        main() {
          final obj = MyClass();
          return obj.getProperty();
        }
      ''';

      final result = await d4rt.execute(
        library: 'package:test/main.dart',
        sources: {'package:test/main.dart': code},
      );

      expect(result, equals('from bridged mixin'));
    });

    test('can call bridged mixin methods with multiple arguments', () async {
      const code = '''
        import 'package:test/mixin.dart';
        
        class Calculator with TestMixin {
          Calculator();
          
          int add(int x, int y) {
            return calculate(x, y);
          }
        }
        
        main() {
          final calc = Calculator();
          return calc.add(5, 3);
        }
      ''';

      final result = await d4rt.execute(
        library: 'package:test/main.dart',
        sources: {'package:test/main.dart': code},
      );

      expect(result, equals(8));
    });

    test('bridged mixin combined with interpreted mixin', () async {
      const code = '''
        import 'package:test/mixin.dart';
        
        mixin LocalMixin {
          String localMethod() => 'from local mixin';
        }
        
        class Combined with TestMixin, LocalMixin {
          Combined();
          
          List<String> getAllMethods() {
            return [mixinProperty, localMethod()];
          }
        }
        
        main() {
          final obj = Combined();
          return obj.getAllMethods();
        }
      ''';

      final result = await d4rt.execute(
        library: 'package:test/main.dart',
        sources: {'package:test/main.dart': code},
      );

      expect(result, equals(['from bridged mixin', 'from local mixin']));
    });

    test('throws error when bridged class not marked as mixin', () async {
      // Register a class without canBeUsedAsMixin=true
      d4rt.registerBridgedClass(
        BridgedClassDefinition(
          nativeType: String,
          name: 'NotAMixin',
          canBeUsedAsMixin: false, // Explicitly set to false
        ),
        'package:test/notmixin.dart',
      );

      const code = '''
        import 'package:test/notmixin.dart';
        
        class MyClass with NotAMixin {
          MyClass();
        }
        
        main() {
          return MyClass();
        }
      ''';

      expect(
        () => d4rt.execute(
          library: 'package:test/main.dart',
          sources: {'package:test/main.dart': code},
        ),
        throwsA(isA<RuntimeError>().having(
          (e) => e.message,
          'message',
          contains('cannot be used as a mixin'),
        )),
      );
    });
  });
}
