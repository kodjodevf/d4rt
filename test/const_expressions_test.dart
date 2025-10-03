import 'package:test/test.dart';
import 'interpreter_test.dart' show execute;

void main() {
  group('Const Expressions', () {
    test('const List with simple values', () {
      const code = '''
main() {
  const list = [1, 2, 3];
  return list.length;
}
''';
      final result = execute(code);
      expect(result, equals(3));
    });

    test('const List with typed declaration', () {
      const code = '''
main() {
  const List<int> numbers = [10, 20, 30];
  return numbers[1];
}
''';
      final result = execute(code);
      expect(result, equals(20));
    });

    test('const Map with simple key-value pairs', () {
      const code = '''
main() {
  const map = {'name': 'John', 'age': 30};
  return map['name'];
}
''';
      final result = execute(code);
      expect(result, equals('John'));
    });

    test('const Map with typed declaration', () {
      const code = '''
main() {
  const Map<String, int> scores = {'Alice': 95, 'Bob': 87};
  return scores['Alice'];
}
''';
      final result = execute(code);
      expect(result, equals(95));
    });

    test('const Set with simple values', () {
      const code = '''
main() {
  const set = {1, 2, 3, 2, 1};
  return set.length;
}
''';
      final result = execute(code);
      expect(result, equals(3)); // Duplicates removed
    });

    test('const Set with typed declaration', () {
      const code = '''
main() {
  const Set<String> fruits = {'apple', 'banana', 'orange'};
  return fruits.contains('banana');
}
''';
      final result = execute(code);
      expect(result, equals(true));
    });

    test('const List with expressions', () {
      const code = '''
main() {
  const list = [1 + 1, 2 * 3, 10 - 5];
  return list[0] + list[1] + list[2];
}
''';
      final result = execute(code);
      expect(result, equals(2 + 6 + 5)); // 13
    });

    test('const nested List', () {
      const code = '''
main() {
  const nested = [[1, 2], [3, 4], [5, 6]];
  return nested[1][0];
}
''';
      final result = execute(code);
      expect(result, equals(3));
    });

    test('const nested Map', () {
      const code = '''
main() {
  const data = {
    'user1': {'name': 'Alice', 'age': 25},
    'user2': {'name': 'Bob', 'age': 30}
  };
  return data['user1']['name'];
}
''';
      final result = execute(code);
      expect(result, equals('Alice'));
    });

    test('const List with String concatenation', () {
      const code = '''
main() {
  const list = ['Hello' + ' ' + 'World', 'Dart'];
  return list[0];
}
''';
      final result = execute(code);
      expect(result, equals('Hello World'));
    });

    test('const empty collections', () {
      const code = '''
main() {
  const emptyList = <int>[];
  const emptyMap = <String, int>{};
  const emptySet = <double>{};
  
  return emptyList.length + emptyMap.length + emptySet.length;
}
''';
      final result = execute(code);
      expect(result, equals(0));
    });

    test('const with conditional expression', () {
      const code = '''
main() {
  const value = true ? 42 : 0;
  return value;
}
''';
      final result = execute(code);
      expect(result, equals(42));
    });

    test('const List with const keyword on literal', () {
      const code = '''
main() {
  // Test with const directly on the literal
  final list = const [1, 2, 3];
  return list.length;
}
''';
      final result = execute(code);
      expect(result, equals(3));
    });

    test('const Map with const keyword on literal', () {
      const code = '''
main() {
  final map = const {'key': 'value', 'key2': 'value2'};
  return map.length;
}
''';
      final result = execute(code);
      expect(result, equals(2));
    });

    test('const Set with const keyword on literal', () {
      const code = '''
main() {
  final set = const {1, 2, 3};
  return set.length;
}
''';
      final result = execute(code);
      expect(result, equals(3));
    });
  });
}
