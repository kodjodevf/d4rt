import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('Object.hash, Object.hashAll, Object.hashAllUnordered tests', () {
    test('Object.hash with values produces deterministic int', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        main() {
          final h1 = Object.hash(1, 2, 'hello');
          final h2 = Object.hash(1, 2, 'hello');
          final h3 = Object.hash(1, 2, 'world');
          return [h1 == h2, h1 != h3, h1 is int];
        }
      ''') as List;

      expect(result[0], isTrue);
      expect(result[1], isTrue);
      expect(result[2], isTrue);
    });

    test('Object.hashAll with iterable', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        main() {
          final list1 = [10, 20, 30];
          final list2 = [10, 20, 30];
          return Object.hashAll(list1) == Object.hashAll(list2);
        }
      ''');

      expect(result, isTrue);
    });

    test('Object.hashAllUnordered produces equal hash regardless of ordering', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        main() {
          final list1 = [1, 2, 3];
          final list2 = [3, 2, 1];
          return Object.hashAllUnordered(list1) == Object.hashAllUnordered(list2);
        }
      ''');

      expect(result, isTrue);
    });
  });
}
