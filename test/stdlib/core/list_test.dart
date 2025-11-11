import 'package:test/test.dart';

import '../../interpreter_test.dart';

void main() {
  group('List stdlib tests', () {
    test('List literal and basic properties', () {
      final result = execute(r'''
        main() {
          List<int> l1 = [1, 2, 3];
          List<dynamic> l2 = [];
          return [
            l1.length, l1.isEmpty, l1.isNotEmpty,
            l2.length, l2.isEmpty, l2.isNotEmpty
          ];
        }
      ''');
      expect(result, equals([3, false, true, 0, true, false]));
    });

    test('List index access [] and assignment []=', () {
      final result = execute(r'''
        main() {
          List<String> l = ['a', 'b', 'c'];
          var first = l[0];
          l[1] = 'B';
          return [first, l[1], l];
        }
      ''');
      expect(
          result,
          equals([
            'a',
            'B',
            ['a', 'B', 'c']
          ]));
    });

    test('List add and addAll', () {
      final result = execute(r'''
        main() {
          List<int> l = [1];
          l.add(2);
          l.addAll([3, 4]);
          return l;
        }
      ''');
      expect(result, equals([1, 2, 3, 4]));
    });

    test('List remove, removeAt, clear', () {
      final result = execute(r'''
        main() {
          List<String> l = ['x', 'y', 'z', 'y'];
          bool removedY = l.remove('y'); // Removes first 'y'
          var removedAt1 = l.removeAt(1); // Removes 'z'
          l.clear();
          return [removedY, removedAt1, l.length, l];
        }
      ''');
      expect(result, equals([true, 'z', 0, []]));
    });

    test('List contains, indexOf, lastIndexOf', () {
      final result = execute(r'''
        main() {
          List<int> l = [10, 20, 30, 20, 40];
          return [
            l.contains(20),
            l.contains(50),
            l.indexOf(20),       // First occurrence
            l.lastIndexOf(20),   // Last occurrence
            l.indexOf(50)        // Not found
          ];
        }
      ''');
      expect(result, equals([true, false, 1, 3, -1]));
    });

    test('List join', () {
      final result = execute(r'''
        main() {
          List<String> l = ['h', 'e', 'l', 'l', 'o'];
          return l.join('-');
        }
      ''');
      expect(result, equals('h-e-l-l-o'));
    });

    test('List sublist', () {
      final result = execute(r'''
        main() {
          List<int> l = [0, 1, 2, 3, 4, 5];
          return [l.sublist(1, 4), l.sublist(3)];
        }
      ''');
      expect(
          result,
          equals([
            [1, 2, 3],
            [3, 4, 5]
          ]));
    });

    group('List methods', () {
      test('insert', () {
        const source = '''
       main() {
        List<int> numbers = [1, 2, 4];
        numbers.insert(2, 3);
        return numbers;
      }
      ''';
        expect(execute(source), equals([1, 2, 3, 4]));
      });

      test('insertAll', () {
        const source = '''
       main() {
        List<int> numbers = [1, 4];
        numbers.insertAll(1, [2, 3]);
        return numbers;
      }
      ''';
        expect(execute(source), equals([1, 2, 3, 4]));
      });

      test('setAll', () {
        const source = '''
       main() {
        List<int> numbers = [1, 2, 3, 4];
        numbers.setAll(1, [5, 6]);
        return numbers;
      }
      ''';
        expect(execute(source), equals([1, 5, 6, 4]));
      });

      test('fillRange', () {
        const source = '''
       main() {
        List<int> numbers = [1, 2, 3, 4];
        numbers.fillRange(1, 3, 0);
        return numbers;
      }
      ''';
        expect(execute(source), equals([1, 0, 0, 4]));
      });

      test('replaceRange', () {
        const source = '''
       main() {
        List<int> numbers = [1, 2, 3, 4];
        numbers.replaceRange(1, 3, [5, 6]);
        return numbers;
      }
      ''';
        expect(execute(source), equals([1, 5, 6, 4]));
      });

      test('removeRange', () {
        const source = '''
       main() {
        List<int> numbers = [1, 2, 3, 4];
        numbers.removeRange(1, 3);
        return numbers;
      }
      ''';
        expect(execute(source), equals([1, 4]));
      });

      test('retainWhere', () {
        const source = '''
       main() {
        List<int> numbers = [1, 2, 3, 4];
        numbers.retainWhere((n) => n % 2 == 0);
        return numbers;
      }
      ''';
        expect(execute(source), equals([2, 4]));
      });

      test('removeWhere', () {
        const source = '''
       main() {
        List<int> numbers = [1, 2, 3, 4];
        numbers.removeWhere((n) => n % 2 == 0);
        return numbers;
      }
      ''';
        expect(execute(source), equals([1, 3]));
      });

      test('sort', () {
        const source = '''
       main() {
        List<int> numbers = [4, 2, 3, 1];
        numbers.sort();
        return numbers;
      }
      ''';
        expect(execute(source), equals([1, 2, 3, 4]));
      });

      test('shuffle', () {
        const source = '''
       main() {
        List<int> numbers = [1, 2, 3, 4];
        numbers.shuffle();
        return numbers; // Cannot check order, but check length and elements
      }
      ''';
        final result = execute(source) as List;
        expect(result, isA<List>());
        expect(result.length, equals(4));
        expect(result, containsAll([1, 2, 3, 4]));
      });

      test('reversed', () {
        const source = '''
       main() {
        List<int> numbers = [1, 2, 3, 4];
        return numbers.reversed.toList();
      }
      ''';
        expect(execute(source), equals([4, 3, 2, 1]));
      });

      test('asMap', () {
        const source = '''
       main() {
        List<int> numbers = [1, 2, 3];
        return numbers.asMap();
      }
      ''';
        expect(execute(source), equals({0: 1, 1: 2, 2: 3}));
      });
    });

    group('List methods - comprehensive', () {
      test('add', () {
        const source = '''
       main() {
        List<int> numbers = [1, 2];
        numbers.add(3);
        return numbers;
      }
      ''';
        expect(execute(source), equals([1, 2, 3]));
      });

      test('addAll', () {
        const source = '''
       main() {
        List<int> numbers = [1, 2];
        numbers.addAll([3, 4]);
        return numbers;
      }
      ''';
        expect(execute(source), equals([1, 2, 3, 4]));
      });

      test('remove', () {
        const source = '''
       main() {
        List<int> numbers = [1, 2, 3];
        numbers.remove(2);
        return numbers;
      }
      ''';
        expect(execute(source), equals([1, 3]));
      });

      test('removeAt', () {
        const source = '''
       main() {
        List<int> numbers = [1, 2, 3];
        numbers.removeAt(1);
        return numbers;
      }
      ''';
        expect(execute(source), equals([1, 3]));
      });

      test('removeLast', () {
        const source = '''
       main() {
        List<int> numbers = [1, 2, 3];
        numbers.removeLast();
        return numbers;
      }
      ''';
        expect(execute(source), equals([1, 2]));
      });

      test('removeRange', () {
        const source = '''
       main() {
        List<int> numbers = [1, 2, 3, 4];
        numbers.removeRange(1, 3);
        return numbers;
      }
      ''';
        expect(execute(source), equals([1, 4]));
      });

      test('retainWhere', () {
        const source = '''
       main() {
        List<int> numbers = [1, 2, 3, 4];
        numbers.retainWhere((n) => n % 2 == 0);
        return numbers;
      }
      ''';
        expect(execute(source), equals([2, 4]));
      });

      test('indexOf', () {
        const source = '''
       main() {
        List<int> numbers = [1, 2, 3, 2];
        return numbers.indexOf(2);
      }
      ''';
        expect(execute(source), equals(1));
      });

      test('lastIndexOf', () {
        const source = '''
       main() {
        List<int> numbers = [1, 2, 3, 2];
        return numbers.lastIndexOf(2);
      }
      ''';
        expect(execute(source), equals(3));
      });

      test('sublist', () {
        const source = '''
       main() {
        List<int> numbers = [1, 2, 3, 4];
        return numbers.sublist(1, 3);
      }
      ''';
        expect(execute(source), equals([2, 3]));
      });

      test('contains', () {
        const source = '''
       main() {
        List<int> numbers = [1, 2, 3];
        return numbers.contains(2);
      }
      ''';
        expect(execute(source), equals(true));
      });

      test('length', () {
        const source = '''
       main() {
        List<int> numbers = [1, 2, 3];
        return numbers.length;
      }
      ''';
        expect(execute(source), equals(3));
      });

      test('isEmpty and isNotEmpty', () {
        const source = '''
       main() {
        List<int> numbers = [];
        return [numbers.isEmpty, numbers.isNotEmpty];
      }
      ''';
        expect(execute(source), equals([true, false]));
      });

      test('reverse', () {
        const source = '''
       main() {
        List<int> numbers = [1, 2, 3];
        return numbers.reversed.toList();
      }
      ''';
        expect(execute(source), equals([3, 2, 1]));
      });

      test('sort', () {
        const source = '''
       main() {
        List<int> numbers = [3, 1, 2];
        numbers.sort();
        return numbers;
      }
      ''';
        expect(execute(source), equals([1, 2, 3]));
      });

      test('shuffle', () {
        const source = '''
       main() {
        List<int> numbers = [1, 2, 3];
        numbers.shuffle();
        return numbers; // Cannot check order, but check length and elements
      }
      ''';
        final result = execute(source) as List;
        expect(result, isA<List>());
        expect(result.length, equals(3));
        expect(result, containsAll([1, 2, 3]));
      });

      test('expand', () {
        const source = '''
       main() {
        List<int> numbers = [1, 2, 3];
        return numbers.expand((n) => [n, n * 2]).toList();
      }
      ''';
        expect(execute(source), equals([1, 2, 2, 4, 3, 6]));
      });

      test('forEach', () {
        const source = '''
       main() {
        List<int> numbers = [1, 2, 3];
        var sum = 0;
        numbers.forEach((n) => sum += n);
        return sum;
      }
      ''';
        expect(execute(source), equals(6));
      });

      test('map', () {
        const source = '''
       main() {
        List<int> numbers = [1, 2, 3];
        return numbers.map((n) => n * 2).toList();
      }
      ''';
        expect(execute(source), equals([2, 4, 6]));
      });

      test('where', () {
        const source = '''
       main() {
        List<int> numbers = [1, 2, 3, 4];
        return numbers.where((n) => n % 2 == 0).toList();
      }
      ''';
        expect(execute(source), equals([2, 4]));
      });

      test('reduce', () {
        const source = '''
       main() {
        List<int> numbers = [1, 2, 3];
        return numbers.reduce((a, b) => a + b);
      }
      ''';
        expect(execute(source), equals(6));
      });

      test('fold', () {
        const source = '''
       main() {
        List<int> numbers = [1, 2, 3];
        return numbers.fold(0, (a, b) => a + b);
      }
      ''';
        expect(execute(source), equals(6));
      });

      test('join', () {
        const source = '''
       main() {
        List<int> numbers = [1, 2, 3];
        return numbers.join(", ");
      }
      ''';
        expect(execute(source), equals('1, 2, 3'));
      });

      test('toSet', () {
        const source = '''
       main() {
        List<int> numbers = [1, 2, 2, 3];
        return numbers.toSet().toList();
      }
      ''';
        final result = execute(source) as List;
        result.sort();
        expect(result, equals([1, 2, 3]));
      });

      test('toList', () {
        const source = '''
       main() {
        List<int> numbers = [1, 2, 3];
        var l = numbers.toList();
        l.add(4); // Modify to ensure it's a new list
        return [numbers, l]; // Return both to check independence
      }
      ''';
        expect(
            execute(source),
            equals([
              [1, 2, 3],
              [1, 2, 3, 4]
            ]));
      });
    });

    group('Iterable methods', () {
      test('cast', () {
        const source = '''
       main() {
        Iterable<dynamic> numbers = [1, 2, 3];
        Iterable<int> casted = numbers.cast<int>();
        return casted.toList();
      }
      ''';
        expect(execute(source), equals([1, 2, 3]));
      });

      test('followedBy', () {
        const source = '''
       main() {
        Iterable<int> numbers = [1, 2];
        Iterable<int> moreNumbers = numbers.followedBy([3, 4]);
        return moreNumbers.toList();
      }
      ''';
        expect(execute(source), equals([1, 2, 3, 4]));
      });

      test('elementAt', () {
        const source = '''
       main() {
        Iterable<int> numbers = [1, 2, 3];
        return numbers.elementAt(1);
      }
      ''';
        expect(execute(source), equals(2));
      });
    });

    group('Set methods', () {
      test('retainWhere', () {
        const source = '''
       main() {
        Set<int> numbers = {1, 2, 3, 4};
        numbers.retainWhere((n) => n % 2 == 0);
        return numbers.toList(); // Convert to list for stable comparison
      }
      ''';
        final result = execute(source) as List;
        result.sort();
        expect(result, equals([2, 4]));
      });

      test('removeWhere', () {
        const source = '''
       main() {
        Set<int> numbers = {1, 2, 3, 4};
        numbers.removeWhere((n) => n % 2 == 0);
        return numbers.toList(); // Convert to list for stable comparison
      }
      ''';
        final result = execute(source) as List;
        result.sort();
        expect(result, equals([1, 3]));
      });
    });
  });
}
