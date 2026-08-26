import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('Advanced Stdlib Features tests', () {
    test('StackTrace.fromString and static getters', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:core';

        main() {
          final customTrace = StackTrace.fromString('custom error line 42');
          final emptyTrace = StackTrace.empty;
          final currTrace = StackTrace.current;
          return [customTrace.toString(), emptyTrace.toString(), currTrace is StackTrace];
        }
      ''');

      expect(result, equals(['custom error line 42', '', true]));
    });

    test('LineSplitter.split static method', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:convert';

        main() {
          final text = 'line 1\\nline 2\\r\\nline 3';
          return LineSplitter.split(text);
        }
      ''');

      expect(result, equals(['line 1', 'line 2', 'line 3']));
    });

    test('Future.wait with mixed values and futures', () async {
      final d4rt = D4rt();
      final result = await d4rt.execute(source: '''
        import 'dart:async';

        main() async {
          final list = [Future.value(10), 20, Future.value(30)];
          final results = await Future.wait(list);
          return results;
        }
      ''');

      expect(result, equals([10, 20, 30]));
    });
  });
}
