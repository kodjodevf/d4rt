import 'package:test/test.dart';
import 'package:d4rt/d4rt.dart';

dynamic execute(String source, {List<Object?>? args}) {
  final d4rt = D4rt()..setDebug(false);
  return d4rt.execute(
      library: 'package:test/main.dart',
      positionalArgs: args,
      sources: {'package:test/main.dart': source});
}

void main() {
  group('Improved Generics Validation', () {
    test('Generic class constraint validation', () {
      final validCode = '''
        class NumericContainer<T extends num> {
          T value;
          NumericContainer(this.value);
          
          T getValue() => value;
        }
        
        main() {
          var intContainer = NumericContainer<int>(42);
          return intContainer.getValue();
        }
      ''';

      expect(execute(validCode), equals(42));

      final invalidCode = '''
        class NumericContainer<T extends num> {
          T value;
          NumericContainer(this.value);
          
          T getValue() => value;
        }
        
        main() {
          var stringContainer = NumericContainer<String>("hello");
          return stringContainer.getValue();
        }
      ''';

      expect(
        () => execute(invalidCode),
        throwsA(isA<RuntimeError>().having(
          (e) => e.message,
          'message',
          contains('does not satisfy bound'),
        )),
      );
    });

    test('Generic function constraint validation', () {
      final validCode = '''
        T addOne<T extends num>(T value) {
          return value + 1;
        }
        
        main() {
          return addOne<int>(5);
        }
      ''';

      expect(execute(validCode), equals(6));

      final invalidCode = '''
        T addOne<T extends num>(T value) {
          return value + 1;
        }
        
        main() {
          return addOne<String>("hello");
        }
      ''';

      expect(
        () => execute(invalidCode),
        throwsA(isA<RuntimeError>().having(
          (e) => e.message,
          'message',
          contains('does not satisfy bound'),
        )),
      );
    });

    test('Multiple type parameters with bounds', () {
      final validCode = '''
        class Pair<T extends num, U extends String> {
          T first;
          U second;
          Pair(this.first, this.second);
        }
        
        main() {
          var validPair = Pair<double, String>(42, "test");
          return true;
        }
      ''';

      expect(execute(validCode), isTrue);

      final invalidCode = '''
        class Pair<T extends num, U extends String> {
          T first;
          U second;
          Pair(this.first, this.second);
        }
        
        main() {
          var invalidPair = Pair<bool, String>(true, "test");
          return true;
        }
      ''';

      expect(
        () => execute(invalidCode),
        throwsA(isA<RuntimeError>().having(
          (e) => e.message,
          'message',
          contains('does not satisfy bound'),
        )),
      );
    });

    test('Nested generics constraint validation', () {
      final validCode = '''
        class Container<T extends num> {
          List<T> items = [];
        }
        
        main() {
          var container = Container<int>();
          return true;
        }
      ''';

      expect(execute(validCode), isTrue);

      final invalidCode = '''
        class Container<T extends num> {
          List<T> items = [];
        }
        
        main() {
          var container = Container<String>();
          return true;
        }
      ''';

      expect(
        () => execute(invalidCode),
        throwsA(isA<RuntimeError>().having(
          (e) => e.message,
          'message',
          contains('does not satisfy bound'),
        )),
      );
    });

    test('Applied generic runtime type is preserved for user-defined classes',
        () {
      final code = '''
        class Box<T> {
          T value;
          Box(this.value);
        }

        main() {
          var box = Box<int>(42);
          return [box is Box<int>, box is Box<num>, box is Box<String>];
        }
      ''';

      expect(execute(code), equals([true, true, false]));
    });

    test('Generic return type validation uses applied runtime types', () {
      final validCode = '''
        class Box<T> {
          T value;
          Box(this.value);
        }

        Box<int> makeBox() {
          return Box<int>(42);
        }

        main() {
          return makeBox() is Box<int>;
        }
      ''';

      expect(execute(validCode), isTrue);

      final invalidCode = '''
        class Box<T> {
          T value;
          Box(this.value);
        }

        Box<String> makeBox() {
          return Box<int>(42);
        }

        main() {
          return makeBox();
        }
      ''';

      expect(
        () => execute(invalidCode),
        throwsA(isA<RuntimeError>().having(
          (e) => e.message,
          'message',
          contains("can't be returned"),
        )),
      );
    });

    test('Typed native collection returns preserve applied runtime types', () {
      final validCode = '''
        List<int> numbers() {
          return [1, 2, 3];
        }

        Map<String, int> scores() {
          return {'a': 1, 'b': 2};
        }

        main() {
          return [numbers() is List<int>, scores() is Map<String, int>];
        }
      ''';

      expect(execute(validCode), equals([true, true]));

      final invalidCode = '''
        List<String> numbers() {
          return [1, 2, 3];
        }

        main() {
          return numbers();
        }
      ''';

      expect(
        () => execute(invalidCode),
        throwsA(isA<RuntimeError>().having(
          (e) => e.message,
          'message',
          contains("can't be returned"),
        )),
      );
    });

    test('Typed variable declarations annotate empty collections', () {
      final code = '''
        List<int> build() {
          List<int> result = [];
          result.add(1);
          result.add(2);
          return result;
        }

        main() {
          return build() is List<int>;
        }
      ''';

      expect(execute(code), isTrue);
    });
  });
}
