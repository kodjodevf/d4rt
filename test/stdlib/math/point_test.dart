import '../../interpreter_test.dart';
import 'package:test/test.dart';

void main() {
  group('PointCore tests', () {
    test('Point properties', () {
      const source = '''
      import 'dart:math';
      main() {
        Point p = Point(3, 4);
        return [p.x, p.y, p.magnitude];
      }
      ''';
      expect(execute(source), equals([3, 4, 5.0]));
    });

    test('Point distanceTo', () {
      const source = '''
      import 'dart:math';
      main() {
        Point p1 = Point(3, 4);
        Point p2 = Point(0, 0);
        return p1.distanceTo(p2);
      }
      ''';
      expect(execute(source), equals(5.0));
    });

    test('Point squaredDistanceTo', () {
      const source = '''
      import 'dart:math';
      main() {
        Point p1 = Point(3, 4);
        Point p2 = Point(0, 0);
        return p1.squaredDistanceTo(p2);
      }
      ''';
      expect(execute(source), equals(25));
    });

    test('Point toString', () {
      const source = '''
      import 'dart:math';
      main() {
        Point p = Point(3, 4);
        return p.toString();
      }
      ''';
      expect(execute(source), equals('Point(3, 4)'));
    });

    test('Point equality and hashCode', () {
      const source = '''
      import 'dart:math';
      main() {
        Point p1 = Point(3, 4);
        Point p2 = Point(3, 4);
        Point p3 = Point(0, 0);
        return [p1 == p2, p1 == p3, p1.hashCode == p2.hashCode];
      }
      ''';
      expect(execute(source), equals([true, false, true]));
    });
  });
}
