import '../../interpreter_test.dart';
import 'package:test/test.dart';

void main() {
  group('double tests', () {
    test('double.parse', () {
      const source = '''
      main() {
        double value1 = double.parse("123.45");
        double value2 = double.parse("-678.90");
        return [value1, value2];
      }
      ''';
      expect(execute(source), equals([123.45, -678.9]));
    });

    test('double.tryParse', () {
      const source = '''
      main() {
        double? value1 = double.tryParse("123.45");
        double? value2 = double.tryParse("-678.90");
        double? value3 = double.tryParse("invalid");
        return [value1, value2, value3];
      }
      ''';
      expect(execute(source), equals([123.45, -678.9, null]));
    });

    test('double.toString', () {
      const source = '''
      main() {
        double value1 = 123.45;
        double value2 = -678.90;
        return [value1.toString(), value2.toString()];
      }
      ''';
      expect(execute(source), equals(['123.45', '-678.9']));
    });

    test('double.abs', () {
      const source = '''
      main() {
        double value = -123.45;
        return value.abs();
      }
      ''';
      expect(execute(source), equals(123.45));
    });

    test('double.ceil, floor, round, and truncate', () {
      const source = '''
      main() {
        double value = 123.45;
        return [value.ceil(), value.floor(), value.round(), value.truncate()];
      }
      ''';
      expect(execute(source), equals([124, 123, 123, 123]));
    });

    test('double.toInt and toDouble', () {
      const source = '''
      main() {
        double value = 123.45;
        return [value.toInt(), value.toDouble()];
      }
      ''';
      expect(execute(source), equals([123, 123.45]));
    });

    test('double.isFinite, isInfinite, isNaN, and isNegative', () {
      const source = '''
      main() {
        double value1 = 123.45;
        double value2 = double.infinity;
        double value3 = double.nan;
        return [value1.isFinite, value2.isInfinite, value3.isNaN, (-value1).isNegative];
      }
      ''';
      expect(execute(source), equals([true, true, true, true]));
    });

    test('double.clamp', () {
      const source = '''
      main() {
        double value = 123.45;
        return [value.clamp(100, 200), value.clamp(130, 140)];
      }
      ''';
      expect(execute(source), equals([123.45, 130.0]));
    });

    test('double.remainder', () {
      const source = '''
      main() {
        double value = 123.45;
        return value.remainder(10);
      }
      ''';
      expect(execute(source), closeTo(3.45, 0.001));
    });

    test(
        'double.toStringAsFixed, toStringAsExponential, and toStringAsPrecision',
        () {
      const source = '''
      main() {
        double value = 123.456789;
        return [value.toStringAsFixed(2), value.toStringAsExponential(2), value.toStringAsPrecision(4)];
      }
      ''';
      expect(execute(source), equals(['123.46', '1.23e+2', '123.5']));
    });

    test('double.hashCode', () {
      const source = '''
      main() {
        double value = 123.45;
        return value.hashCode;
      }
      ''';
      expect(execute(source), isA<int>());
    });

    test('double static properties', () {
      const source = '''
      main() {
        return [double.maxFinite, double.minPositive, double.infinity, double.negativeInfinity, double.nan];
      }
      ''';
      final result = execute(source) as List;
      expect(result[0], isA<double>());
      expect(result[1], isA<double>());
      expect(result[2], isA<double>());
      expect(result[3], isA<double>());
      expect(result[4], isA<double>());
      expect(result[0].isFinite, isTrue);
      expect(result[1], greaterThan(0));
      expect(result[2].isInfinite, isTrue);
      expect(result[3].isInfinite, isTrue);
      expect(result[3].isNegative, isTrue);
      expect(result[4].isNaN, isTrue);
    });
  });
}
