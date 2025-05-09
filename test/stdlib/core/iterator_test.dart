import '../../interpreter_test.dart';
import 'package:test/test.dart';

void main() {
  group('Iterator tests', () {
    test('Iterator basic usage', () {
      const source = '''
      main() {
        List<int> numbers = [1, 2, 3, 4, 5];
        Iterator<int> iterator = numbers.iterator;
        List<int> result = [];
        while (iterator.moveNext()) {
          result.add(iterator.current);
        }
        return result;
      }
      ''';
      expect(execute(source), equals([1, 2, 3, 4, 5]));
    });

    test('Iterator with empty list', () {
      const source = '''
      main() {
        List<int> numbers = [];
        Iterator<int> iterator = numbers.iterator;
        return iterator.moveNext();
      }
      ''';
      expect(execute(source), equals(false));
    });

    test('Iterator current without moveNext', () {
      const source = '''
      main() {
        List<int> numbers = [1, 2, 3];
        Iterator<int> iterator = numbers.iterator;
        return iterator.current;
      }
      ''';
      expect(execute(source), isNull);
    });

    test('Iterator moveNext after end', () {
      const source = '''
      main() {
        List<int> numbers = [1, 2, 3];
        Iterator<int> iterator = numbers.iterator;
        List<int> iterated = [];
        while (iterator.moveNext()) {
          iterated.add(iterator.current);
        }
        return [iterated, iterator.moveNext()];
      }
      ''';
      expect(
          execute(source),
          equals([
            [1, 2, 3],
            false
          ]));
    });

    test('Iterator with nested loops', () {
      const source = '''
      main() {
        List<List<int>> matrix = [
          [1, 2],
          [3, 4],
          [5, 6]
        ];
        List<int> result = [];
        for (List<int> row in matrix) {
          Iterator<int> iterator = row.iterator;
          while (iterator.moveNext()) {
            result.add(iterator.current);
          }
        }
        return result;
      }
      ''';
      expect(execute(source), equals([1, 2, 3, 4, 5, 6]));
    });

    test('Iterator with custom iterable', () {
      const source = '''
      main() {
        Iterable<int> customIterable = Iterable.generate(5, (i) => i + 1);
        Iterator<int> iterator = customIterable.iterator;
        List<int> result = [];
        while (iterator.moveNext()) {
          result.add(iterator.current);
        }
        return result;
      }
      ''';
      expect(execute(source), equals([1, 2, 3, 4, 5]));
    });

    test('Iterator with break in loop', () {
      const source = '''
      main() {
        List<int> numbers = [1, 2, 3, 4, 5];
        Iterator<int> iterator = numbers.iterator;
        List<int> result = [];
        while (iterator.moveNext()) {
          if (iterator.current == 3) break;
          result.add(iterator.current);
        }
        return result;
      }
      ''';
      expect(execute(source), equals([1, 2]));
    });

    test('Iterator with continue in loop', () {
      const source = '''
      main() {
        List<int> numbers = [1, 2, 3, 4, 5];
        Iterator<int> iterator = numbers.iterator;
        List<int> result = [];
        while (iterator.moveNext()) {
          if (iterator.current % 2 == 0) continue;
          result.add(iterator.current);
        }
        return result;
      }
      ''';
      expect(execute(source), equals([1, 3, 5]));
    });
  });
}
