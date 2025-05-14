import '../../interpreter_test.dart';
import 'package:test/test.dart';
import 'dart:math';

void main() {
  group('MathCore tests', () {
    test('Math constants', () {
      const source = '''
      import 'dart:math';
      main() {
        return [pi, e, sqrt2, sqrt1_2];
      }
      ''';
      final result = execute(source) as List;
      expect(result[0], closeTo(3.141592653589793, 0.000000000000001));
      expect(result[1], closeTo(2.718281828459045, 0.000000000000001));
      expect(result[2], closeTo(1.4142135623730951, 0.000000000000001));
      expect(result[3], closeTo(0.7071067811865476, 0.000000000000001));
    });

    test('Math functions', () {
      const source = '''
      import 'dart:math';
      main() {
        return [
          cos(0),
          tan(pi / 4),
          sin(pi / 2),
          sqrt(16),
          exp(1),
          log(e),
          pow(2, 3),
          max(10, 20),
          min(10, 20)
        ];
      }
      ''';
      final result = execute(source) as List;
      expect(result[0], equals(1.0));
      expect(result[1], closeTo(1.0, 0.000000000000001));
      expect(result[2], equals(1.0));
      expect(result[3], equals(4.0));
      expect(result[4], closeTo(e, 0.000000000000001));
      expect(result[5], equals(1.0));
      expect(result[6], equals(8));
      expect(result[7], equals(20));
      expect(result[8], equals(10));
    });
  });

  group('PointCore tests', () {
    test('Point properties and methods', () {
      const source = '''
      import 'dart:math';
      main() {
        Point p = Point(3, 4);
        return [p.x, p.y, p.magnitude, p.distanceTo(Point(0, 0))];
      }
      ''';
      expect(execute(source), equals([3, 4, 5.0, 5.0]));
    });
  });

  group('RectangleCore tests', () {
    test('Rectangle properties and methods', () {
      const source = '''
      import 'dart:math';
      main() {
        Rectangle r = Rectangle(0, 0, 10, 20);
        Rectangle intersection = r.intersection(Rectangle(5, 5, 10, 10));
        return [
          r.left,
          r.top,
          r.width,
          r.height,
          r.right,
          r.bottom,
          r.containsPoint(Point(5, 5)),
          r.containsRectangle(Rectangle(1, 1, 5, 5)),
          r.intersects(Rectangle(5, 5, 10, 10)),
          [intersection.left, intersection.top, intersection.width, intersection.height]
        ];
      }
      ''';
      expect(
          execute(source),
          equals([
            0,
            0,
            10,
            20,
            10,
            20,
            true,
            true,
            true,
            [5, 5, 5, 10]
          ]));
    });
  });

  group('RandomCore tests', () {
    test('Random methods', () {
      const source = '''
      import 'dart:math';
      main() {
        Random random = Random(42);
        return [random.nextInt(100), random.nextDouble(), random.nextBool()];
      }
      ''';
      final result = execute(source) as List;
      expect(result[0], isA<int>());
      expect(result[1], isA<double>());
      expect(result[2], isA<bool>());
    });
  });
}
