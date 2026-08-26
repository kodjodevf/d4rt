import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('WeakReference and Finalizer stdlib tests', () {
    test('WeakReference basic usage', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:core';

        class Data {
          String name;
          Data(this.name);
        }

        main() {
          final data = Data('secret');
          final ref = WeakReference(data);
          return [ref.target != null, (ref.target as Data).name];
        }
      ''');

      expect(result, equals([true, 'secret']));
    });

    test('Finalizer attach and detach methods', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:core';

        class Resource {
          int id;
          Resource(this.id);
        }

        main() {
          final finalizer = Finalizer<int>((token) {
            print('Cleaned up resource: \$token');
          });

          final res1 = Resource(1);
          final res2 = Resource(2);

          finalizer.attach(res1, 1, detach: res1);
          finalizer.attach(res2, 2, detach: res2);

          finalizer.detach(res1);

          return [finalizer != null, finalizer.hashCode != 0];
        }
      ''');

      expect(result, equals([true, true]));
    });
  });
}
