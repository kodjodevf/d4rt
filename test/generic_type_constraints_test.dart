import 'package:test/test.dart';
import 'package:d4rt/d4rt.dart';
import 'interpreter_test.dart';

void main() {
  group('Generic Type Constraints:', () {
    test('num type satisfies Comparable<dynamic> bound', () {
      final code = '''
        class Box<T extends Comparable<dynamic>> {
          T value;
          Box(this.value);
        }

        main() {
          var b = Box<num>(42);
          return b.value;
        }
      ''';
      expect(execute(code), equals(42));
    });

    test('int type satisfies Comparable bound', () {
      final code = '''
        class Container<T extends Comparable> {
          T item;
          Container(this.item);
        }

        main() {
          var c = Container<int>(5);
          return c.item;
        }
      ''';
      expect(execute(code), equals(5));
    });

    test('double type satisfies Comparable bound', () {
      final code = '''
        class Wrapper<T extends Comparable> {
          T data;
          Wrapper(this.data);
        }

        main() {
          var w = Wrapper<double>(3.14);
          return w.data;
        }
      ''';
      expect(execute(code), equals(3.14));
    });

    test('String type satisfies Comparable bound', () {
      final code = '''
        class Holder<T extends Comparable> {
          T content;
          Holder(this.content);
        }

        main() {
          var h = Holder<String>("hello");
          return h.content;
        }
      ''';
      expect(execute(code), equals("hello"));
    });

    test('Type argument not satisfying bound throws error', () {
      final code = '''
        class Box<T extends Comparable> {
          T value;
          Box(this.value);
        }

        class NotComparable {}

        main() {
          var b = Box<NotComparable>(NotComparable());
          return b.value;
        }
      ''';
      expect(() => execute(code), throwsA(isA<RuntimeError>()));
    });

    test('num satisfies multiple numeric constraints', () {
      final code = '''
        class NumBox<T extends num> {
          T value;
          NumBox(this.value);
        }

        main() {
          var b = NumBox<num>(99);
          return b.value;
        }
      ''';
      expect(execute(code), equals(99));
    });

    test('Generic with Comparable bound and casting', () {
      final code = '''
        class SortableBox<T extends Comparable> {
          T value;
          SortableBox(this.value);
        }

        main() {
          var b1 = SortableBox<int>(5);
          var b2 = SortableBox<int>(3);
          return [b1.value, b2.value];
        }
      ''';
      expect(execute(code), equals([5, 3]));
    });

    test('Nested generic with Comparable bound', () {
      final code = '''
        class Pair<T extends Comparable> {
          T first;
          T second;
          Pair(this.first, this.second);
        }

        main() {
          var p = Pair<String>("a", "b");
          return [p.first, p.second];
        }
      ''';
      expect(execute(code), equals(['a', 'b']));
    });
  });
}
