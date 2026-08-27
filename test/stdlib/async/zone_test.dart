import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('runZoned and runZonedGuarded stdlib tests', () {
    test('runZoned with return value and zoneValues', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:async';

        main() {
          final res = runZoned(() {
            return 100 + 200;
          });
          return res;
        }
      ''');

      expect(result, equals(300));
    });

    test('runZonedGuarded capturing error', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:async';

        main() {
          var caughtError = '';
          runZonedGuarded(() {
            throw 'Zone exception';
          }, (error, stack) {
            caughtError = error.toString();
          });
          return caughtError;
        }
      ''');

      expect(result, equals('Zone exception'));
    });
  });
}
