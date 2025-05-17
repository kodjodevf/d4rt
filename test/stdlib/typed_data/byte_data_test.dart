import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:d4rt/d4rt.dart';

void main() {
  final d4rt = D4rt();
  const String testLibPath = 'd4rt-mem:/byte_data_test.dart';

  dynamic executeTestScript(String scriptBody) {
    final fullScript = '''
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

  group('ByteData Tests', () {
    test('Constructor ByteData(length) and basic properties', () {
      final result = executeTestScript('''
        var bd = new ByteData(10);
        return {
          'length': bd.lengthInBytes,
          'elementSize': bd.elementSizeInBytes
        };
      ''');
      expect(result['length'], 10);
      expect(result['elementSize'], 1);
    });

    test('ByteData getInt8 and setInt8', () {
      final result = executeTestScript('''
        var bd = new ByteData(2);
        bd.setInt8(0, -5); // Max negative for int8 is -128
        bd.setInt8(1, 127);
        return {
          'val0': bd.getInt8(0),
          'val1': bd.getInt8(1)
        };
      ''');
      expect(result['val0'], -5);
      expect(result['val1'], 127);
    });

    test('ByteData getUint16 and setUint16 (default Endian.big)', () {
      final result = executeTestScript('''
        var bd = new ByteData(4);
        // Default Endian.big: MSB first
        // For 0xABCD -> bd[0]=AB, bd[1]=CD
        bd.setUint16(0, 0xABCD); 
        bd.setUint16(2, 0x1234, Endian.little); // LSB first: bd[2]=34, bd[3]=12
        
        return {
          'valBig': bd.getUint16(0), // Reads with Endian.big by default
          'valLittle': bd.getUint16(2, Endian.little),
          // Raw bytes to verify
          'byte0': bd.buffer.asUint8List()[0],
          'byte1': bd.buffer.asUint8List()[1],
          'byte2': bd.buffer.asUint8List()[2],
          'byte3': bd.buffer.asUint8List()[3],
        };
      ''');
      expect(result['valBig'], 0xABCD);
      expect(result['valLittle'], 0x1234);
      expect(result['byte0'], 0xAB);
      expect(result['byte1'], 0xCD);
      expect(result['byte2'], 0x34);
      expect(result['byte3'], 0x12);
    });

    test('ByteData getUint16 and setUint16 with explicit Endian', () {
      final result = executeTestScript('''
        var bd = new ByteData(2);
        bd.setUint16(0, 0x1234, Endian.little);
        return {
          'valDefaultBig': bd.getUint16(0), // default is big
          'valLittle': bd.getUint16(0, Endian.little),
          'byte0': bd.buffer.asUint8List()[0], // Should be 0x34 for little endian
          'byte1': bd.buffer.asUint8List()[1], // Should be 0x12 for little endian
        };
      ''');
      // Native getUint16(0) with default Endian.big will read 0x3412 if bytes are [0x34, 0x12]
      expect(
          result['valDefaultBig'],
          (ByteData(2)
                ..setUint8(0, 0x34)
                ..setUint8(1, 0x12))
              .getUint16(0, Endian.big));
      expect(result['valLittle'], 0x1234);
      expect(result['byte0'], 0x34);
      expect(result['byte1'], 0x12);
    });

    test('ByteData buffer property', () {
      final result = executeTestScript('''
        var bd = new ByteData(3);
        var buffer = bd.buffer;
        return {
          'bufferLength': buffer.lengthInBytes
        };
      ''');
      expect(result['bufferLength'], 3);
    });

    test('Offset out of bounds throws error', () {
      expect(
        () => executeTestScript("var bd = new ByteData(1); bd.getInt8(1);"),
        throwsA(isA<RuntimeError>()),
      );
      expect(
        () => executeTestScript("var bd = new ByteData(1); bd.setInt8(1, 0);"),
        throwsA(isA<RuntimeError>()),
      );
      expect(
        () => executeTestScript("var bd = new ByteData(1); bd.getUint16(0);"),
        throwsA(isA<RuntimeError>()), // Not enough space for Uint16
      );
    });
  });
}
