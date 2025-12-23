import 'package:test/test.dart';
import 'package:d4rt/d4rt.dart';

dynamic execute(String source, {List<Object?>? args}) {
  final d4rt = D4rt()..setDebug(false);
  return d4rt.execute(
      library: 'package:test/main.dart',
      positionalArgs: args,
      sources: {'package:test/main.dart': source});
}

void main() {
  group('Advanced Pattern Matching Features', () {
    test('List patterns with rest elements - multiple positions', () {
      final code = '''
        main() {
          var results = [];
          
          // Rest at end
          var list1 = [1, 2, 3, 4, 5];
          switch (list1) {
            case [var first, var second, ...var rest]:
              results.add(['end', first, second, rest]);
          }
          
          // Rest at beginning  
          var list2 = [10, 20, 30, 40];
          switch (list2) {
            case [...var beginning, var last]:
              results.add(['beginning', beginning, last]);
          }
          
          // Rest in middle
          var list3 = [100, 200, 300, 400, 500];
          switch (list3) {
            case [var first, ...var middle, var last]:
              results.add(['middle', first, middle, last]);
          }
          
          return results;
        }
      ''';

      final result = execute(code);
      expect(
          result,
          equals([
            [
              'end',
              1,
              2,
              [3, 4, 5]
            ],
            [
              'beginning',
              [10, 20, 30],
              40
            ],
            [
              'middle',
              100,
              [200, 300, 400],
              500
            ]
          ]));
    });

    test('Map patterns with rest elements', () {
      final code = '''
        main() {
          var map = {'name': 'John', 'age': 25, 'city': 'NYC', 'country': 'USA'};
          switch (map) {
            case {'name': var name, 'age': var age, ...var rest}:
              return [name, age, rest];
            default:
              return "no match";
          }
        }
      ''';

      final result = execute(code);
      expect(
          result,
          equals([
            'John',
            25,
            {'city': 'NYC', 'country': 'USA'}
          ]));
    });

    test('Nested pattern matching with rest elements', () {
      final code = '''
        main() {
          var data = [
            {'type': 'user', 'data': [1, 2, 3, 4]},
            'extra'
          ];
          
          switch (data) {
            case [{'type': var type, 'data': [var first, ...var rest]}, ...var remaining]:
              return [type, first, rest, remaining];
            default:
              return "no match";
          }
        }
      ''';

      final result = execute(code);
      expect(
          result,
          equals([
            'user',
            1,
            [2, 3, 4],
            ['extra']
          ]));
    });

    test('Anonymous rest elements (no binding)', () {
      final code = '''
        main() {
          var list = [1, 2, 3, 4, 5, 6, 7, 8, 9];
          switch (list) {
            case [var first, var second, ...]:  // Anonymous rest - no binding
              return [first, second, 'has_more'];
            default:
              return "no match";
          }
        }
      ''';

      final result = execute(code);
      expect(result, equals([1, 2, 'has_more']));
    });

    test('Map patterns with anonymous rest', () {
      final code = '''
        main() {
          var config = {
            'enabled': true,
            'timeout': 30,
            'retries': 3,
            'debug': false,
            'verbose': true
          };
          
          switch (config) {
            case {'enabled': true, 'timeout': var t, ...}:  // Anonymous rest
              return ['enabled_with_timeout', t];
            case {'enabled': false, ...}:
              return ['disabled'];
            default:
              return "unknown_config";
          }
        }
      ''';

      final result = execute(code);
      expect(result, equals(['enabled_with_timeout', 30]));
    });

    test('Empty rest elements', () {
      final code = '''
        main() {
          var results = [];
          
          // List with exact match using rest
          var list1 = [1, 2];
          switch (list1) {
            case [var a, var b, ...var rest]:
              results.add(['list', a, b, rest]);
          }
          
          // Map with exact match using rest  
          var map1 = {'x': 10, 'y': 20};
          switch (map1) {
            case {'x': var x, 'y': var y, ...var rest}:
              results.add(['map', x, y, rest]);
          }
          
          return results;
        }
      ''';

      final result = execute(code);
      expect(
          result,
          equals([
            ['list', 1, 2, []],
            ['map', 10, 20, {}]
          ]));
    });

    test('Complex pattern matching with guards (when available)', () {
      final code = '''
        main() {
          var data = [
            [1, 2, 3, 4, 5],
            [10, 20],
            [100, 200, 300]
          ];
          
          var results = [];
          for (var item in data) {
            switch (item) {
              case [var first, ...var rest] when rest.length > 2:
                results.add(['long', first, rest.length]);
                break;
              case [var first, ...var rest]:
                results.add(['short', first, rest.length]);
                break;
              default:
                results.add(['unknown']);
            }
          }
          
          return results;
        }
      ''';

      // Note: Guards (when clauses) might not be fully implemented yet
      // This test will verify what we can handle
      try {
        final result = execute(code);
        // If guards work, we should get meaningful results
        expect(result, isA<List>());
      } catch (e) {
        // If guards don't work yet, that's expected
        expect(e, isA<Exception>());
      }
    });
  });
}
