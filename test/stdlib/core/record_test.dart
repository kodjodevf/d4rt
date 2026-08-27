import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('Record bridge tests', () {
    test('Record instance is subtype of Record', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        main() {
          final rec = (1, 'hello', count: 42);
          return [rec is Record, rec.toString()];
        }
      ''') as List;

      expect(result[0], isTrue);
      expect(result[1], contains('hello'));
    });

    test('Record equality and hashCode via bridge', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        main() {
          final r1 = (10, 20);
          final r2 = (10, 20);
          final r3 = (10, 30);
          return [r1 == r2, r1 != r3, r1.hashCode == r2.hashCode];
        }
      ''') as List;

      expect(result[0], isTrue);
      expect(result[1], isTrue);
      expect(result[2], isTrue);
    });
  });
}
