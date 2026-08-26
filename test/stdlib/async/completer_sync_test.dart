import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('Completer.sync stdlib tests', () {
    test('Completer.sync instantiation and completion', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:async';

        main() {
          final completer = Completer.sync();
          completer.complete('sync value');
          return [completer.isCompleted, completer.future is Future];
        }
      ''');

      expect(result, equals([true, true]));
    });
  });
}
