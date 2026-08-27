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
