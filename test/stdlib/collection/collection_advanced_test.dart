import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('Collection Advanced Features & HasNextIterator Tests', () {
    late D4rt d4rt;

    setUp(() {
      d4rt = D4rt();
    });

    test('HasNextIterator functionality and subtyping', () {
      final result = d4rt.execute(source: '''
        import 'dart:collection';

        main() {
          final list = [10, 20, 30];
          final iter = HasNextIterator(list.iterator);

          final isHasNextIter = iter is HasNextIterator;

          final values = [];
          while (iter.hasNext) {
            values.add(iter.next());
          }

          return [isHasNextIter, values, iter.hasNext];
        }
      ''') as List;

      expect(result[0], isTrue);
      expect(result[1], equals([10, 20, 30]));
      expect(result[2], isFalse);
    });

    test('Queue.of, ListQueue.of, DoubleLinkedQueue.of constructors', () {
      final result = d4rt.execute(source: '''
        import 'dart:collection';

        main() {
          final q = Queue.of([1, 2, 3]);
          final lq = ListQueue.of([4, 5, 6]);
          final dlq = DoubleLinkedQueue.of([7, 8, 9]);

          final isQ = q is Queue;
          final isLQ = lq is ListQueue;
          final isLQQueue = lq is Queue;
          final isDLQ = dlq is DoubleLinkedQueue;
          final isDLQQueue = dlq is Queue;

          return [
            isQ,
            isLQ,
            isLQQueue,
            isDLQ,
            isDLQQueue,
            q.toList(),
            lq.toList(),
            dlq.toList(),
          ];
        }
      ''') as List;

      expect(result[0], isTrue);
      expect(result[1], isTrue);
      expect(result[2], isTrue);
      expect(result[3], isTrue);
      expect(result[4], isTrue);
      expect(result[5], equals([1, 2, 3]));
      expect(result[6], equals([4, 5, 6]));
      expect(result[7], equals([7, 8, 9]));
    });

    test('Map, Set, and LinkedList subtyping in dart:collection', () {
      final result = d4rt.execute(source: '''
        import 'dart:collection';

        main() {
          final hm = HashMap();
          final lhm = LinkedHashMap();
          final sm = SplayTreeMap();

          final hs = HashSet();
          final lhs = LinkedHashSet();
          final ss = SplayTreeSet();

          final ll = LinkedList();

          return [
            hm is HashMap,
            lhm is LinkedHashMap,
            sm is SplayTreeMap,
            hs is HashSet,
            lhs is LinkedHashSet,
            ss is SplayTreeSet,
            ll is LinkedList,
          ];
        }
      ''') as List;

      expect(result[0], isTrue);
      expect(result[1], isTrue);
      expect(result[2], isTrue);
      expect(result[3], isTrue);
      expect(result[4], isTrue);
      expect(result[5], isTrue);
      expect(result[6], isTrue);
    });
  });
}
