import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('Stopwatch stdlib bridge tests', () {
    test('Stopwatch lifecycle (start, elapsed, stop, reset)', () async {
      final d4rt = D4rt();
      final result = await d4rt.execute(source: '''
        import 'dart:core';

        main() {
          final sw = Stopwatch();
          final initialElapsed = sw.elapsedMilliseconds;
          final wasRunning = sw.isRunning;
          sw.start();
          final isRunningNow = sw.isRunning;
          sw.stop();
          final stoppedRunning = sw.isRunning;
          sw.reset();
          final afterReset = sw.elapsedMilliseconds;
          return [initialElapsed, wasRunning, isRunningNow, stoppedRunning, afterReset];
        }
      ''');

      expect(result, equals([0, false, true, false, 0]));
    });

    test('Stopwatch.createStarted static method', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:core';

        main() {
          final sw = Stopwatch.createStarted();
          final running = sw.isRunning;
          sw.stop();
          return running;
        }
      ''');

      expect(result, isTrue);
    });
  });
}
