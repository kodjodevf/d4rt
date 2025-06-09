import 'package:test/test.dart';
import '../../interpreter_test.dart';

void main() {
  group('Interpreted Async/Await Tests', () {
    test('await Future.value', () async {
      const source = '''
        Future<int> main() async {
          int result = await Future.value(42);
          return result;
        }
      ''';
      expect(await execute(source), equals(42));
    });

    test('await Future.delayed', () async {
      const source = '''
        Future<String> main() async {
          await Future.delayed(Duration(milliseconds: 10));
          return "Done";
        }
      ''';
      // Check timing roughly? Hard in tests. Just check result.
      expect(await execute(source), equals("Done"));
    });

    test('Assign await result to variable', () async {
      const source = '''
        Future<int> fetchValue() async {
           await Future.delayed(Duration(milliseconds: 5));
           return 100;
        }

        Future<int> main() async {
          int x = await fetchValue();
          return x + 5;
        }
      ''';
      expect(await execute(source), equals(105));
    });

    test('Return await result directly', () async {
      const source = '''
        Future<String> fetchMessage() async {
           await Future.delayed(Duration(milliseconds: 5));
           return "Returned Message";
        }

        Future<String> main() async {
          return await fetchMessage();
        }
      ''';
      expect(await execute(source), equals("Returned Message"));
    });

    test('Multiple awaits in sequence', () async {
      const source = '''
        Future<int> step1() async {
           await Future.delayed(Duration(milliseconds: 5));
           return 10;
        }
        Future<int> step2(int prev) async {
           await Future.delayed(Duration(milliseconds: 5));
           return prev + 20;
        }

        Future<int> main() async {
          int r1 = await step1();
          int r2 = await step2(r1);
          return r2 + 30;
        }
      ''';
      // 10 -> 10+20=30 -> 30+30=60
      expect(await execute(source), equals(60));
    });

    test('Nested async function calls', () async {
      const source = '''
         Future<int> inner() async {
           await Future.delayed(Duration(milliseconds: 1));
           return 50;
         }
         Future<int> middle() async {
            int val = await inner();
            await Future.delayed(Duration(milliseconds: 1));
            return val + 50;
         }
        Future<int> main() async {
          int result = await middle();
          return result + 50;
        }
      ''';
      // 50 -> 50+50=100 -> 100+50=150
      expect(await execute(source), equals(150));
    });

    test('Sync code between awaits', () async {
      const source = '''
        Future<String> part1() async { return "A"; }
        Future<String> part3() async { return "C"; }

        Future<String> main() async {
           String r1 = await part1();
           String r2 = r1 + "B"; // Sync operation
           String r3 = await part3();
           return r2 + r3; // Sync operation
        }
      ''';
      expect(await execute(source), equals("ABC"));
    });

    test('Return non-Future from async function', () async {
      const source = '''
        Future<int> getValue() async {
          // No await needed here
          return 99;
        }

        Future<int> main() async {
          return await getValue();
        }
      ''';
      expect(await execute(source), equals(99));
    });

    test('Interpreted Async/Await Tests await in if condition', () async {
      final code = '''
        Future<bool> checkCondition() async {
          await Future.delayed(Duration(milliseconds: 1));
          return true;
        }
        Future<String> main() async {
          String result = "Initial";
          if (await checkCondition()) {
            result = "Condition True";
          }
          return result;
        }
      ''';
      final result = await execute(code);
      expect(result, 'Condition True');
    });

    test('Interpreted Async/Await Tests await in for loop', () async {
      final code = '''
        Future<int> processItem(int i) async {
          await Future.delayed(Duration(milliseconds: 1));
          return i * 10;
        }
        Future<int> main() async {
          int total = 0;
          for (int i = 0; i < 3; i++) {
            total += await processItem(i);
          }
          return total; // 0*10 + 1*10 + 2*10 = 30
        }
      ''';
      final result = await execute(code);
      expect(result, 30);
    });

    test('Interpreted Async/Await Tests await in try/catch (success)',
        () async {
      final code = '''
        Future<String> successfulFuture() async {
          await Future.delayed(Duration(milliseconds: 1));
          return "Success";
        }
        Future<String> main() async {
          String result = "Failed";
          try {
            result = await successfulFuture();
          } catch (e) {
             result = "Caught Error";
          }
          return result;
        }
      ''';
      final result = await execute(code);
      expect(result, 'Success');
    });

    test('Interpreted Async/Await Tests await Future.error in try/catch',
        () async {
      final code = '''
        Future<String> failingFuture() async {
          await Future.delayed(Duration(milliseconds: 1));
          throw 'Future Failed';
        }
        Future<String> main() async {
          String result = "Initial";
          try {
            result = await failingFuture();
            result = "Future Succeeded Unexpectedly"; // Should not reach here
          } catch (e) {
             result = "Caught: \$e";
          }
          return result;
        }
      ''';
      final result = await execute(code);
      expect(result, 'Caught: Future Failed');
    });

    test('Interpreted Async/Await Tests await Future.error without try/catch',
        () async {
      final code = '''
        Future<void> failingFuture() async {
          await Future.delayed(Duration(milliseconds: 1));
          throw 'Deliberate Error';
        }
        Future<void> main() async {
           await failingFuture();
        }
      ''';
      try {
        await execute(code);
        fail('Expected execute to throw an error');
      } catch (e) {
        expect(e.toString().contains('Deliberate Error'), isTrue);
      }
    });
  });
  group('Async Control Flow Tests', () {
    test('async while loop with await in body', () async {
      final result = await execute('''
        // Define a simple async function to introduce an await point
        Future<void> waitABit() async {
           await Future.value(null); // The simplest await possible
        }

        Future<int> counter(int limit) async {
          var i = 0;
          var sum = 0;
          while (i < limit) {
            sum = sum + i;
            i = i + 1;
            // Use our self-defined async function
            await waitABit(); 
          }
          return sum;
        }
        main() {
          return counter(5); // Expect 0+1+2+3+4 = 10
        }
      ''');
      expect(result, equals(10));
    });

    test('async while loop with await in condition', () async {
      final result = await execute('''
        // Helper async function for condition
        Future<bool> shouldContinue(int currentVal) async {
          await Future.value(null); // Simulate async work
          return currentVal < 3; // Condition based on value
        }

        Future<int> looper() async {
          var i = 0;
          while (await shouldContinue(i)) {
            i = i + 1;
          }
          return i; // Expect i to be 3 when loop terminates
        }

        main() {
          return looper();
        }
      ''');
      expect(result, equals(3));
    });

    test('async do-while loop with await in body', () async {
      final result = await execute('''
        Future<void> waitABit() async {
          await Future.value(null);
        }

        Future<int> looper() async {
          var i = 0;
          var sum = 0;
          do {
            sum = sum + i;
            await waitABit(); // Async operation in body
            i = i + 1;
          } while (i < 4); // Condition évaluée après le corps
          // Le corps s'exécute pour i = 0, 1, 2, 3.
          // La condition est vérifiée pour i=1, 2, 3 (true), puis i=4 (false)
          // sum = 0 + 1 + 2 + 3 = 6
          return sum;
        }

        main() {
          return looper();
        }
      ''');
      expect(result, equals(6));
    });

    test('async do-while loop with await in condition', () async {
      final result = await execute('''
        Future<bool> shouldContinue(int currentVal) async {
          await Future.value(null); // Simulate async work
          return currentVal < 3; // Condition based on value
        }

        Future<int> looper() async {
          var i = 0;
          do {
            i = i + 1;
            // Corps exécuté pour i=1, i=2, i=3
          } while (await shouldContinue(i)); // Condition async
          // Vérifie shouldContinue(1) -> true
          // Vérifie shouldContinue(2) -> true
          // Vérifie shouldContinue(3) -> false
          // La boucle termine, i = 3
          return i;
        }

        main() {
          return looper();
        }
      ''');
      expect(result, equals(3));
    });

    test('async for loop with await in body', () async {
      final result = await execute('''
        Future<void> waitABit() async {
          await Future.value(null);
        }

        Future<int> looper() async {
          var sum = 0;
          for (var i = 0; i < 4; i = i + 1) {
            sum = sum + i;
            await waitABit(); // Async in body
          }
          // i = 0, sum = 0, await
          // i = 1, sum = 1, await
          // i = 2, sum = 3, await
          // i = 3, sum = 6, await
          // i = 4, condition false
          return sum; // Expect 6
        }

        main() {
          return looper();
        }
      ''');
      expect(result, equals(6));
    });

    test('async for loop with await in initializer', () async {
      final result = await execute('''
        Future<int> getStart() async {
          await Future.delayed(Duration(milliseconds: 1)); // Simulate async work
          return 1;
        }

        Future<int> looper() async {
          var sum = 0;
          for (var i = await getStart(); i < 4; i = i + 1) {
            sum = sum + i;
          }
          // await -> i = 1
          // i = 1, sum = 1
          // i = 2, sum = 3
          // i = 3, sum = 6
          // i = 4, condition false
          return sum; // Expect 6
        }

        main() {
          return looper();
        }
      ''');
      expect(result, equals(6));
    });

    test('async for loop with await assignment in body', () async {
      final result = await execute(r'''
        Future<int> getValue(int iteration) async {
          await Future.delayed(Duration(milliseconds: 1));
          return iteration * 10;
        }

        Future<int> looper() async {
          int total = 0;
          int lastAwaitedValue = -1;
          for (int i = 0; i < 3; i++) {
            int awaitedValue = await getValue(i); // Assign await result
            lastAwaitedValue = await getValue(i);
            total += i; // Some other work
          }
          // Expected: total = 0+1+2=3, lastAwaitedValue = getValue(2)=20
          return total + lastAwaitedValue;
        }

        main() {
          // Implicitly returns the result of looper()
          return looper();
        }
      ''');

      // Expected result is 3 + 20 = 23
      expect(result, equals(23));
    });

    test('async for loop with await in assignment operator', () async {
      final result = await execute(r'''
        Future<int> getValue(int iteration) async {
          await Future.delayed(Duration(milliseconds: 1));
          return iteration * 10;
        }

        Future<int> looper() async {
          int total = 0;
          for (int i = 0; i < 3; i++) {
            total += await getValue(i); // Assignment operation with await
          }
          // i=0: total += await getValue(0) => total += 0  => total = 0
          // i=1: total += await getValue(1) => total += 10 => total = 10
          // i=2: total += await getValue(2) => total += 20 => total = 30
          return total;
        }

        main() {
          return looper();
        }
      ''');

      // Expected result is 0 + 10 + 20 = 30
      expect(result, equals(30));
    });

    test('async for-in loop with await in body', () async {
      final result = await execute('''
        Future<int> getValue(int iteration) async {
          await Future.delayed(Duration(milliseconds: 1)); // Simulate async work
          final result = iteration * 10;
          return result;
        }

        Future<int> testAsyncForInWithAwaitInBody() async {
          final syncList = [1, 2, 3];
          var total = 0;
          for (var item in syncList) {
            var awaitedValue = await getValue(item);
            total += awaitedValue;
            await Future.delayed(Duration(milliseconds: 1)); // Another await
          }
          return total;
        }

        Future<void> main() async {
          await testAsyncForInWithAwaitInBody();
        }
      ''');

      expect(
        result,
        equals(60),
      );
    });

    test('async try-catch-finally with await throwing error', () async {
      final result = await execute('''
        Future<String> operationThatThrows() async {
          await Future.delayed(Duration(milliseconds: 1));
          throw Exception('Something went wrong asynchronously');
          // Unreachable
          // return "Success";
        }

        Future<String> testTryCatch() async {
          String status = "Initial";
          String finallyStatus = "Not Executed";
          try {
            status = "In Try";
            await operationThatThrows();
            status = "Try Completed (Should not happen)";
          } catch (e) {
            status = "Caught Error";
          } finally {
            finallyStatus = "Finally Executed";
          }
          return "\$status:\$finallyStatus";
        }

        Future<void> main() async {
          await testTryCatch();
        }
      ''');

      expect(
        result,
        equals("Caught Error:Finally Executed"),
      );
    });

    test('async if statement with await in condition', () async {
      final result = await execute(r'''
        Future<bool> checkCondition(bool value) async {
          await Future.delayed(Duration(milliseconds: 1));
          return value;
        }

        Future<String> main() async {
          var result = 'Initial';
          if (await checkCondition(true)) {
            result = 'First If True';
          } else {
            result = 'First If False (Error)';
          }

          if (await checkCondition(false)) {
            result = 'Second If True (Error)';
          } else {
            result = 'Second If False';
          }
          return result;
        }
      ''');

      expect(result, equals('Second If False'));
    });

    test('async try-catch with rethrow and await error', () async {
      final sourceCode = '''
        Future<String> operationThatThrows() async {
          await Future.delayed(Duration(milliseconds: 1));
          throw Exception('Something went wrong asynchronously');
          // Unreachable
          // return "Success";
        }

        Future<String> testTryCatch() async {
          String status = "Initial";
          try {
            status = "In Try";
            await operationThatThrows();
            status = "Try Completed (Should not happen)";
          } catch (e) {
            rethrow;
          }
          return "ok"; 
        }

        Future<void> main() async {
          await testTryCatch();
        }
      ''';

      expect(
        () async => await execute(sourceCode),
        throwsA(isA<Exception>().having((e) => e.toString(), 'toString()',
            'Exception: Something went wrong asynchronously')),
      );
    });

    test('nested for-in loops with list processing', () async {
      const source = '''
      main() async {
        List resultList = [];
        for (var element in [
        [1, 2, 3, 4],
        [5, 6, 7, 8]
        ]) {
        // Introduce a local variable for the current element
        var currentElement = element;
        for (var i = 0; i < currentElement.length; i++) {
          resultList.add(currentElement[i]);
        }
        }
        return resultList;
      }
      ''';
      expect(await execute(source), equals([1, 2, 3, 4, 5, 6, 7, 8]));
    });

    test('nested for loops with list processing using indexed access',
        () async {
      const source = '''
      main() async {
        List resultList = [];
        final dddd = [
        [1, 2, 3, 4],
        [5, 6, 7, 8]
        ];
        for (var i = 0; i < dddd.length; i++) {
        var currentElement = dddd[i];
        for (var j = 0; j < currentElement.length; j++) {
          resultList.add(currentElement[j]);
        }
        }
        return resultList;
      }
      ''';
      expect(await execute(source), equals([1, 2, 3, 4, 5, 6, 7, 8]));
    });
  });
}
