import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('Math Geometry Stdlib Tests', () {
    late D4rt d4rt;

    setUp(() {
      d4rt = D4rt();
    });

    test('Point operators, distances, and is-checks', () {
      final result = d4rt.execute(source: '''
        import 'dart:math';

        main() {
          final p1 = Point(0, 0);
          final p2 = Point(3, 4);
          final p3 = p1 + p2;
          final p4 = p2 * 2;
          final dist = p1.distanceTo(p2);
          final sqDist = p1.squaredDistanceTo(p2);
          final isPt = p1 is Point;

          return [
            p3.x,
            p3.y,
            p4.x,
            p4.y,
            dist,
            sqDist,
            isPt,
          ];
        }
      ''') as List;

      expect(result[0], equals(3));
      expect(result[1], equals(4));
      expect(result[2], equals(6));
      expect(result[3], equals(8));
      expect(result[4], equals(5.0));
      expect(result[5], equals(25));
      expect(result[6], isTrue);
    });

    test('Rectangle.fromPoints, intersection, and is-checks', () {
      final result = d4rt.execute(source: '''
        import 'dart:math';

        main() {
          final p1 = Point(10, 20);
          final p2 = Point(50, 60);
          final rect1 = Rectangle.fromPoints(p1, p2);
          final rect2 = Rectangle(20, 30, 20, 20);
          final mutRect = MutableRectangle.fromPoints(p1, p2);

          final contains = rect1.containsPoint(Point(25, 25));
          final intersects = rect1.intersects(rect2);
          final intersection = rect1.intersection(rect2);
          final isRect = rect1 is Rectangle;
          final isMutRect = mutRect is Rectangle;

          return [
            rect1.left,
            rect1.top,
            rect1.width,
            rect1.height,
            contains,
            intersects,
            intersection?.left,
            intersection?.top,
            isRect,
            isMutRect,
          ];
        }
      ''') as List;

      expect(result[0], equals(10));
      expect(result[1], equals(20));
      expect(result[2], equals(40));
      expect(result[3], equals(40));
      expect(result[4], isTrue);
      expect(result[5], isTrue);
      expect(result[6], equals(20));
      expect(result[7], equals(30));
      expect(result[8], isTrue);
      expect(result[9], isTrue);
    });
  });
}
