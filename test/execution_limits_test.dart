import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('Execution Limits & Sandbox Timeout Tests', () {
    test('maxSteps terminates infinite while loop with ExecutionLimitException', () {
      final d4rt = D4rt();
      const source = '''
        void main() {
          while (true) {
            // Infinite loop
          }
        }
      ''';

      expect(
        () => d4rt.execute(source: source, maxSteps: 50),
        throwsA(isA<ExecutionLimitException>()),
      );
    });

    test('maxSteps terminates infinite for loop with ExecutionLimitException', () {
      final d4rt = D4rt();
      const source = '''
        void main() {
          for (var i = 0; i >= 0; i++) {
            // Infinite loop
          }
        }
      ''';

      expect(
        () => d4rt.execute(source: source, maxSteps: 100),
        throwsA(isA<ExecutionLimitException>()),
      );
    });

    test('timeout terminates infinite loop with ExecutionTimeoutException', () {
      final d4rt = D4rt();
      const source = '''
        void main() {
          var count = 0;
          while (true) {
            count++;
          }
        }
      ''';

      expect(
        () => d4rt.execute(source: source, timeout: const Duration(milliseconds: 100)),
        throwsA(isA<ExecutionTimeoutException>()),
      );
    });

    test('normal execution within limits succeeds', () {
      final d4rt = D4rt();
      const source = '''
        int main() {
          var sum = 0;
          for (var i = 0; i < 10; i++) {
            sum += i;
          }
          return sum;
        }
      ''';

      final result = d4rt.execute(
        source: source,
        maxSteps: 1000,
        timeout: const Duration(seconds: 2),
      );

      expect(result, equals(45));
    });

    test('eval respects timeout and maxSteps limits', () {
      final d4rt = D4rt();
      d4rt.execute(source: 'void main() {}');

      expect(
        () => d4rt.eval('while (true) {}', maxSteps: 20),
        throwsA(isA<ExecutionLimitException>()),
      );
    });
  });
}
