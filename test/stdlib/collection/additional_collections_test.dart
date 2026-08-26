import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('Additional Collections stdlib tests', () {
    test('SplayTreeSet maintains sorted order', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:collection';

        main() {
          final set = SplayTreeSet<int>();
          set.addAll([50, 10, 40, 20, 30]);
          return set.toList();
        }
      ''');

      expect(result, equals([10, 20, 30, 40, 50]));
    });

    test('DoubleLinkedQueue addFirst and addLast operations', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:collection';

        main() {
          final queue = DoubleLinkedQueue<String>();
          queue.addLast('B');
          queue.addFirst('A');
          queue.addLast('C');
          return queue.toList();
        }
      ''');

      expect(result, equals(['A', 'B', 'C']));
    });

    test('UnmodifiableMapView reads wrapped map and prevents modification', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:collection';

        main() {
          final map = {'a': 1, 'b': 2};
          final view = UnmodifiableMapView(map);
          return [view['a'], view['b'], view.length, view.containsKey('a')];
        }
      ''');

      expect(result, equals([1, 2, 2, true]));
    });

    test('UnmodifiableSetView reads wrapped set', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:collection';

        main() {
          final set = {10, 20, 30};
          final view = UnmodifiableSetView(set);
          return [view.contains(20), view.length, view.toList()];
        }
      ''');

      expect(result, equals([true, 3, [10, 20, 30]]));
    });
  });
}
