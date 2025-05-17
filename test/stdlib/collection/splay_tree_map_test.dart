import 'package:test/test.dart';
import 'package:d4rt/d4rt.dart';

void main() {
  final d4rt = D4rt();

  group('SplayTreeMap Tests', () {
    test('SplayTreeMap() constructor and basic properties, natural ordering',
        () {
      final result = d4rt.execute(
        source: '''
          import 'dart:collection';
          main() {
            final map = SplayTreeMap();
            map[3] = 'c';
            map[1] = 'a';
            map[2] = 'b';
            return [map.length, map.isEmpty, map.isNotEmpty, map.keys.toList(), map.values.toList(), map.firstKey(), map.lastKey()];
          }
        ''',
      ) as List;
      expect(result[0], 3, reason: "length");
      expect(result[1], false, reason: "isEmpty");
      expect(result[2], true, reason: "isNotEmpty");
      expect(result[3], orderedEquals([1, 2, 3]), reason: "keys order");
      expect(result[4], orderedEquals(['a', 'b', 'c']), reason: "values order");
      expect(result[5], 1, reason: "firstKey");
      expect(result[6], 3, reason: "lastKey");
    });

    test('SplayTreeMap() with custom compare function (reverse order)', () {
      final result = d4rt.execute(
        source: '''
          import 'dart:collection';
          main() {
            final map = SplayTreeMap((k1, k2) => (k2 as int).compareTo(k1 as int));
            map[3] = 'c';
            map[1] = 'a';
            map[2] = 'b';
            return [map.keys.toList(), map.values.toList(), map.firstKey(), map.lastKey()];
          }
        ''',
      ) as List;
      expect(result[0], orderedEquals([3, 2, 1]), reason: "keys reverse order");
      expect(result[1], orderedEquals(['c', 'b', 'a']),
          reason: "values reverse order");
      expect(result[2], 3, reason: "firstKey (reverse)");
      expect(result[3], 1, reason: "lastKey (reverse)");
    });

    test('SplayTreeMap.from() with natural ordering', () {
      final result = d4rt.execute(
        source: '''
          import 'dart:collection';
          main() {
            final sourceMap = {5: 'e', 1: 'a', 3: 'c'};
            final map = SplayTreeMap.from(sourceMap);
            map[2] = 'b'; // Add another element
            return [map.keys.toList(), map.values.toList()];
          }
        ''',
      ) as List;
      expect(result[0], orderedEquals([1, 2, 3, 5]), reason: "keys from map");
      expect(result[1], orderedEquals(['a', 'b', 'c', 'e']),
          reason: "values from map");
    });

    test('SplayTreeMap.from() with custom compare function', () {
      final result = d4rt.execute(
        source: '''
          import 'dart:collection';
          main() {
            final sourceMap = {5: 'e', 1: 'a', 3: 'c'};
            // Custom sort: by value length, then by key descending for ties (hypothetical)
            final map = SplayTreeMap.from(sourceMap, (k1, k2) => (k2 as int).compareTo(k1 as int));
            map[2] = 'b';
            return [map.keys.toList(), map.values.toList()];
          }
        ''',
      ) as List;
      expect(result[0], orderedEquals([5, 3, 2, 1]),
          reason: "keys custom from map");
      expect(result[1], orderedEquals(['e', 'c', 'b', 'a']),
          reason: "values custom from map");
    });

    test('SplayTreeMap.of() with natural ordering', () {
      final result = d4rt.execute(
        source: '''
          import 'dart:collection';
          main() {
            final sourceMap = {10: "ten", 2: "two"};
            final map = SplayTreeMap.of(sourceMap);
            map[5] = "five";
            return map.keys.toList();
          }
        ''',
      ) as List;
      expect(result, orderedEquals([2, 5, 10]));
    });

    test('[] and []= operators, sorted order maintained', () {
      final result = d4rt.execute(
        source: '''
          import 'dart:collection';
          main() {
            final map = SplayTreeMap();
            map['gamma'] = 3;
            map['alpha'] = 1;
            map['beta'] = 2;
            map['alpha'] = 11; // Update existing key
            return [map['beta'], map.keys.toList(), map.values.toList(), map.length];
          }
        ''',
      ) as List;
      expect(result[0], 2, reason: "map['beta']");
      expect(result[1], orderedEquals(['alpha', 'beta', 'gamma']),
          reason: "keys after ops");
      expect(result[2], orderedEquals([11, 2, 3]), reason: "values after ops");
      expect(result[3], 3, reason: "length after ops");
    });

    test('addAll(), clear(), isEmpty, isNotEmpty', () {
      final result = d4rt.execute(
        source: '''
          import 'dart:collection';
          main() {
            final map = SplayTreeMap();
            map[10] = 'x';
            map.addAll({5: 'y', 15: 'z'}); // Added out of order
            final keys1 = map.keys.toList();
            final values1 = map.values.toList();
            final l1 = map.length;
            final e1 = map.isEmpty;
            final ne1 = map.isNotEmpty;

            map.clear();
            final keys2 = map.keys.toList();
            final l2 = map.length;
            final e2 = map.isEmpty;
            return [keys1, values1, l1, e1, ne1, keys2, l2, e2];
          }
        ''',
      ) as List;
      expect(result[0], orderedEquals([5, 10, 15]),
          reason: "keys after addAll");
      expect(result[1], orderedEquals(['y', 'x', 'z']),
          reason: "values after addAll");
      expect(result[2], 3, reason: "length l1");
      expect(result[3], false, reason: "isEmpty e1");
      expect(result[4], true, reason: "isNotEmpty ne1");
      expect(result[5], [], reason: "keys after clear");
      expect(result[6], 0, reason: "length l2");
      expect(result[7], true, reason: "isEmpty e2");
    });

    test('containsKey(), containsValue()', () {
      final result = d4rt.execute(
        source: '''
          import 'dart:collection';
          main() {
            final map = SplayTreeMap.of({'k1': 'v1', 'k2': 'v2'});
            return [
              map.containsKey('k1'), map.containsKey('k3'),
              map.containsValue('v2'), map.containsValue('v3')
            ];
          }
        ''',
      ) as List;
      expect(result[0], true, reason: "containsKey k1");
      expect(result[1], false, reason: "containsKey k3");
      expect(result[2], true, reason: "containsValue v2");
      expect(result[3], false, reason: "containsValue v3");
    });

    test('remove() and sorted order', () {
      final result = d4rt.execute(
        source: '''
          import 'dart:collection';
          main() {
            final map = SplayTreeMap();
            map['x'] = 10;
            map['a'] = 1;
            map['m'] = 5;
            final removedValue1 = map.remove('m');
            final keys1 = map.keys.toList();
            final removedValue2 = map.remove('non_existent');
            return [removedValue1, keys1, removedValue2, map.length];
          }
        ''',
      ) as List;
      expect(result[0], 5, reason: "removedValue1");
      expect(result[1], orderedEquals(['a', 'x']), reason: "keys after remove");
      expect(result[2], null, reason: "removedValue2");
      expect(result[3], 2, reason: "length after remove");
    });

    test('forEach() and entries are sorted', () {
      final result = d4rt.execute(
        source: '''
          import 'dart:collection';
          main() {
            final map = SplayTreeMap.of({'c': 103, 'a': 101, 'b': 102});
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
      expect(result[0], orderedEquals(['a', 'b', 'c']), reason: "forEach keys");
      expect(result[1], orderedEquals([101, 102, 103]),
          reason: "forEach values");
      expect(result[2], orderedEquals(['a', 'b', 'c']), reason: "entries keys");
      expect(result[3], orderedEquals([101, 102, 103]),
          reason: "entries values");
    });

    test('putIfAbsent() and sorted order', () {
      final result = d4rt.execute(
        source: '''
          import 'dart:collection';
          main() {
            final map = SplayTreeMap.of({'z': 26, 'm': 13});
            final v1 = map.putIfAbsent('m', () => 99); // Key exists
            final v2 = map.putIfAbsent('a', () => 1);  // Key doesn't exist
            final v3 = map.putIfAbsent('n', () => 14); // Key doesn't exist
            return [v1, v2, v3, map['m'], map['a'], map['n'], map.keys.toList()];
          }
        ''',
      ) as List;
      expect(result[0], 13, reason: "v1 putIfAbsent existing");
      expect(result[1], 1, reason: "v2 putIfAbsent new");
      expect(result[2], 14, reason: "v3 putIfAbsent new");
      expect(result[3], 13, reason: "map['m']");
      expect(result[4], 1, reason: "map['a']");
      expect(result[5], 14, reason: "map['n']");
      expect(result[6], orderedEquals(['a', 'm', 'n', 'z']),
          reason: "keys order after putIfAbsent");
    });

    test('firstKey() / lastKey() on empty map throws error', () {
      expect(() => d4rt.execute(source: '''
          import 'dart:collection';
          main() { SplayTreeMap().firstKey(); }
        '''), throwsA(isA<RuntimeError>()), reason: "firstKey on empty map");
      expect(() => d4rt.execute(source: '''
          import 'dart:collection';
          main() { SplayTreeMap().lastKey(); }
        '''), throwsA(isA<RuntimeError>()), reason: "lastKey on empty map");
    });
  });
}
