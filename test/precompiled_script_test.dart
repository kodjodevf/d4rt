import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('PrecompiledScript Tests', () {
    test('compiles and executes simple function', () {
      final d4rt = D4rt();
      final script = d4rt.compile(source: '''
        int square(int x) => x * x;
      ''');

      expect(script.declarationCount, equals(1));
      expect(script.source, contains('square'));

      final result1 = d4rt.executeCompiled(
        script,
        name: 'square',
        positionalArgs: [4],
      );
      expect(result1, equals(16));

      final result2 = d4rt.executeCompiled(
        script,
        name: 'square',
        positionalArgs: [7],
      );
      expect(result2, equals(49));
    });

    test('compiles and executes complex class with methods', () {
      final d4rt = D4rt();
      final script = d4rt.compile(source: '''
        class Calculator {
          int add(int a, int b) => a + b;
          int multiply(int a, int b) => a * b;
        }

        int main() {
          final calc = Calculator();
          return calc.add(5, 3) + calc.multiply(4, 2);
        }
      ''');

      final result = d4rt.executeCompiled(script);
      expect(result, equals(16));
    });

    test('throws SourceCodeException on invalid syntax during compile', () {
      final d4rt = D4rt();
      expect(
        () => d4rt.compile(source: 'int add(int a, int b) { return a + ; }'),
        throwsA(isA<SourceCodeException>()),
      );
    });

    test('AST caching reuses precompiled script when enableAstCache is true', () {
      final d4rt = D4rt(enableAstCache: true);
      const source = 'int compute() => 12345;';

      final script1 = d4rt.compile(source: source);
      final script2 = d4rt.compile(source: source);

      expect(identical(script1, script2), isTrue);

      final result = d4rt.execute(source: source, name: 'compute');
      expect(result, equals(12345));

      d4rt.clearAstCache();
      final script3 = d4rt.compile(source: source);
      expect(identical(script1, script3), isFalse);
    });
  });
}
