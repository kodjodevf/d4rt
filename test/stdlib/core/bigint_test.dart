import '../../interpreter_test.dart';
import 'package:test/test.dart';

void main() {
  group('BigInt tests', () {
    test('BigInt.parse', () {
      const source = '''
      main() {
        BigInt bigInt = BigInt.parse("123456789012345678901234567890");
        return bigInt.toString();
      }
      ''';
      expect(execute(source), equals('123456789012345678901234567890'));
    });

    test('BigInt.tryParse', () {
      const source = '''
      main() {
        BigInt? bigInt = BigInt.tryParse("123456789012345678901234567890");
        return bigInt?.toString();
      }
      ''';
      expect(execute(source), equals('123456789012345678901234567890'));
    });

    test('BigInt.add and subtract', () {
      const source = '''
      main() {
        BigInt bigInt1 = BigInt.parse("100000000000000000000000000000");
        BigInt bigInt2 = BigInt.parse("200000000000000000000000000000");
        return [(bigInt1 + bigInt2).toString(), (bigInt2 - bigInt1).toString()];
      }
      ''';
      expect(
          execute(source),
          equals([
            '300000000000000000000000000000',
            '100000000000000000000000000000'
          ]));
    });

    test('BigInt.multiply and divide', () {
      const source = '''
      main() {
        BigInt bigInt1 = BigInt.parse("100000000000000000000000000000");
        BigInt bigInt2 = BigInt.parse("2");
        return [(bigInt1 * bigInt2).toString(), (bigInt1 ~/ bigInt2).toString()];
      }
      ''';
      expect(
          execute(source),
          equals([
            '200000000000000000000000000000',
            '50000000000000000000000000000'
          ]));
    });

    test('BigInt.modulo and remainder', () {
      const source = '''
      main() {
        BigInt bigInt1 = BigInt.parse("100000000000000000000000000001");
        BigInt bigInt2 = BigInt.parse("2");
        return [(bigInt1 % bigInt2).toString(), (bigInt1.remainder(bigInt2)).toString()];
      }
      ''';
      expect(execute(source), equals(['1', '1']));
    });

    test('BigInt.abs and negate', () {
      const source = '''
      main() {
        BigInt bigInt = BigInt.parse("-123456789012345678901234567890");
        return [bigInt.abs().toString(), (-bigInt).toString()];
      }
      ''';
      expect(
          execute(source),
          equals([
            '123456789012345678901234567890',
            '123456789012345678901234567890'
          ]));
    });

    test('BigInt.compareTo', () {
      const source = '''
      main() {
        BigInt bigInt1 = BigInt.parse("100000000000000000000000000000");
        BigInt bigInt2 = BigInt.parse("200000000000000000000000000000");
        return [bigInt1.compareTo(bigInt2), bigInt2.compareTo(bigInt1), bigInt1.compareTo(bigInt1)];
      }
      ''';
      expect(execute(source), equals([-1, 1, 0]));
    });

    test('BigInt.bitLength and sign', () {
      const source = '''
      main() {
        BigInt bigInt = BigInt.parse("123456789012345678901234567890");
        return [bigInt.bitLength, bigInt.sign];
      }
      ''';
      final result = execute(source) as List;
      expect(result[0], isA<int>()); // bitLength is int
      expect(result[1], equals(1)); // sign is 1 for positive
    });

    test('BigInt.toRadixString', () {
      const source = '''
      main() {
        BigInt bigInt = BigInt.parse("255");
        return bigInt.toRadixString(16);
      }
      ''';
      expect(execute(source), equals('ff'));
    });

    test('BigInt.pow', () {
      const source = '''
      main() {
        BigInt bigInt = BigInt.parse("2");
        return bigInt.pow(10).toString();
      }
      ''';
      expect(execute(source), equals('1024'));
    });

    test('BigInt.toUnsigned and toSigned', () {
      const source = '''
      main() {
        BigInt bigInt = BigInt.parse("123456789012345678901234567890");
        return [bigInt.toUnsigned(64).toString(), bigInt.toSigned(64).toString()];
      }
      ''';
      final result = execute(source) as List;
      expect(result[0], isA<String>());
      expect(result[1], isA<String>());
    });

    test('BigInt.isEven and isOdd', () {
      const source = '''
      main() {
        BigInt bigInt1 = BigInt.parse("123456789012345678901234567890");
        BigInt bigInt2 = BigInt.parse("123456789012345678901234567891");
        return [bigInt1.isEven, bigInt2.isOdd];
      }
      ''';
      expect(execute(source), equals([true, true]));
    });

    test('BigInt.gcd', () {
      const source = '''
      main() {
        BigInt bigInt1 = BigInt.parse("48");
        BigInt bigInt2 = BigInt.parse("18");
        return bigInt1.gcd(bigInt2).toString();
      }
      ''';
      expect(execute(source), equals('6'));
    });

    test('BigInt.modPow and modInverse', () {
      const source = '''
      main() {
        BigInt base = BigInt.parse("4");
        BigInt exponent = BigInt.parse("13");
        BigInt modulus = BigInt.parse("497");
        return [base.modPow(exponent, modulus).toString(), base.modInverse(modulus).toString()];
      }
      ''';
      expect(execute(source), equals(['445', '373']));
    });
  });
}
