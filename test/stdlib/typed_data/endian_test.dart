import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:d4rt/d4rt.dart';

void main() {
  final d4rt = D4rt();
  const String testLibPath = 'd4rt-mem:/endian_test.dart';

  dynamic executeTestScript(String scriptBody) {
    final fullScript = '''
      import 'dart:typed_data';
      main() {
        $scriptBody
      }
    ''';
    return d4rt.execute(
      library: testLibPath,
      name: 'main',
      sources: {testLibPath: fullScript},
    );
  }

  group('Endian Tests', () {
    test('Access Endian static getters', () {
      final result = executeTestScript('''
        return {
          'big': Endian.big,
          'little': Endian.little,
          'host': Endian.host,
          'isBigEndianHost': Endian.host == Endian.big
        };
      ''');

      expect(result['big'], equals(Endian.big));
      expect(result['little'], equals(Endian.little));
      expect(result['host'], equals(Endian.host));

      expect(result['isBigEndianHost'], Endian.host == Endian.big);
    });

    test('Endian values are distinct', () {
      final result = executeTestScript('''
        var isBigDifferentFromLittle = Endian.big != Endian.little;
        var isHostDifferentFromBigOrLittle = (Endian.host == Endian.big && Endian.host != Endian.little) || 
                                         (Endian.host == Endian.little && Endian.host != Endian.big);
        return {
          'bigVsLittle': isBigDifferentFromLittle,
          'hostDistinct': isHostDifferentFromBigOrLittle
        };
      ''');
      expect(result['bigVsLittle'], isTrue);
      expect(result['hostDistinct'], isTrue);
    });
  });
}
