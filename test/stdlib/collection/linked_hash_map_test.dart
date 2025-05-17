import 'package:test/test.dart';
import 'package:d4rt/d4rt.dart';

void main() {
  final d4rt = D4rt();

  group('LinkedHashMap Tests', () {
    test('LinkedHashMap() constructor and basic properties', () {
      final result = d4rt.execute(
        source: '''
          import 'dart:collection';
          main() {
            final map = LinkedHashMap();
            return [map.length, map.isEmpty, map.isNotEmpty, map.keys.toList(), map.values.toList()];
          }
        ''',
      ) as List;
      expect(result[0], 0);
      expect(result[1], true);
      expect(result[2], false);
      expect(result[3], []);
      expect(result[4], []);
    });

    test('LinkedHashMap.from() constructor and insertion order', () {
      final result = d4rt.execute(
        source: '''
          import 'dart:collection';
          main() {
            final sourceMap = {'b': 2, 'a': 1, 'c': 3}; // Ordre non garanti ici
            final map = LinkedHashMap.from(sourceMap);
            // L'ordre dans LinkedHashMap.from dépend de l'itération sur sourceMap.
            // Pour un test déterministe de l'ordre d'insertion, il vaut mieux ajouter les éléments un par un.
            // Ici, on teste surtout la copie des éléments.
            map['d'] = 4; // Ajout pour vérifier l'ordre ultérieur
            return [map.length, map.containsKey('a'), map['a'], map.keys.toList()];
          }
        ''',
      ) as List;
      expect(result[0], 4);
      expect(result[1], true);
      expect(result[2], 1);
      expect((result[3] as List).last, 'd');
    });

    test('LinkedHashMap.of() constructor', () {
      final result = d4rt.execute(
        source: '''
          import 'dart:collection';
          main() {
            final sourceMap = LinkedHashMap.of({'x': 10, 'y': 20});
            sourceMap['z'] = 30;
            final map = LinkedHashMap.of(sourceMap);
            map['a'] = 40;
            return [map.length, map.keys.toList(), map.values.toList()];
          }
        ''',
      ) as List;
      expect(result[0], 4);
      expect(result[1], orderedEquals(['x', 'y', 'z', 'a']));
      expect(result[2], orderedEquals([10, 20, 30, 40]));
    });

    test('LinkedHashMap.identity() constructor', () {
      final result = d4rt.execute(
        source: '''
          import 'dart:collection';
          main() {
            final map = LinkedHashMap.identity();
            map[1] = 'a';
            map[2] = 'b';
            return map.length;
          }
        ''',
      );
      expect(result, 2);
    });

    test('[] and []= operators, insertion order preserved', () {
      final result = d4rt.execute(
        source: '''
          import 'dart:collection';
          main() {
            final map = LinkedHashMap();
            map['one'] = 1;
            map['two'] = 2;
            map['three'] = 3;
            map['one'] = 11; // Update existing key
            return [map['two'], map.keys.toList(), map.values.toList(), map.length];
          }
        ''',
      ) as List;
      expect(result[0], 2);
      expect(result[1], orderedEquals(['one', 'two', 'three']));
      expect(result[2], orderedEquals([11, 2, 3]));
      expect(result[3], 3);
    });

    test('addAll(), clear(), isEmpty, isNotEmpty', () {
      final result = d4rt.execute(
        source: '''
          import 'dart:collection';
          main() {
            final map = LinkedHashMap();
            map['a'] = 1;
            map.addAll({'b': 2, 'c': 3});
            final keys1 = map.keys.toList();
            final values1 = map.values.toList();
            final l1 = map.length;
            final e1 = map.isEmpty;
            final ne1 = map.isNotEmpty;

            map.clear();
            final keys2 = map.keys.toList();
            final values2 = map.values.toList();
            final l2 = map.length;
            final e2 = map.isEmpty;
            final ne2 = map.isNotEmpty;
            return [keys1, values1, l1, e1, ne1, keys2, values2, l2, e2, ne2];
          }
        ''',
      ) as List;
      expect(result[0], orderedEquals(['a', 'b', 'c']));
      expect(result[1], orderedEquals([1, 2, 3]));
      expect(result[2], 3);
      expect(result[3], false);
      expect(result[4], true);
      expect(result[5], []);
      expect(result[6], []);
      expect(result[7], 0);
      expect(result[8], true);
      expect(result[9], false);
    });

    test('containsKey(), containsValue()', () {
      final result = d4rt.execute(
        source: '''
          import 'dart:collection';
          main() {
            final map = LinkedHashMap.of({'k1': 'v1', 'k2': 'v2'});
            return [
              map.containsKey('k1'), map.containsKey('k3'),
              map.containsValue('v2'), map.containsValue('v3')
            ];
          }
        ''',
      ) as List;
      expect(result[0], true); // containsKey k1
      expect(result[1], false); // containsKey k3
      expect(result[2], true); // containsValue v2
      expect(result[3], false); // containsValue v3
    });

    test('remove() and insertion order', () {
      final result = d4rt.execute(
        source: '''
          import 'dart:collection';
          main() {
            final map = LinkedHashMap();
            map['x'] = 10;
            map['y'] = 20;
            map['z'] = 30;
            final removedValue1 = map.remove('y');
            final keys1 = map.keys.toList();
            final removedValue2 = map.remove('non_existent');
            return [removedValue1, keys1, removedValue2, map.length];
          }
        ''',
      ) as List;
      expect(result[0], 20);
      expect(result[1], orderedEquals(['x', 'z']));
      expect(result[2], null);
      expect(result[3], 2);
    });

    test('forEach() and entries', () {
      final result = d4rt.execute(
        source: '''
          import 'dart:collection';
          main() {
            final map = LinkedHashMap.of({'one': 1, 'two': 2, 'three': 3});
            final iteratedKeys = [];
            final iteratedValues = [];
            map.forEach((key, value) {
              iteratedKeys.add(key);
              iteratedValues.add(value);
            });

            final entryKeys = [];
            final entryValues = [];
            for (final entry in map.entries) {
              entryKeys.add(entry.key);
              entryValues.add(entry.value);
            }
            return [iteratedKeys, iteratedValues, entryKeys, entryValues];
          }
        ''',
      ) as List;
      expect(result[0], orderedEquals(['one', 'two', 'three']));
      expect(result[1], orderedEquals([1, 2, 3]));
      expect(result[2], orderedEquals(['one', 'two', 'three']));
      expect(result[3], orderedEquals([1, 2, 3]));
    });

    test('putIfAbsent()', () {
      final result = d4rt.execute(
        source: '''
          import 'dart:collection';
          main() {
            final map = LinkedHashMap.of({'a': 1});
            final v1 = map.putIfAbsent('a', () => 10); // Key exists, returns existing value
            final v2 = map.putIfAbsent('b', () => 20); // Key doesn't exist, adds and returns new value
            return [v1, v2, map['a'], map['b'], map.keys.toList()];
          }
        ''',
      ) as List;
      expect(result[0], 1); // v1
      expect(result[1], 20); // v2
      expect(result[2], 1); // map['a']
      expect(result[3], 20); // map['b']
      expect(result[4], orderedEquals(['a', 'b'])); // keys order
    });
  });
}
