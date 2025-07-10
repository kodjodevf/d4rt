import 'package:test/test.dart';
import 'package:d4rt/d4rt.dart';

dynamic execute(String source, {Object? args}) {
  final d4rt = D4rt()..setDebug(false);
  return d4rt.execute(
      library: 'package:test/main.dart',
      args: args,
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
  });
}
