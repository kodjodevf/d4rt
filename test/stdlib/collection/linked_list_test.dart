import 'package:test/test.dart';
import 'package:d4rt/d4rt.dart';

void main() {
  final d4rt = D4rt();
  const String testLibPath = 'd4rt-mem:/linked_list_test.dart';

  dynamic executeTestScript(String scriptBody) {
    final fullScript = '''
      import 'dart:collection';

      main() {
        $scriptBody
      }
    ''';
    return d4rt.execute(
      library: testLibPath,
      name: 'main',
      sources: {testLibPath: fullScript},
    );
  }

  group('LinkedList and LinkedListEntry Tests', () {
    test('Create LinkedList, add entries, check properties', () {
      final result = executeTestScript('''
        var list = LinkedList();
        var entry1 = LinkedListEntry('apple');
        var entry2 = LinkedListEntry(123);
        
        list.add(entry1);
        list.add(entry2);
        
        return {
          'length': list.length,
          'isEmpty': list.isEmpty,
          'isNotEmpty': list.isNotEmpty,
          'firstValue': list.first.value,
          'lastValue': list.last.value,
          'entry1InList': entry1.list != null,
          'entry2NextIsNull': entry2.next == null,
          'entry1PrevIsNull': entry1.previous == null,
          'entry1NextIsEntry2': entry1.next == entry2,
          'entry2PrevIsEntry1': entry2.previous == entry1,
        };
      ''');
      expect(result['length'], 2);
      expect(result['isEmpty'], false);
      expect(result['isNotEmpty'], true);
      expect(result['firstValue'], 'apple');
      expect(result['lastValue'], 123);
      expect(result['entry1InList'], true);
      expect(result['entry2NextIsNull'], true);
      expect(result['entry1PrevIsNull'], true);
      expect(result['entry1NextIsEntry2'], true);
      expect(result['entry2PrevIsEntry1'], true);
    });

    test('LinkedListEntry unlink', () {
      final result = executeTestScript('''
        var list = LinkedList();
        var entry1 = LinkedListEntry('a');
        var entry2 = LinkedListEntry('b');
        list.add(entry1);
        list.add(entry2);
        
        entry1.unlink(); // Unlink first
        
        return {
          'listLength': list.length,
          'firstValue': list.first.value,
          'entry1ListIsNull': entry1.list == null,
          'entry1PrevIsNull': entry1.previous == null,
          'entry1NextIsNull': entry1.next == null,
        };
      ''');
      expect(result['listLength'], 1);
      expect(result['firstValue'], 'b');
      expect(result['entry1ListIsNull'], true);
      expect(result['entry1PrevIsNull'], true);
      expect(result['entry1NextIsNull'], true);
    });

    test('LinkedList remove entry', () {
      final result = executeTestScript('''
        var list = LinkedList();
        var entry1 = LinkedListEntry(1);
        var entry2 = LinkedListEntry(2);
        var entry3 = LinkedListEntry(3);
        list.add(entry1);
        list.add(entry2);
        list.add(entry3);
        
        var removed = list.remove(entry2); // Remove middle
        
        return {
          'removedResult': removed,
          'listLength': list.length,
          'firstValue': list.first.value,
          'lastValue': list.last.value,
          'entry2ListIsNull': entry2.list == null,
          'entry1NextIsEntry3': entry1.next == entry3,
          'entry3PrevIsEntry1': entry3.previous == entry1,
        };
      ''');
      expect(result['removedResult'], true);
      expect(result['listLength'], 2);
      expect(result['firstValue'], 1);
      expect(result['lastValue'], 3);
      expect(result['entry2ListIsNull'], true);
      expect(result['entry1NextIsEntry3'], true);
      expect(result['entry3PrevIsEntry1'], true);
    });

    test('LinkedList removeFirst', () {
      final result = executeTestScript('''
        var list = LinkedList();
        var entry1 = LinkedListEntry('x');
        var entry2 = LinkedListEntry('y');
        list.add(entry1);
        list.add(entry2);
        
        var removedEntry = list.removeFirst();
        
        return {
          'removedValue': removedEntry.value,
          'removedEntryIsEntry1': removedEntry == entry1,
          'listLength': list.length,
          'firstValue': list.first.value,
          'entry1ListIsNull': entry1.list == null,
        };
      ''');
      expect(result['removedValue'], 'x');
      expect(result['removedEntryIsEntry1'], true);
      expect(result['listLength'], 1);
      expect(result['firstValue'], 'y');
      expect(result['entry1ListIsNull'], true);
    });

    test('LinkedList clear', () {
      final result = executeTestScript('''
        var list = LinkedList();
        var entry1 = LinkedListEntry(100);
        list.add(entry1);
        list.clear();
        
        return {
          'listLength': list.length,
          'isEmpty': list.isEmpty,
          'entry1ListIsNull': entry1.list == null,
        };
      ''');
      expect(result['listLength'], 0);
      expect(result['isEmpty'], true);
      expect(result['entry1ListIsNull'], true);
    });

    test('Accessing first/last on empty list throws error', () {
      expect(
        () => executeTestScript('var list = LinkedList(); return list.first;'),
        throwsA(isA<RuntimeError>()),
      );
      expect(
        () => executeTestScript('var list = LinkedList(); return list.last;'),
        throwsA(isA<RuntimeError>()),
      );
    });

    test('removeFirst on empty list throws error', () {
      expect(
        () => executeTestScript('var list = LinkedList(); list.removeFirst();'),
        throwsA(isA<RuntimeError>()),
      );
    });

    test('Unlink entry not in a list throws error', () {
      // Unlinking an entry that was never added
      expect(
        () => executeTestScript(
            'var entry = LinkedListEntry(0); entry.unlink();'),
        throwsA(isA<RuntimeError>()),
      );

      // Unlinking an entry that was already unlinked
      expect(
        () => executeTestScript('''
          var list = LinkedList();
          var entry = LinkedListEntry(0);
          list.add(entry);
          entry.unlink(); // First unlink
          entry.unlink(); // Second unlink, should throw
        '''),
        throwsA(isA<RuntimeError>()),
      );
    });
  });
}
