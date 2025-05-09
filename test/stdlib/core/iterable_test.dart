import '../../interpreter_test.dart';
import 'package:test/test.dart';

void main() {
  group('Iterable tests', () {
    test('Iterable.map and Iterable.where', () {
      const source = '''
      main() {
        Iterable<int> numbers = [1, 2, 3, 4, 5];
        Iterable<int> doubled = numbers.map((n) => n * 2);
        Iterable<int> evens = numbers.where((n) => n % 2 == 0);
        return [doubled.toList(), evens.toList()];
      }
      ''';
      expect(
          execute(source),
          equals([
            [2, 4, 6, 8, 10],
            [2, 4]
          ]));
    });

    test('Iterable.reduce and Iterable.fold', () {
      const source = '''
      main() {
        Iterable<int> numbers = [1, 2, 3, 4, 5];
        int sum = numbers.reduce((a, b) => a + b);
        int product = numbers.fold(1, (a, b) => a * b);
        return [sum, product];
      }
      ''';
      expect(execute(source), equals([15, 120]));
    });

    test('Iterable.first, last, and length', () {
      const source = '''
      main() {
        Iterable<int> numbers = [1, 2, 3, 4, 5];
        return [numbers.first, numbers.last, numbers.length];
      }
      ''';
      expect(execute(source), equals([1, 5, 5]));
    });

    test('Iterable.contains and Iterable.any', () {
      const source = '''
      main() {
        Iterable<int> numbers = [1, 2, 3, 4, 5];
        return [numbers.contains(3), numbers.any((n) => n > 4)];
      }
      ''';
      expect(execute(source), equals([true, true]));
    });

    test('Iterable.every and Iterable.take', () {
      const source = '''
      main() {
        Iterable<int> numbers = [1, 2, 3, 4, 5];
        return [numbers.every((n) => n > 0), numbers.take(3).toList()];
      }
      ''';
      expect(
          execute(source),
          equals([
            true,
            [1, 2, 3]
          ]));
    });

    test('Iterable.skip and Iterable.toList', () {
      const source = '''
      main() {
        Iterable<int> numbers = [1, 2, 3, 4, 5];
        return [numbers.skip(2).toList(), numbers.toList()];
      }
      ''';
      expect(
          execute(source),
          equals([
            [3, 4, 5],
            [1, 2, 3, 4, 5]
          ]));
    });

    test('Iterable.join and Iterable.toSet', () {
      const source = '''
      main() {
        Iterable<int> numbers = [1, 2, 3, 4, 5];
        var setList = numbers.toSet().toList();
        setList.sort();
        return [numbers.join(", "), setList];
      }
      ''';
      expect(
          execute(source),
          equals([
            '1, 2, 3, 4, 5',
            [1, 2, 3, 4, 5]
          ]));
    });

    test('Iterable.expand', () {
      const source = '''
      main() {
        Iterable<int> numbers = [1, 2, 3];
        Iterable<int> expanded = numbers.expand((n) => [n, n * 2]);
        return expanded.toList();
      }
      ''';
      expect(execute(source), equals([1, 2, 2, 4, 3, 6]));
    });

    test('Iterable.forEach', () {
      const source = '''
      main() {
        Iterable<int> numbers = [1, 2, 3];
        var sum = 0;
        numbers.forEach((n) => sum += n);
        return sum;
      }
      ''';
      expect(execute(source), equals(6));
    });

    test('Iterable.isEmpty and Iterable.isNotEmpty', () {
      const source = '''
      main() {
        Iterable<int> numbers = [1, 2, 3];
        Iterable<int> empty = [];
        return [numbers.isEmpty, numbers.isNotEmpty, empty.isEmpty, empty.isNotEmpty];
      }
      ''';
      expect(execute(source), equals([false, true, true, false]));
    });
  });
}
