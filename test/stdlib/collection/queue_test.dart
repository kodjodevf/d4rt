import 'package:test/test.dart';
import 'package:d4rt/d4rt.dart';

void main() {
  group('dart:collection - Queue Tests', () {
    D4rt d4rtInstance = D4rt();

    setUp(() {
      d4rtInstance = D4rt();
    });

    dynamic execute(String mainFunctionBody, {List<Object?>? args}) {
      final source = '''
        import 'dart:collection';

        main() {
          $mainFunctionBody
        }
      ''';
      return d4rtInstance.execute(
        library: 'd4rt-mem:/main_collection_test.dart',
        name: 'main',
        positionalArgs: args,
        sources: {'d4rt-mem:/main_collection_test.dart': source},
      );
    }

    test('Queue() constructor and basic properties', () {
      final result = execute('''
        var q = Queue();
        return [q.length, q.isEmpty, q.isNotEmpty];
      ''');
      expect(result, equals([0, true, false]));
    });

    test('Queue.from() constructor with an iterable', () {
      final result = execute('''
        var q = Queue.from([1, 2, 3]);
        return [q.length, q.first, q.last];
      ''');
      expect(result, equals([3, 1, 3]));
    });

    test('Queue.from() with empty iterable', () {
      final result = execute('''
        var q = Queue.from([]);
        return q.length;
      ''');
      expect(result, equals(0));
    });

    test('add() and removeFirst() methods', () {
      final result = execute('''
        var q = Queue();
        q.add(10);
        q.add(20);
        var r1 = q.removeFirst();
        var r2 = q.removeFirst();
        return [r1, r2, q.length];
      ''');
      expect(result, equals([10, 20, 0]));
    });

    test('removeFirst() on empty queue throws', () {
      expect(
        () => execute('''
          var q = Queue();
          q.removeFirst();
        '''),
        throwsA(isA<RuntimeError>().having(
          (e) => e.message,
          'message',
          contains('Cannot removeFirst from an empty queue.'),
        )),
      );
    });

    test('first and last getters', () {
      final result = execute('''
        var q = Queue.from(['a', 'b', 'c']);
        return [q.first, q.last];
      ''');
      expect(result, equals(['a', 'c']));
    });

    test('first getter on empty queue throws', () {
      expect(
        () => execute('''
          var q = Queue();
          return q.first;
        '''),
        throwsA(isA<RuntimeError>().having(
          (e) => e.message,
          'message',
          contains('Cannot get first from an empty queue.'),
        )),
      );
    });

    test('last getter on empty queue throws', () {
      expect(
        () => execute('''
          var q = Queue();
          return q.last;
        '''),
        throwsA(isA<RuntimeError>().having(
          (e) => e.message,
          'message',
          contains('Cannot get last from an empty queue.'),
        )),
      );
    });

    test('clear() method', () {
      final result = execute('''
        var q = Queue.from([1, 2, 3]);
        q.clear();
        return q.length;
      ''');
      expect(result, equals(0));
    });

    test('contains() method', () {
      final result = execute('''
        var q = Queue.from([10, 20, 30]);
        return [q.contains(20), q.contains(40)];
      ''');
      expect(result, equals([true, false]));
    });
  });
}
