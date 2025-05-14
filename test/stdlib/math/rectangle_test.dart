import '../../interpreter_test.dart';
import 'package:test/test.dart';

void main() {
  group('RectangleCore tests', () {
    test('Rectangle properties', () {
      const source = '''
      import 'dart:math';
      main() {
        Rectangle r = Rectangle(0, 0, 10, 20);
        return [r.left, r.top, r.width, r.height, r.right, r.bottom];
      }
      ''';
      expect(execute(source), equals([0, 0, 10, 20, 10, 20]));
    });

    test('Rectangle containsPoint', () {
      const source = '''
      import 'dart:math';
      main() {
        Rectangle r = Rectangle(0, 0, 10, 20);
        return [r.containsPoint(Point(5, 5)), r.containsPoint(Point(15, 5))];
      }
      ''';
      expect(execute(source), equals([true, false]));
    });

    test('Rectangle containsRectangle', () {
      const source = '''
      import 'dart:math';
      main() {
        Rectangle r1 = Rectangle(0, 0, 10, 20);
        Rectangle r2 = Rectangle(1, 1, 5, 5);
        Rectangle r3 = Rectangle(5, 5, 10, 10);
        return [r1.containsRectangle(r2), r1.containsRectangle(r3)];
      }
      ''';
      expect(execute(source), equals([true, false]));
    });

    test('Rectangle intersects', () {
      const source = '''
      import 'dart:math';
      main() {
        Rectangle r1 = Rectangle(0, 0, 10, 20);
        Rectangle r2 = Rectangle(5, 5, 10, 10);
        Rectangle r3 = Rectangle(15, 15, 5, 5);
        return [r1.intersects(r2), r1.intersects(r3)];
      }
      ''';
      expect(execute(source), equals([true, false]));
    });

    test('Rectangle intersection', () {
      const source = '''
      import 'dart:math';
      main() {
        Rectangle r1 = Rectangle(0, 0, 10, 20);
        Rectangle r2 = Rectangle(5, 5, 10, 10);
        Rectangle r3 = Rectangle(15, 15, 5, 5);
        Rectangle? intersect1 = r1.intersection(r2);
        Rectangle? intersect2 = r1.intersection(r3);
        return [
          intersect1 == null ? null : [intersect1.left, intersect1.top, intersect1.width, intersect1.height],
          intersect2 == null ? null : [intersect2.left, intersect2.top, intersect2.width, intersect2.height]
        ];
      }
      ''';
      expect(
          execute(source),
          equals([
            [5, 5, 5, 10],
            null
          ]));
    });

    test('Rectangle toString', () {
      const source = '''
      import 'dart:math';
      main() {
        Rectangle r = Rectangle(0, 0, 10, 20);
        return r.toString();
      }
      ''';
      expect(execute(source), equals('Rectangle (0, 0) 10 x 20'));
    });

    test('Rectangle equality and hashCode', () {
      const source = '''
      import 'dart:math';
      main() {
        Rectangle r1 = Rectangle(0, 0, 10, 20);
        Rectangle r2 = Rectangle(0, 0, 10, 20);
        Rectangle r3 = Rectangle(5, 5, 10, 10);
        return [r1 == r2, r1 == r3, r1.hashCode == r2.hashCode];
      }
      ''';
      expect(execute(source), equals([true, false, true]));
    });
  });
}
