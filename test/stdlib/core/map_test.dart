import '../../interpreter_test.dart';
import 'package:test/test.dart';

void main() {
  group('Map methods - comprehensive', () {
    test('addAll', () {
      const source = '''
     main() {
        Map<int, String> map = {1: 'one'};
        map.addAll({2: 'two', 3: 'three'});
        return map;
      }
      ''';
      expect(execute(source), equals({1: 'one', 2: 'two', 3: 'three'}));
    });

    test('clear', () {
      const source = '''
     main() {
        Map<int, String> map = {1: 'one', 2: 'two'};
        map.clear();
        return map;
      }
      ''';
      expect(execute(source), equals({}));
    });

    test('containsKey', () {
      const source = '''
     main() {
        Map<int, String> map = {1: 'one', 2: 'two'};
        return [map.containsKey(1), map.containsKey(3)];
      }
      ''';
      expect(execute(source), equals([true, false]));
    });

    test('containsValue', () {
      const source = '''
     main() {
        Map<int, String> map = {1: 'one', 2: 'two'};
        return [map.containsValue('two'), map.containsValue('three')];
      }
      ''';
      expect(execute(source), equals([true, false]));
    });

    test('remove', () {
      const source = '''
     main() {
        Map<int, String> map = {1: 'one', 2: 'two'};
        map.remove(1);
        return map;
      }
      ''';
      expect(execute(source), equals({2: 'two'}));
    });

    test('length', () {
      const source = '''
     main() {
        Map<int, String> map = {1: 'one', 2: 'two'};
        return map.length;
      }
      ''';
      expect(execute(source), equals(2));
    });

    test('isEmpty and isNotEmpty', () {
      const source = '''
     main() {
        Map<int, String> map = {};
        return [map.isEmpty, map.isNotEmpty];
      }
      ''';
      expect(execute(source), equals([true, false]));
    });

    test('keys and values', () {
      const source = '''
     main() {
        Map<int, String> map = {1: 'one', 2: 'two'};
        return [map.keys.toList(), map.values.toList()];
      }
      ''';
      expect(
          execute(source),
          equals([
            [1, 2],
            ['one', 'two']
          ]));
    });

    test('update', () {
      const source = '''
     main() {
        Map<int, String> map = {1: 'one', 2: 'two'};
        map.update(1, (value) => 'ONE');
        return map;
      }
      ''';
      expect(execute(source), equals({1: 'ONE', 2: 'two'}));
    });

    test('putIfAbsent', () {
      const source = '''
     main() {
        Map<int, String> map = {1: 'one'};
        map.putIfAbsent(2, () => 'two');
        return map;
      }
      ''';
      expect(execute(source), equals({1: 'one', 2: 'two'}));
    });

    test('addEntries', () {
      const source = '''
     main() {
        Map<int, String> map = {1: 'one'};
        map.addEntries([MapEntry(2, 'two'), MapEntry(3, 'three')]);
        return map;
      }
      ''';
      expect(execute(source), equals({1: 'one', 2: 'two', 3: 'three'}));
    });

    test('updateAll', () {
      const source = '''
     main() {
        Map<int, String> map = {1: 'one', 2: 'two'};
        map.updateAll((key, value) => value.toUpperCase());
        return map;
      }
      ''';
      expect(execute(source), equals({1: 'ONE', 2: 'TWO'}));
    });

    test('removeWhere', () {
      const source = '''
     main() {
        Map<int, String> map = {1: 'one', 2: 'two', 3: 'three'};
        map.removeWhere((key, value) => key % 2 == 0);
        return map;
      }
      ''';
      expect(execute(source), equals({1: 'one', 3: 'three'}));
    });

    test('map', () {
      const source = '''
     main() {
        Map<int, String> map = {1: 'one', 2: 'two'};
        Map<String, int> newMap = map.map((key, value) => MapEntry(value, key));
        return newMap;
      }
      ''';
      expect(execute(source), equals({'one': 1, 'two': 2}));
    });

    test('entries', () {
      const source = '''
     main() {
        Map<int, String> map = {1: 'one', 2: 'two'};
        return map.entries.map((e) => [e.key, e.value]).toList();
      }
      ''';
      final result = execute(source) as List;
      result.sort((a, b) => (a[0] as int).compareTo(b[0] as int));
      expect(
          result,
          equals([
            [1, 'one'],
            [2, 'two']
          ]));
    });

    test('cast', () {
      const source = '''
     main() {
        Map<dynamic, dynamic> map = {1: 'one', 2: 'two'};
        Map<int, String> castedMap = map.cast<int, String>();
        return castedMap;
      }
      ''';
      expect(execute(source), equals({1: 'one', 2: 'two'}));
    });

    test('forEach', () {
      final source = '''
     main() {
        Map<int, String> map = {1: 'one', 2: 'two'};
        var result = '';
        var sortedKeys = map.keys.toList()..sort();
        sortedKeys.forEach((key) {
           result += '\$key:\${map[key]};';
        });
        return result;
      }
      ''';
      expect(execute(source), equals('1:one;2:two;'));
    });

    test('from', () {
      const source = '''
     main() {
        Map<int, String> original = {1: 'one', 2: 'two'};
        Map<int, String> copy = Map.from(original);
        copy[3] = 'three';
        return [original, copy];
      }
      ''';
      expect(
          execute(source),
          equals([
            {1: 'one', 2: 'two'},
            {1: 'one', 2: 'two', 3: 'three'}
          ]));
    });

    test('fromEntries', () {
      const source = '''
     main() {
        List<MapEntry<int, String>> entries = [MapEntry(1, 'one'), MapEntry(2, 'two')];
        Map<int, String> map = Map.fromEntries(entries);
        return map;
      }
      ''';
      expect(execute(source), equals({1: 'one', 2: 'two'}));
    });

    test('fromIterable', () {
      const source = '''
     main() {
        List<int> numbers = [1, 2, 3];
        Map<int, String> map = Map.fromIterable(numbers, key: (item) => item, value: (item) => 'Value \$item');
        return map;
      }
      ''';
      expect(
          execute(source), equals({1: 'Value 1', 2: 'Value 2', 3: 'Value 3'}));
    });

    test('fromIterables', () {
      const source = '''
     main() {
        List<int> keys = [1, 2, 3];
        List<String> values = ['one', 'two', 'three'];
        Map<int, String> map = Map.fromIterables(keys, values);
        return map;
      }
      ''';
      expect(execute(source), equals({1: 'one', 2: 'two', 3: 'three'}));
    });

    test('identity', () {
      const source = '''
     main() {
        Map<int, String> map = Map.identity();
        map[1] = 'one';
        return map;
      }
      ''';
      expect(execute(source), equals({1: 'one'}));
    });

    test('unmodifiable', () {
      const source = '''
     main() {
        Map<int, String> original = {1: 'one', 2: 'two'};
        Map<int, String> unmodifiableMap = Map.unmodifiable(original);
        return unmodifiableMap;
      }
      ''';
      expect(execute(source), equals({1: 'one', 2: 'two'}));
    });
  });
}
