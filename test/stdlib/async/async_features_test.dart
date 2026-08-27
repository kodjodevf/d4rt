import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('Async Features and Subtyping Stdlib Tests', () {
    late D4rt d4rt;

    setUp(() {
      d4rt = D4rt();
    });

    test('Timer.run and unawaited execution', () async {
      final result = await d4rt.execute(source: '''
        import 'dart:async';

        main() async {
          int count = 0;
          Timer.run(() {
            count += 10;
          });
          unawaited(Future.delayed(Duration(milliseconds: 10), () {
            count += 5;
          }));
          await Future.delayed(Duration(milliseconds: 50));
          return count;
        }
      ''');

      expect(result, equals(15));
    });

    test('Async subtyping and is-checks', () async {
      final result = await d4rt.execute(source: '''
        import 'dart:async';

        main() async {
          final fut = Future.value(42);
          final controller = StreamController();
          final stream = controller.stream;
          final subscription = stream.listen((_) {});
          final timer = Timer(Duration(milliseconds: 100), () {});
          final timeoutEx = TimeoutException('timed out', Duration(seconds: 1));

          final isFut = fut is Future;
          final isController = controller is StreamController;
          final isStream = stream is Stream;
          final isSub = subscription is StreamSubscription;
          final isTimer = timer is Timer;
          final isTimeoutEx = timeoutEx is TimeoutException;

          await subscription.cancel();
          await controller.close();
          timer.cancel();

          return [
            isFut,
            isController,
            isStream,
            isSub,
            isTimer,
            isTimeoutEx,
          ];
        }
      ''') as List;

      expect(result[0], isTrue);
      expect(result[1], isTrue);
      expect(result[2], isTrue);
      expect(result[3], isTrue);
      expect(result[4], isTrue);
      expect(result[5], isTrue);
    });
  });
}
