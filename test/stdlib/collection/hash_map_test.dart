import 'package:test/test.dart';
import 'package:d4rt/d4rt.dart';

void main() {
  group('dart:collection - HashMap Tests', () {
    D4rt d4rtInstance = D4rt();

    setUp(() {
      d4rtInstance = D4rt();
    });

    dynamic execute(String mainFunctionBody, {Object? args}) {
      final source = '''
        import 'dart:collection';

        main() {
          $mainFunctionBody
        }
      ''';
      return d4rtInstance.execute(
        library: 'd4rt-mem:/main_hash_map_test.dart',
        name: 'main',
        args: args,
        sources: {'d4rt-mem:/main_hash_map_test.dart': source},
      );
    }

    test('HashMap() constructor and basic properties', () {
      final result = execute('''
        var map = HashMap();
        return [map.length, map.isEmpty, map.isNotEmpty];
      ''');
      expect(result, equals([0, true, false]));
    });

    test('HashMap.from() constructor', () {
      final result = execute('''
        var map = HashMap.from({'a': 1, 'b': 2});
        return [map.length, map['a'], map['b']];
      ''');
      expect(result, equals([2, 1, 2]));
    });

    test('HashMap.of() constructor', () {
      final result = execute('''
        var map = HashMap.of({'x': 10, 'y': 20});
        return [map.length, map['x'], map['y']];
      ''');
      expect(result, equals([2, 10, 20]));
    });

    test('operator []= and []', () {
      final result = execute('''
        var map = HashMap();
        map['key1'] = 'value1';
        map[2] = 'value2'; 
        return [map['key1'], map[2], map['nonExistentKey']];
      ''');
      expect(result, equals(['value1', 'value2', null]));
    });

    test('addAll() method', () {
      final result = execute('''
        var map = HashMap();
        map.addAll({'c': 3, 'd': 4});
        map.addAll({'d': 40, 'e': 5}); // Test override and new key
        return [map.length, map['c'], map['d'], map['e']];
      ''');
      expect(result, equals([3, 3, 40, 5]));
    });

    test('clear() method', () {
      final result = execute('''
        var map = HashMap.from({'a': 1});
        map.clear();
        return map.length;
      ''');
      expect(result, equals(0));
    });

    test('containsKey() and containsValue()', () {
      final result = execute('''
        var map = HashMap.from({'a': 10, 'b': 20});
        return [
          map.containsKey('a'), map.containsKey('z'),
          map.containsValue(20), map.containsValue(99)
        ];
      ''');
      expect(result, equals([true, false, true, false]));
    });

    test('remove() method', () {
      final result = execute('''
        var map = HashMap.from({'a': 1, 'b': 2, 'c': 3});
        var removedB = map.remove('b');
        var removedZ = map.remove('z'); // Non-existent key
        return [map.length, map.containsKey('b'), removedB, removedZ];
      ''');
      expect(result, equals([2, false, 2, null]));
    });

    test('forEach() method', () {
      final result = execute('''
        var map = HashMap.from({'a': 1, 'b': 2});
        var log = <String>[];
        map.forEach((key, value) {
          log.add('\$key:\$value');
        });
        return log;
      ''');
      expect(
          result,
          TypeMatcher<List>()
              .having((l) => l, 'elements', unorderedEquals(['a:1', 'b:2'])));
    });

    test('putIfAbsent() method', () {
      final result = execute('''
        var map = HashMap.from({'a': 10});
        var r1 = map.putIfAbsent('a', () => 99); // Should return existing value
        var r2 = map.putIfAbsent('b', () => 20); // Should add and return new value
        return [map['a'], map['b'], r1, r2];
      ''');
      expect(result, equals([10, 20, 10, 20]));
    });

    test('keys and values getters', () {
      final result = execute('''
        var map = HashMap.from({'one': 1, 'two': 2, 'three': 3});
        var k = map.keys.toList(); // Convert to list for stable order in test
        var v = map.values.toList(); // Convert to list for stable order in test
        // Sorting because HashMap doesn't guarantee order
        k.sort(); 
        v.sort();
        return [k, v];
      ''');

      expect(result[0], orderedEquals(['one', 'three', 'two']));
      expect(result[1], orderedEquals([1, 2, 3]));
    });
  });
}
