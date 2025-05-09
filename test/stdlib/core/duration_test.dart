import '../../interpreter_test.dart';
import 'package:test/test.dart';

void main() {
  group('Duration tests', () {
    test('Duration creation', () {
      const source = '''
     main() {
        Duration duration = Duration(days: 1, hours: 2, minutes: 30, seconds: 45, milliseconds: 500, microseconds: 250);
        return [
          duration.inDays,
          duration.inHours,
          duration.inMinutes,
          duration.inSeconds,
          duration.inMilliseconds,
          duration.inMicroseconds
        ];
      }
      ''';
      expect(
          execute(source), equals([1, 26, 1590, 95445, 95445500, 95445500250]));
    });

    test('Duration.fromMilliseconds and fromMicroseconds', () {
      const source = '''
     main() {
        Duration duration1 = Duration(milliseconds: 123456);
        Duration duration2 = Duration(microseconds: 123456789);
        return [duration1.inMilliseconds, duration2.inMicroseconds];
      }
      ''';
      expect(execute(source), equals([123456, 123456789]));
    });

    test('Duration addition and subtraction', () {
      const source = '''
     main() {
        Duration duration1 = Duration(hours: 1);
        Duration duration2 = Duration(minutes: 30);
        return [(duration1 + duration2).inMinutes, (duration1 - duration2).inMinutes];
      }
      ''';
      expect(execute(source), equals([90, 30]));
    });

    test('Duration multiplication and division', () {
      const source = '''
     main() {
        Duration duration = Duration(minutes: 30);
        return [(duration * 2).inMinutes, (duration ~/ 2).inMinutes];
      }
      ''';
      expect(execute(source), equals([60, 15]));
    });

    test('Duration comparison', () {
      const source = '''
     main() {
        Duration duration1 = Duration(hours: 1);
        Duration duration2 = Duration(minutes: 30);
        return [duration1 > duration2, duration1 < duration2, duration1 == Duration(hours: 1)];
      }
      ''';
      expect(execute(source), equals([true, false, true]));
    });

    test('Duration properties', () {
      const source = '''
     main() {
        Duration duration = Duration(days: 1, hours: 2, minutes: 30, seconds: 45, milliseconds: 500, microseconds: 250);
        return [duration.isNegative, duration.abs().inHours];
      }
      ''';
      expect(execute(source), equals([false, 26]));
    });

    test('Duration.toString', () {
      const source = '''
     main() {
        Duration duration = Duration(hours: 1, minutes: 30, seconds: 45);
        return duration.toString();
      }
      ''';
      expect(execute(source), equals('1:30:45.000000'));
    });

    test('Duration.zero', () {
      const source = '''
     main() {
        Duration duration = Duration.zero;
        return duration.inMilliseconds;
      }
      ''';
      expect(execute(source), equals(0));
    });

    test('Duration.compareTo', () {
      const source = '''
     main() {
        Duration duration1 = Duration(hours: 1);
        Duration duration2 = Duration(minutes: 30);
        return [duration1.compareTo(duration2), duration2.compareTo(duration1), duration1.compareTo(Duration(hours: 1))];
      }
      ''';
      expect(execute(source), equals([1, -1, 0]));
    });
  });
}
