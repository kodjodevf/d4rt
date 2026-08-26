import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('MutableRectangle stdlib tests', () {
    test('MutableRectangle creation, getters and setters', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:math';

        main() {
          final rect = MutableRectangle(10, 20, 100, 200);
          rect.left = 15;
          rect.top = 25;
          rect.width = 120;
          rect.height = 220;
          return [rect.left, rect.top, rect.width, rect.height, rect.right, rect.bottom];
        }
      ''');

      expect(result, equals([15, 25, 120, 220, 135, 245]));
    });

    test('MutableRectangle geometric intersections', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:math';

        main() {
          final r1 = MutableRectangle(0, 0, 10, 10);
          final r2 = MutableRectangle(5, 5, 10, 10);
          final p = Point(6, 6);
          return [r1.intersects(r2), r1.containsPoint(p)];
        }
      ''');

      expect(result, equals([true, true]));
    });
  });
}
