import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('RuneIterator stdlib tests', () {
    test('RuneIterator forward and backward iteration', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:core';

        main() {
          final it = RuneIterator('Dart 🎯');
          final chars = <String>[];
          while (it.moveNext()) {
            chars.add(it.currentAsString);
          }
          // it is now past the end
          it.movePrevious();
          final lastChar = it.currentAsString;
          it.movePrevious();
          final prevChar = it.currentAsString;
          return [chars.join(''), lastChar, prevChar];
        }
      ''');

      expect(result, equals(['Dart 🎯', '🎯', ' ']));
    });

    test('RuneIterator.at constructor and reset', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:core';

        main() {
          final it = RuneIterator.at('Hello', 2);
          it.moveNext();
          final atChar = it.currentAsString;
          it.reset(0);
          it.moveNext();
          final firstChar = it.currentAsString;
          return [atChar, firstChar];
        }
      ''');

      expect(result, equals(['l', 'H']));
    });
  });
}
