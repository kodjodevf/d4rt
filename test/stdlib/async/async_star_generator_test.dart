import 'package:test/test.dart';
import '../../interpreter_test.dart';

void main() {
  group('Async* Generator Tests', () {
    test('Basic async* generator with yield', () async {
      const code = '''
        Stream<int> countAsync() async* {
          yield 1;
          yield 2;
          yield 3;
        }
        
        Future<List<int>> main() async {
          List<int> results = [];
          await for (var value in countAsync()) {
            results.add(value);
          }
          return results;
        }
      ''';

      final result = await execute(code);
      expect(result, equals([1, 2, 3]));
    });

    test('Async* generator with async operations between yields', () async {
      const code = '''
        Stream<int> delayedCount() async* {
          for (int i = 1; i <= 3; i++) {
            await Future.delayed(Duration(milliseconds: 1));
            yield i;
          }
        }
        
        Future<List<int>> main() async {
          List<int> results = [];
          await for (var value in delayedCount()) {
            results.add(value);
          }
          return results;
        }
      ''';

      final result = await execute(code);
      expect(result, equals([1, 2, 3]));
    });

    test('Async* generator with yield*', () async {
      const code = '''
        Stream<int> baseStream() async* {
          yield 1;
          yield 2;
        }
        
        Stream<int> extendedStream() async* {
          yield 0;
          yield* baseStream();
          yield 3;
        }
        
        Future<List<int>> main() async {
          List<int> results = [];
          await for (var value in extendedStream()) {
            results.add(value);
          }
          return results;
        }
      ''';

      final result = await execute(code);
      expect(result, equals([0, 1, 2, 3]));
    });

    test('Async* generator with early return', () async {
      const code = '''
        Stream<int> conditionalGenerator(bool shouldContinue) async* {
          yield 1;
          if (!shouldContinue) return;
          yield 2;
          yield 3;
        }
        
        Future<List<int>> main() async {
          List<int> results1 = [];
          await for (var value in conditionalGenerator(false)) {
            results1.add(value);
          }
          
          List<int> results2 = [];
          await for (var value in conditionalGenerator(true)) {
            results2.add(value);
          }
          
          return [results1, results2];
        }
      ''';

      final result = await execute(code);
      expect(
          result,
          equals([
            [1],
            [1, 2, 3]
          ]));
    });

    test('Async* generator with exception handling', () async {
      const code = '''
        Stream<int> errorGenerator() async* {
          yield 1;
          throw Exception('Test error');
          yield 2; // Should not be reached
        }
        
        Future<String> main() async {
          try {
            await for (var value in errorGenerator()) {
              // First value should be received
              if (value == 1) continue;
            }
            return 'No error';
          } catch (e) {
            return 'Caught: \${e.toString()}';
          }
        }
      ''';

      final result = await execute(code);
      expect(result, contains('Caught:'));
      expect(result, contains('Test error'));
    });

    test('Nested async* generators', () async {
      const code = '''
        Stream<int> innerGenerator(int start, int count) async* {
          for (int i = 0; i < count; i++) {
            yield start + i;
          }
        }
        
        Stream<int> outerGenerator() async* {
          yield* innerGenerator(1, 2);
          yield* innerGenerator(10, 2);
        }
        
        Future<List<int>> main() async {
          List<int> results = [];
          await for (var value in outerGenerator()) {
            results.add(value);
          }
          return results;
        }
      ''';

      final result = await execute(code);
      expect(result, equals([1, 2, 10, 11]));
    });

    test('Async* generator with complex control flow', () async {
      const code = '''
        Stream<int> complexGenerator() async* {
          for (int i = 1; i <= 5; i++) {
            if (i % 2 == 0) {
              yield i * 2;
            } else {
              yield i;
            }
            
            if (i == 3) {
              await Future.delayed(Duration(milliseconds: 1));
            }
          }
        }
        
        Future<List<int>> main() async {
          List<int> results = [];
          await for (var value in complexGenerator()) {
            results.add(value);
          }
          return results;
        }
      ''';

      final result = await execute(code);
      expect(result, equals([1, 4, 3, 8, 5]));
    });

    test('Multiple async* generators running concurrently', () async {
      const code = '''
        Stream<String> generator1() async* {
          for (int i = 1; i <= 3; i++) {
            await Future.delayed(Duration(milliseconds: 1));
            yield 'A\$i';
          }
        }
        
        Stream<String> generator2() async* {
          for (int i = 1; i <= 3; i++) {
            await Future.delayed(Duration(milliseconds: 1));
            yield 'B\$i';
          }
        }
        
        Future<List<String>> main() async {
          List<String> results1 = [];
          List<String> results2 = [];
          
          // Run generators concurrently
          await Future.wait([
            () async {
              await for (var value in generator1()) {
                results1.add(value);
              }
            }(),
            () async {
              await for (var value in generator2()) {
                results2.add(value);
              }
            }()
          ]);
          
          return [results1, results2];
        }
      ''';

      final result = await execute(code);
      expect(
          result,
          equals([
            ['A1', 'A2', 'A3'],
            ['B1', 'B2', 'B3']
          ]));
    });

    test('Async* generator yielding complex objects', () async {
      const code = '''
        Stream<Map<String, dynamic>> dataGenerator() async* {
          yield {'id': 1, 'name': 'First'};
          await Future.delayed(Duration(milliseconds: 1));
          yield {'id': 2, 'name': 'Second'};
          yield {'id': 3, 'name': 'Third'};
        }
        
        Future<List<Map<String, dynamic>>> main() async {
          List<Map<String, dynamic>> results = [];
          await for (var data in dataGenerator()) {
            results.add(data);
          }
          return results;
        }
      ''';

      final result = await execute(code);
      expect(
          result,
          equals([
            {'id': 1, 'name': 'First'},
            {'id': 2, 'name': 'Second'},
            {'id': 3, 'name': 'Third'}
          ]));
    });
  });
}
