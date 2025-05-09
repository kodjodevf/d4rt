import 'dart:async';
import 'package:test/test.dart';
import '../../interpreter_test.dart';

void main() {
  group('Interpreted Stream Bindings Tests', () {
    // Helper to run Interpreted code that involves async operations
    Future<dynamic> runInterpretedStreamTest(String code) async {
      final fullSource = '''
        import 'dart:async';

        Future<dynamic> main() async {
           $code
        }
      ''';

      // Use the static mainAsync method assuming it handles interpretation
      return await execute(fullSource);
    }

    group('Stream Static Methods', () {
      test('Stream.value', () async {
        const source = '''
          Stream s = Stream.value(123);
          return await s.first;
        ''';
        expect(await runInterpretedStreamTest(source), equals(123));
      });

      test('Stream.error', () async {
        const source = '''
          Stream s = Stream.error("Test Error");
          try {
            await s.first;
            return "Did not throw";
          } catch (e) {
            return e.toString(); // Interpreted exceptions might be simple strings
          }
        ''';

        expect(await runInterpretedStreamTest(source), contains('Test Error'));
      });

      test('Stream.empty', () async {
        const source = '''
          Stream s = Stream.empty();
          return await s.isEmpty;
        ''';
        expect(await runInterpretedStreamTest(source), isTrue);
      });

      test('Stream.fromIterable', () async {
        const source = '''
          Stream s = Stream.fromIterable([1, 2, 3]);
          return await s.toList();
        ''';
        expect(await runInterpretedStreamTest(source), equals([1, 2, 3]));
      });

      test('Stream.periodic', () async {
        const source = '''
           // Take first 3 values from a stream emitting every 10ms
           Stream s = Stream.periodic(Duration(milliseconds: 10), (i) => i);
           return await s.take(3).toList();
         ''';
        // Expect [0, 1, 2]
        expect(await runInterpretedStreamTest(source), equals([0, 1, 2]));
      });

      test('Stream.fromFuture', () async {
        const source = '''
          Future<String> f = Future.delayed(Duration(milliseconds: 1), () => "done");
          Stream s = Stream.fromFuture(f);
          return await s.toList();
        ''';
        expect(await runInterpretedStreamTest(source), equals(["done"]));
      });

      test('Stream.fromFutures', () async {
        const source = '''
          Future<int> f1 = Future.delayed(Duration(milliseconds: 5), () => 1);
          Future<int> f2 = Future.value(2);
          Future<int> f3 = Future.delayed(Duration(milliseconds: 1), () => 3);
          Stream s = Stream.fromFutures([f1, f2, f3]);
          return await s.toList();
        ''';
        // Order depends on Future completion, but all should be present
        List<dynamic> result =
            await runInterpretedStreamTest(source) as List<dynamic>;
        expect(result, containsAll([1, 2, 3]));
        expect(result.length, 3);
      });
    });

    group('Stream Instance Methods & Properties', () {
      test('stream.first', () async {
        const source = '''
            Stream s = Stream.fromIterable([10, 20, 30]);
            return await s.first;
          ''';
        expect(await runInterpretedStreamTest(source), equals(10));
      });

      test('stream.last', () async {
        const source = '''
             Stream s = Stream.fromIterable([10, 20, 30]);
             return await s.last;
           ''';
        expect(await runInterpretedStreamTest(source), equals(30));
      });

      test('stream.length', () async {
        const source = '''
             Stream s = Stream.fromIterable([10, 20, 30]);
             return await s.length;
           ''';
        expect(await runInterpretedStreamTest(source), equals(3));
      });

      test('stream.isEmpty', () async {
        const source = '''
             Stream s = Stream.fromIterable([10]);
             return await s.isEmpty;
           ''';
        expect(await runInterpretedStreamTest(source), isFalse);
        const sourceEmpty = '''
             Stream s = Stream.empty();
             return await s.isEmpty;
           ''';
        expect(await runInterpretedStreamTest(sourceEmpty), isTrue);
      });

      test('stream.map', () async {
        const source = '''
            Stream s = Stream.fromIterable([1, 2, 3]);
            Stream mapped = s.map((x) => x * 2);
            return await mapped.toList();
          ''';
        expect(await runInterpretedStreamTest(source), equals([2, 4, 6]));
      });

      test('stream.where', () async {
        const source = '''
            Stream s = Stream.fromIterable([1, 2, 3, 4, 5]);
            Stream filtered = s.where((x) => x % 2 == 0); // Even numbers
            return await filtered.toList();
          ''';
        expect(await runInterpretedStreamTest(source), equals([2, 4]));
      });

      test('stream.expand', () async {
        const source = '''
             Stream s = Stream.fromIterable([1, 2]);
             // For each number x, emit x and x+10
             Stream expanded = s.expand((x) => [x, x + 10]);
             return await expanded.toList();
           ''';
        expect(await runInterpretedStreamTest(source), equals([1, 11, 2, 12]));
      });

      test('stream.take', () async {
        const source = '''
             Stream s = Stream.periodic(Duration(milliseconds: 1), (i) => i);
             return await s.take(4).toList();
           ''';
        expect(await runInterpretedStreamTest(source), equals([0, 1, 2, 3]));
      });

      test('stream.skip', () async {
        const source = '''
             Stream s = Stream.fromIterable([1, 2, 3, 4, 5]);
             return await s.skip(3).toList();
           ''';
        expect(await runInterpretedStreamTest(source), equals([4, 5]));
      });

      test('stream.takeWhile', () async {
        const source = '''
                 Stream s = Stream.fromIterable([2, 4, 6, 7, 8]);
                 return await s.takeWhile((n) => n % 2 == 0).toList(); // Take while even
             ''';
        expect(await runInterpretedStreamTest(source), equals([2, 4, 6]));
      });

      test('stream.skipWhile', () async {
        const source = '''
                 Stream s = Stream.fromIterable([2, 4, 6, 7, 8]);
                 return await s.skipWhile((n) => n < 5).toList(); // Skip while less than 5
             ''';
        expect(await runInterpretedStreamTest(source), equals([6, 7, 8]));
      });

      test('stream.distinct', () async {
        const source = '''
                Stream s = Stream.fromIterable([1, 2, 2, 3, 1, 3, 4, 2]);
                return await s.distinct().toList();
            ''';
        expect(await runInterpretedStreamTest(source),
            equals([1, 2, 3, 1, 3, 4, 2]));

        // With custom equals (based on first char for strings)
        const sourceCustom = '''
                bool firstCharEquals(prev, next) {
                    if (prev is String && next is String && prev.isNotEmpty && next.isNotEmpty) {
                        return prev[0] == next[0];
                    }
                    return prev == next;
                }
                Stream s = Stream.fromIterable(["apple", "apricot", "banana", "avocado", "berry"]);
                return await s.distinct(firstCharEquals).toList();
            ''';
        expect(await runInterpretedStreamTest(sourceCustom),
            equals(["apple", "banana", "avocado", "berry"]));
      });

      test('stream.toList', () async {
        const source = '''
             Stream s = Stream.fromIterable([5, 10, 15]);
             return await s.toList();
           ''';
        expect(await runInterpretedStreamTest(source), equals([5, 10, 15]));
      });

      test('stream.toSet', () async {
        const source = '''
             Stream s = Stream.fromIterable([1, 2, 1, 3, 2]);
             Set result = await s.toSet();
             // Convert set to list for easier comparison in expect
             List sorted = result.toList();
             sorted.sort();
             return sorted;
           ''';
        expect(await runInterpretedStreamTest(source), equals([1, 2, 3]));
      });

      test('stream.join', () async {
        const source = '''
             Stream s = Stream.fromIterable(["a", "b", "c"]);
             return await s.join("-");
           ''';
        expect(await runInterpretedStreamTest(source), equals("a-b-c"));
      });

      test('stream.any', () async {
        const source = '''
                Stream s = Stream.fromIterable([1, 3, 5, 6, 7]);
                return await s.any((n) => n % 2 == 0); // Is any even?
            ''';
        expect(await runInterpretedStreamTest(source), isTrue);
      });

      test('stream.every', () async {
        const source = '''
                Stream s = Stream.fromIterable([2, 4, 6, 8]);
                return await s.every((n) => n % 2 == 0); // Are all even?
            ''';
        expect(await runInterpretedStreamTest(source), isTrue);
        const sourceFalse = '''
                 Stream s = Stream.fromIterable([2, 4, 5, 8]);
                 return await s.every((n) => n % 2 == 0);
             ''';
        expect(await runInterpretedStreamTest(sourceFalse), isFalse);
      });

      test('stream.contains', () async {
        const source = '''
                Stream s = Stream.fromIterable([10, 20, 30]);
                return await s.contains(20);
            ''';
        expect(await runInterpretedStreamTest(source), isTrue);
        const sourceFalse = '''
                Stream s = Stream.fromIterable([10, 20, 30]);
                return await s.contains(40);
            ''';
        expect(await runInterpretedStreamTest(sourceFalse), isFalse);
      });

      test('stream.fold', () async {
        const source = '''
             Stream s = Stream.fromIterable([1, 2, 3, 4]);
             // Sum the stream, starting with initial value 10
             return await s.fold(10, (prev, element) => prev + element);
           ''';
        // 10 + 1 + 2 + 3 + 4 = 20
        expect(await runInterpretedStreamTest(source), equals(20));
      });

      test('stream.reduce', () async {
        const source = '''
             Stream s = Stream.fromIterable([1, 2, 3, 4]);
             // Sum the stream (no initial value)
             return await s.reduce((prev, element) => prev + element);
           ''';
        // 1 + 2 + 3 + 4 = 10
        expect(await runInterpretedStreamTest(source), equals(10));
      });

      test('stream.forEach', () async {
        const source = '''
             Stream s = Stream.fromIterable([10, 20, 30]);
             List<dynamic> collectedResults = [];
             // Add items to the local list
             await s.forEach((item) => collectedResults.add(item * 3));
             return collectedResults; // Return the collected list
           ''';
        var results = await runInterpretedStreamTest(source);
        expect(results, equals([30, 60, 90]));
      });

      test('stream.cast', () async {
        const source = '''
               Stream<num> s = Stream.fromIterable([1, 2.5, 3]);
               Stream<dynamic> casted = s.cast(); // Casts to dynamic via binding
               // We can't easily test the *type* here, but check if elements pass through
               return await casted.toList();
           ''';
        expect(await runInterpretedStreamTest(source), equals([1, 2.5, 3]));
      });

      test('stream.asBroadcastStream', () async {
        const source = '''
             StreamController controller = StreamController();
             Stream singleSub = controller.stream;
             Stream broadcast = singleSub.asBroadcastStream();

             List<dynamic> results1 = [];
             List<dynamic> results2 = [];

             broadcast.listen((data) => results1.add(data));
             broadcast.listen((data) => results2.add("item:" + data.toString()));

             controller.add(1);
             controller.add(2);
             await Future.delayed(Duration(milliseconds: 5)); // Allow listeners to process
             await controller.close();

             // Return results from both listeners
             return [results1, results2];
           ''';
        List<dynamic> result =
            await runInterpretedStreamTest(source) as List<dynamic>;
        expect(result.length, 2);
        expect(result[0], equals([1, 2]));
        expect(result[1], equals(["item:1", "item:2"]));
      });
    });

    group('Stream Listen & Subscription', () {
      test('listen with onData, onDone', () async {
        const source = '''
            StreamController controller = StreamController();
            List<dynamic> dataReceived = [];
            bool doneCalled = false;
            Completer doneCompleter = Completer();

            StreamSubscription sub = controller.stream.listen(
              (data) => dataReceived.add(data * 10),
              onDone: () {
                 doneCalled = true;
                 doneCompleter.complete();
              }
            );

            controller.add(1);
            controller.add(2);
            await controller.close(); // Triggers onDone

            await doneCompleter.future; // Wait for onDone callback

            return {'data': dataReceived, 'done': doneCalled};
          ''';
        Map<dynamic, dynamic> result =
            await runInterpretedStreamTest(source) as Map<dynamic, dynamic>;
        expect(result['data'], equals([10, 20]));
        expect(result['done'], isTrue);
      });

      test('listen with onError', () async {
        const source = '''
            StreamController controller = StreamController();
            dynamic errorReceived = null;
            Completer errorCompleter = Completer();

            StreamSubscription sub = controller.stream.listen(
              null, // No onData needed for this test
              onError: (err, stack) { // Interpreted functions might receive stack too
                 errorReceived = err;
                 errorCompleter.complete();
              }
            );

            controller.addError("Boom!");
            // Don't close, error should be caught

            await errorCompleter.future; // Wait for onError

            return errorReceived;
          ''';
        expect(await runInterpretedStreamTest(source), equals("Boom!"));
      });
    });
  });
}
