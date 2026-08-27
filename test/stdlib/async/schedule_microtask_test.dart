import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('scheduleMicrotask and Zone stdlib tests', () {
    test('scheduleMicrotask executes asynchronously', () async {
      final d4rt = D4rt();
      final result = await d4rt.execute(source: '''
        import 'dart:async';

        Future<List<String>> main() async {
          final events = <String>[];
          events.add('start');

          scheduleMicrotask(() {
            events.add('microtask');
          });

          events.add('end');
          await Future.delayed(Duration(milliseconds: 50));
          return events;
        }
      ''') as List;

      expect(result, equals(['start', 'end', 'microtask']));
    });

    test('Zone.current and Zone.root bridge access', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:async';

        main() {
          final cur = Zone.current;
          final root = Zone.root;
          return [cur != null, root != null, root.inSameErrorZone(root)];
        }
      ''') as List;

      expect(result[0], isTrue);
      expect(result[1], isTrue);
      expect(result[2], isTrue);
    });

    test('Zone.run execution', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:async';

        main() {
          final res = Zone.current.run(() {
            return 40 + 2;
          });
          return res;
        }
      ''');

      expect(result, equals(42));
    });
  });
}
