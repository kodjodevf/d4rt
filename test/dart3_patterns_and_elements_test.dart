import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('Dart 3.0+ Patterns and Modern Language Features Tests', () {
    late D4rt d4rt;

    setUp(() {
      d4rt = D4rt();
    });

    test('Relational patterns and Logical-AND patterns in switch expressions', () {
      final result = d4rt.execute(source: '''
        String classify(int score) => switch (score) {
          >= 90 => 'A',
          >= 80 && < 90 => 'B',
          >= 70 && < 80 => 'C',
          >= 60 && < 70 => 'D',
          < 60 => 'F',
          _ => 'Unknown',
        };

        main() {
          return [
            classify(95),
            classify(85),
            classify(72),
            classify(60),
            classify(45),
          ];
        }
      ''') as List;

      expect(result, equals(['A', 'B', 'C', 'D', 'F']));
    });

    test('Relational patterns in switch statement with when guards', () {
      final result = d4rt.execute(source: '''
        String testSwitch(int value, bool extraCheck) {
          String res = '';
          switch (value) {
            case > 100 when extraCheck:
              res = 'very large verified';
              break;
            case > 100:
              res = 'very large unverified';
              break;
            case <= 0:
              res = 'non-positive';
              break;
            default:
              res = 'normal';
          }
          return res;
        }

        main() {
          return [
            testSwitch(150, true),
            testSwitch(150, false),
            testSwitch(-5, false),
            testSwitch(42, false),
          ];
        }
      ''') as List;

      expect(result, equals([
        'very large verified',
        'very large unverified',
        'non-positive',
        'normal',
      ]));
    });

    test('NullCheck, NullAssert, Parenthesized and Cast patterns', () {
      final result = d4rt.execute(source: '''
        String testPatterns(Object? obj) => switch (obj) {
          (int x) when x > 0 => 'positive-int:\$x',
          int x? => 'non-null-int:\$x',
          String s => 'string:\$s',
          _ => 'other',
        };

        main() {
          return [
            testPatterns(42),
            testPatterns(-5),
            testPatterns('hello'),
            testPatterns(null),
          ];
        }
      ''') as List;

      expect(result, equals([
        'positive-int:42',
        'non-null-int:-5',
        'string:hello',
        'other',
      ]));
    });

    test('For-in loop with pattern destructuring', () {
      final result = d4rt.execute(source: '''
        main() {
          final points = [(1, 2), (3, 4), (5, 6)];
          int sumX = 0;
          int sumY = 0;

          for (final (x, y) in points) {
            sumX += x as int;
            sumY += y as int;
          }

          return [sumX, sumY];
        }
      ''') as List;

      expect(result, equals([9, 12]));
    });

    test('Collection for-in with pattern destructuring and if-case in collections', () {
      final result = d4rt.execute(source: '''
        main() {
          final pairs = [('a', 1), ('b', 2), ('c', 3)];
          final formatted = [for (final (k, v) in pairs) '\$k:\$v'];

          final user1 = ('Alice', 25);
          final user2 = ('Bob', 15);

          final statusList = [
            if (user1 case (var name, var age) when age >= 18) 'Adult: \$name' else 'Minor',
            if (user2 case (var name, var age) when age >= 18) 'Adult: \$name' else 'Minor',
          ];

          return [formatted, statusList];
        }
      ''') as List;

      expect(result[0], equals(['a:1', 'b:2', 'c:3']));
      expect(result[1], equals(['Adult: Alice', 'Minor']));
    });
  });
}
