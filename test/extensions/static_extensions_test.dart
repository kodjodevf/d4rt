import 'package:test/test.dart';

import '../interpreter_test.dart';

void main() {
  group('Static Extension Members', () {
    test('Static method in extension', () {
      const source = '''
        extension StringUtils on String {
          static String join(List<String> parts, String separator) {
            var result = '';
            for (var i = 0; i < parts.length; i++) {
              if (i > 0) result += separator;
              result += parts[i];
            }
            return result;
          }
        }
        
        main() {
          return StringUtils.join(['a', 'b', 'c'], '-');
        }
      ''';
      final result = execute(source);
      expect(result, equals('a-b-c'));
    });

    test('Static getter in extension', () {
      const source = '''
        extension MathConstants on double {
          static double get pi => 3.14159;
        }
        
        main() {
          return MathConstants.pi;
        }
      ''';
      final result = execute(source);
      expect(result, equals(3.14159));
    });

    test('Static field in extension', () {
      const source = '''
        extension Counter on int {
          static int count = 0;
        }
        
        main() {
          return Counter.count;
        }
      ''';
      final result = execute(source);
      expect(result, equals(0));
    });

    test('Static setter in extension', () {
      const source = '''
        class Config {
          static String _mode = 'default';
        }
        
        extension ConfigExt on Config {
          static void set mode(String m) {
            Config._mode = m;
          }
          
          static String get mode => Config._mode;
        }
        
        main() {
          ConfigExt.mode = 'production';
          return ConfigExt.mode;
        }
      ''';
      final result = execute(source);
      expect(result, equals('production'));
    });

    test('Multiple static members in extension', () {
      const source = '''
        extension ListUtils on List {
          static int maxSize = 100;
          
          static List<T> create<T>(int size, T defaultValue) {
            var list = <T>[];
            for (var i = 0; i < size; i++) {
              list.add(defaultValue);
            }
            return list;
          }
          
          static int get currentMaxSize => ListUtils.maxSize;
        }
        
        main() {
          var list = ListUtils.create<int>(3, 42);
          return [list, ListUtils.currentMaxSize];
        }
      ''';
      final result = execute(source);
      expect(
          result,
          equals([
            [42, 42, 42],
            100
          ]));
    });

    test('Static method calling another static method', () {
      const source = '''
        extension Calculator on num {
          static int add(int a, int b) {
            return a + b;
          }
          
          static int multiply(int a, int b) {
            return a * b;
          }
          
          static int calculate(int x, int y) {
            return Calculator.multiply(Calculator.add(x, y), 2);
          }
        }
        
        main() {
          return Calculator.calculate(3, 4);
        }
      ''';
      final result = execute(source);
      expect(result, equals(14)); // (3 + 4) * 2
    });

    test('Static field modification', () {
      const source = '''
        extension AppState on String {
          static String currentUser = 'guest';
        }
        
        main() {
          var initial = AppState.currentUser;
          AppState.currentUser = 'admin';
          var updated = AppState.currentUser;
          return [initial, updated];
        }
      ''';
      final result = execute(source);
      expect(result, equals(['guest', 'admin']));
    });

    test('Static method with type parameters', () {
      const source = '''
        extension TypedUtils on Object {
          static T identity<T>(T value) {
            return value;
          }
        }
        
        main() {
          var str = TypedUtils.identity<String>('hello');
          var num = TypedUtils.identity<int>(42);
          return [str, num];
        }
      ''';
      final result = execute(source);
      expect(result, equals(['hello', 42]));
    });

    test('Static getter returning computed value', () {
      const source = '''
        extension TimeUtils on DateTime {
          static int callCount = 0;
          
          static void incrementCalls() {
            TimeUtils.callCount++;
          }
        }
        
        main() {
          TimeUtils.incrementCalls();
          TimeUtils.incrementCalls();
          TimeUtils.incrementCalls();
          return TimeUtils.callCount;
        }
      ''';
      final result = execute(source);
      expect(result, equals(3));
    });

    test('Mix of static and instance members', () {
      const source = '''
        extension StringExt on String {
          static String prefix = 'PREFIX: ';
          
          String withPrefix() {
            return StringExt.prefix + this;
          }
        }
        
        main() {
          var result = 'test'.withPrefix();
          return result;
        }
      ''';
      final result = execute(source);
      expect(result, equals('PREFIX: test'));
    });

    test('Static method with multiple parameters', () {
      const source = '''
        extension MathOps on int {
          static int sum(int a, int b, int c) {
            return a + b + c;
          }
          
          static int product(int a, int b, int c) {
            return a * b * c;
          }
        }
        
        main() {
          var s = MathOps.sum(1, 2, 3);
          var p = MathOps.product(2, 3, 4);
          return [s, p];
        }
      ''';
      final result = execute(source);
      expect(result, equals([6, 24]));
    });

    test('Static field accessed from instance method', () {
      const source = '''
        extension NumberExt on int {
          static int multiplier = 10;
          
          int scaled() {
            return this * NumberExt.multiplier;
          }
        }
        
        main() {
          return 5.scaled();
        }
      ''';
      final result = execute(source);
      expect(result, equals(50));
    });

    test('Multiple extensions with static members on same type', () {
      const source = '''
        extension ExtA on String {
          static String prefix = 'A: ';
        }
        
        extension ExtB on String {
          static String prefix = 'B: ';
        }
        
        main() {
          return [ExtA.prefix, ExtB.prefix];
        }
      ''';
      final result = execute(source);
      expect(result, equals(['A: ', 'B: ']));
    });

    test('Static method returning function', () {
      const source = '''
        extension FunctionUtils on Function {
          static Function makeAdder(int x) {
            return (int y) => x + y;
          }
        }
        
        main() {
          var add5 = FunctionUtils.makeAdder(5);
          return add5(10);
        }
      ''';
      final result = execute(source);
      expect(result, equals(15));
    });

    test('Unnamed extension with static members', () {
      const source = '''
        extension on int {
          static int defaultValue = 999;
        }
        
        main() {
          // Note: Unnamed extensions' static members are stored with '_' prefix
          // This test verifies they can be defined without errors
          return 42;
        }
      ''';
      final result = execute(source);
      expect(result, equals(42));
    });
  });
}
