import '../../interpreter_test.dart';
import 'package:test/test.dart';

void main() {
  group('num methods - comprehensive', () {
    test('abs', () {
      const source = '''
     main() {
        num value = -42.5;
        return value.abs();
      }
      ''';
      expect(execute(source), equals(42.5));
    });

    test('ceil', () {
      const source = '''
     main() {
        num value = 42.3;
        return value.ceil();
      }
      ''';
      expect(execute(source), equals(43));
    });

    test('floor', () {
      const source = '''
     main() {
        num value = 42.7;
        return value.floor();
      }
      ''';
      expect(execute(source), equals(42));
    });

    test('round', () {
      const source = '''
     main() {
        num value = 42.5;
        return value.round();
      }
      ''';
      expect(execute(source), equals(43));
    });

    test('toInt', () {
      const source = '''
     main() {
        num value = 42.9;
        return value.toInt();
      }
      ''';
      expect(execute(source), equals(42));
    });

    test('toDouble', () {
      const source = '''
     main() {
        num value = 42;
        return value.toDouble();
      }
      ''';
      expect(execute(source), equals(42.0));
    });

    test('toString', () {
      const source = '''
     main() {
        num value = 42.5;
        return value.toString();
      }
      ''';
      expect(execute(source), equals('42.5'));
    });

    test('isFinite', () {
      const source = '''
     main() {
        num value = 42.5;
        return value.isFinite;
      }
      ''';
      expect(execute(source), isTrue);
    });

    test('isInfinite', () {
      const source = '''
     main() {
        num value = double.infinity;
        return value.isInfinite;
      }
      ''';
      expect(execute(source), isTrue);
    });

    test('isNaN', () {
      const source = '''
     main() {
        num value = double.nan;
        return value.isNaN;
      }
      ''';
      expect(execute(source), isTrue);
    });

    test('isNegative', () {
      const source = '''
     main() {
        num value = -42.5;
        return value.isNegative;
      }
      ''';
      expect(execute(source), isTrue);
    });

    test('clamp', () {
      const source = '''
     main() {
        num value = 42.5;
        return [value.clamp(40, 45), value.clamp(43, 50)];
      }
      ''';
      expect(execute(source), equals([42.5, 43]));
    });

    test('remainder', () {
      const source = '''
     main() {
        num value = 42.5;
        return value.remainder(10);
      }
      ''';
      expect(execute(source), equals(2.5));
    });

    test('compareTo', () {
      const source = '''
     main() {
        num value = 42.5;
        return [value.compareTo(42.5), value.compareTo(50), value.compareTo(40)];
      }
      ''';
      expect(execute(source), equals([0, -1, 1]));
    });

    test('sign', () {
      const source = '''
     main() {
        num value = -42.5;
        return value.sign;
      }
      ''';
      expect(execute(source), equals(-1.0));
    });

    test('toStringAsFixed', () {
      const source = '''
     main() {
        num value = 42.56789;
        return value.toStringAsFixed(2);
      }
      ''';
      expect(execute(source), equals('42.57'));
    });

    test('toStringAsExponential', () {
      const source = '''
     main() {
        num value = 42.56789;
        return value.toStringAsExponential(2);
      }
      ''';
      expect(execute(source), equals('4.26e+1'));
    });

    test('toStringAsPrecision', () {
      const source = '''
     main() {
        num value = 42.56789;
        return value.toStringAsPrecision(4);
      }
      ''';
      expect(execute(source), equals('42.57'));
    });

    test('truncate', () {
      const source = '''
     main() {
        num value = 42.9;
        return value.truncate();
      }
      ''';
      expect(execute(source), equals(42));
    });

    test('truncateToDouble', () {
      const source = '''
     main() {
        num value = 42.9;
        return value.truncateToDouble();
      }
      ''';
      expect(execute(source), equals(42.0));
    });

    test('ceilToDouble', () {
      const source = '''
     main() {
        num value = 42.3;
        return value.ceilToDouble();
      }
      ''';
      expect(execute(source), equals(43.0));
    });

    test('floorToDouble', () {
      const source = '''
     main() {
        num value = 42.7;
        return value.floorToDouble();
      }
      ''';
      expect(execute(source), equals(42.0));
    });

    test('roundToDouble', () {
      const source = '''
     main() {
        num value = 42.5;
        return value.roundToDouble();
      }
      ''';
      expect(execute(source), equals(43.0));
    });

    test('parse', () {
      const source = '''
     main() {
        num value = num.parse("42.5");
        return value;
      }
      ''';
      expect(execute(source), equals(42.5));
    });

    test('tryParse', () {
      const source = '''
     main() {
        num? value = num.tryParse("42.5");
        num? invalid = num.tryParse("invalid");
        return [value, invalid];
      }
      ''';
      expect(execute(source), equals([42.5, null]));
    });
  });
}
