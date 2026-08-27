import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('MapView and collection views stdlib tests', () {
    test('MapView delegates read and write operations', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:collection';

        main() {
          final underlying = {'a': 1, 'b': 2};
          final view = MapView(underlying);
          view['c'] = 3;
          return [view.length, view['a'], underlying['c'], view.containsKey('b')];
        }
      ''') as List;

      expect(result[0], equals(3));
      expect(result[1], equals(1));
      expect(result[2], equals(3));
      expect(result[3], isTrue);
    });

    test('LinkedHashSet creation, mutation, and is-checks', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:collection';

        main() {
          final set1 = LinkedHashSet.from([1, 2, 3]);
          set1.add(4);
          final set2 = LinkedHashSet.of([3, 4, 5]);
          final unionSet = set1.union(set2);
          final isSet = set1 is Set;
          final isLinkedHashSet = set1 is LinkedHashSet;
          return [set1.length, set1.contains(2), unionSet.length, isSet, isLinkedHashSet];
        }
      ''') as List;

      expect(result[0], equals(4));
      expect(result[1], isTrue);
      expect(result[2], equals(5));
      expect(result[3], isTrue);
      expect(result[4], isTrue);
    });

    test('UnmodifiableSetView wraps and exposes set contents', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:collection';

        main() {
          final underlying = {10, 20, 30};
          final view = UnmodifiableSetView(underlying);
          return [view.length, view.contains(20), view.contains(99)];
        }
      ''') as List;

      expect(result[0], equals(3));
      expect(result[1], isTrue);
      expect(result[2], isFalse);
    });
  });
}
