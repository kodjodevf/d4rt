import 'package:test/test.dart';
import 'package:d4rt/d4rt.dart';

void main() {
  final d4rt = D4rt();

  group('HashSet Tests', () {
    test('HashSet() constructor and basic properties', () {
      final result = d4rt.execute(
        source: '''
          import 'dart:collection';
          main() {
            final set = HashSet();
            return [set.length, set.isEmpty, set.isNotEmpty];
          }
        ''',
      ) as List;
      expect(result[0], 0);
      expect(result[1], true);
      expect(result[2], false);
    });

    test('HashSet() constructor, add, length, contains', () {
      final result = d4rt.execute(
        source: '''
          import 'dart:collection';
          main() {
            final set = HashSet();
            final r1 = set.add(10);
            final r2 = set.add(20);
            final r3 = set.add(10); // try adding duplicate
            return [set.length, set.contains(10), set.contains(30), r1, r2, r3, set.toList()];
          }
        ''',
      ) as List;
      expect(result[0], 2, reason: "Length after adds");
      expect(result[1], true, reason: "Contains 10");
      expect(result[2], false, reason: "Does not contain 30");
      expect(result[3], true, reason: "Add 10 should return true");
      expect(result[4], true, reason: "Add 20 should return true");
      expect(result[5], false, reason: "Add duplicate 10 should return false");
      expect(result[6], unorderedEquals([10, 20]), reason: "toList check");
    });

    test('HashSet.from() constructor', () {
      final result = d4rt.execute(
        source: '''
          import 'dart:collection';
          main() {
            final sourceList = [1, 2, 2, 3, 4, 4, 4];
            final set = HashSet.from(sourceList);
            return [set.length, set.contains(1), set.contains(5), set.toList()];
          }
        ''',
      ) as List;
      expect(result[0], 4, reason: "Length from list with duplicates");
      expect(result[1], true, reason: "Contains 1 from list");
      expect(result[2], false, reason: "Does not contain 5");
      expect(result[3], unorderedEquals([1, 2, 3, 4]),
          reason: "toList from list with duplicates");
    });

    test('clear() and isEmpty', () {
      final result = d4rt.execute(
        source: '''
          import 'dart:collection';
          main() {
            final set = HashSet.from([1, 2, 3]);
            final initialLength = set.length;
            set.clear();
            return [initialLength, set.length, set.isEmpty];
          }
        ''',
      ) as List;
      expect(result[0], 3, reason: "Initial length");
      expect(result[1], 0, reason: "Length after clear");
      expect(result[2], true, reason: "isEmpty after clear");
    });

    test('addAll(), remove(), removeAll(), retainAll(), containsAll()', () {
      final result = d4rt.execute(
        source: '''
          import 'dart:collection';
          main() {
            final set = HashSet<int>.from([1, 2, 3]);

            set.addAll([3, 4, 5]); // set is now {1, 2, 3, 4, 5}
            final lengthAfterAddAll = set.length;
            final contains3 = set.contains(3);

            final removed1 = set.remove(1); // set is {2, 3, 4, 5}
            final removed6 = set.remove(6); // non-existent
            final lengthAfterRemove = set.length;

            set.removeAll([2, 4, 7]); // set is {3, 5}
            final lengthAfterRemoveAll = set.length;
            final contains2 = set.contains(2);

            final set2 = HashSet<int>.from([3, 5, 8, 9]);
            set2.retainAll([0, 3, 9, 10]); // set2 is {3, 9}
            final lengthAfterRetainAll = set2.length;
            final contains5_set2 = set2.contains(5);

            final containsAll_3_5 = set.containsAll([3,5]);
            final containsAll_3_6 = set.containsAll([3,6]);

            return [
              lengthAfterAddAll, contains3, 
              removed1, removed6, lengthAfterRemove, 
              lengthAfterRemoveAll, contains2,
              lengthAfterRetainAll, contains5_set2,
              containsAll_3_5, containsAll_3_6,
              set.toList(), // Expected {3, 5}
              set2.toList() // Expected {3, 9}
            ];
          }
        ''',
      ) as List;

      expect(result[0], 5, reason: "lengthAfterAddAll");
      expect(result[1], true, reason: "contains3 after addAll");
      expect(result[2], true, reason: "removed1");
      expect(result[3], false, reason: "removed6");
      expect(result[4], 4, reason: "lengthAfterRemove");
      expect(result[5], 2, reason: "lengthAfterRemoveAll");
      expect(result[6], false, reason: "contains2 after removeAll");
      expect(result[7], 2, reason: "lengthAfterRetainAll for set2");
      expect(result[8], false, reason: "contains5_set2 after retainAll");
      expect(result[9], true, reason: "containsAll {3,5} in {3,5}");
      expect(result[10], false, reason: "containsAll {3,6} in {3,5}");
      expect(result[11], unorderedEquals([3, 5]), reason: "set toList");
      expect(result[12], unorderedEquals([3, 9]), reason: "set2 toList");
    });

    test('first, last, single getters', () {
      final result = d4rt.execute(
        source: '''
          import 'dart:collection';
          main() {
            final set1 = HashSet.from([10]);
            final first1 = set1.first;
            final last1 = set1.last;
            final single1 = set1.single;

            final set2 = HashSet.from([10, 20, 5]); // Order might vary
            // For first/last, we rely on the fact that for small sets, order of insertion is often preserved
            // but this is not guaranteed by HashSet contract. These tests might be flaky.
            // A more robust test would be to check if first/last are *one of* the elements.
            var first2, last2;
            try { first2 = set2.first; } catch (e) { first2 = e.toString(); }
            try { last2 = set2.last; } catch (e) { last2 = e.toString(); }
            
            var single2_error = false;
            try { set2.single; } catch (e) { single2_error = true; }

            final set_empty = HashSet();
            var first_empty_error = false;
            try { set_empty.first; } catch (e) { first_empty_error = true; }
            var last_empty_error = false;
            try { set_empty.last; } catch (e) { last_empty_error = true; }
            var single_empty_error = false;
            try { set_empty.single; } catch (e) { single_empty_error = true; }

            return [
              first1, last1, single1,
              [10, 20, 5].contains(first2), [10, 20, 5].contains(last2), // Check if they are valid elements
              single2_error,
              first_empty_error, last_empty_error, single_empty_error,
            ];
          }
        ''',
      ) as List;
      expect(result[0], 10, reason: "first1");
      expect(result[1], 10, reason: "last1");
      expect(result[2], 10, reason: "single1");
      expect(result[3], true, reason: "first2 is one of the elements");
      expect(result[4], true, reason: "last2 is one of the elements");
      expect(result[5], true,
          reason: "single2_error (set has multiple elements)");
      expect(result[6], true, reason: "first_empty_error");
      expect(result[7], true, reason: "last_empty_error");
      expect(result[8], true, reason: "single_empty_error");
    });

    test('iterator basics and forEach', () {
      final result = d4rt.execute(
        source: '''
          import 'dart:collection';
          main() {
            final set = HashSet.from([1, 'hello', true]);
            final iter = set.iterator;
            final iteratedElements = [];
            while (iter.moveNext()) {
              iteratedElements.add(iter.current);
            }

            final forEachElements = [];
            set.forEach((e) {
              forEachElements.add(e);
            });

            final emptySet = HashSet();
            final emptyIter = emptySet.iterator;
            final emptyIterHasNext = emptyIter.moveNext();

            return [iteratedElements, forEachElements, emptyIterHasNext];
          }
        ''',
      ) as List;

      // Since HashSet is unordered, we check for unordered equality
      expect(result[0], unorderedEquals([1, 'hello', true]),
          reason: "iteratedElements");
      expect(result[1], unorderedEquals([1, 'hello', true]),
          reason: "forEachElements");
      expect(result[2], false, reason: "emptyIterHasNext");
    });

    test('toList() and toSet()', () {
      final result = d4rt.execute(
        source: '''
          import 'dart:collection';
          main() {
            final set = HashSet.from([10, 20, 5]);
            final list = set.toList(); // Default growable: true
            list.add(30);

            final listNonGrowable = set.toList(growable: false);
            var nonGrowableError = false;
            try {
              listNonGrowable.add(40);
            } catch (e) {
              nonGrowableError = true;
            }

            final newSet = set.toSet();
            final addedToNewSet = newSet.add(15); // should be true as it's a new set
            
            return [list, nonGrowableError, newSet.contains(15), newSet.length, set.length ];
          }
        ''',
      ) as List;

      expect(result[0], unorderedEquals([10, 20, 5, 30]),
          reason: "list (growable)");
      expect(result[1], true,
          reason: "nonGrowableError when adding to non-growable list");
      expect(result[2], true, reason: "newSet contains 15");
      expect(result[3], 4, reason: "newSet length");
      expect(result[4], 3, reason: "original set length unchanged");
    });
  });
}
