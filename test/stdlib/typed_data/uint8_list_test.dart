import 'package:test/test.dart';
import 'package:d4rt/d4rt.dart';

void main() {
  final d4rt = D4rt();
  const String testLibPath = 'd4rt-mem:/uint8_list_test.dart';

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

  group('Uint8List Tests', () {
    test('Constructor Uint8List(length)', () {
      final result = executeTestScript('''
        var list = Uint8List(5);
        return {
          'length': list.length,
          'elementSize': list.elementSizeInBytes,
          'defaultValue': list[0] // Should be 0
        };
      ''');
      expect(result['length'], 5);
      expect(result['elementSize'], 1);
      expect(result['defaultValue'], 0);
    });

    test('Constructor Uint8List.fromList()', () {
      final result = executeTestScript('''
        var source = [10, 20, 30];
        var list = Uint8List.fromList(source);
        return {
          'length': list.length,
          'val0': list[0],
          'val2': list[2]
        };
      ''');
      expect(result['length'], 3);
      expect(result['val0'], 10);
      expect(result['val2'], 30);
    });

    test('Uint8List operator [] and []=', () {
      final result = executeTestScript('''
        var list = Uint8List(3);
        list[0] = 255;
        list[1] = 128;
        list[2] = list[0] - list[1]; // 255 - 128 = 127
        return {
          'val0': list[0],
          'val1': list[1],
          'val2': list[2]
        };
      ''');
      expect(result['val0'], 255);
      expect(result['val1'], 128);
      expect(result['val2'], 127);
    });

    test('Uint8List sublist', () {
      final result = executeTestScript('''
        var list = Uint8List.fromList([0,1,2,3,4,5]);
        var sub = list.sublist(2, 5); // Elements at index 2, 3, 4
        var values = [];
        for (var i=0; i < sub.length; i++) { values.add(sub[i]); }
        return {
          'subLength': sub.length,
          'subValues': values,
          'originalLength': list.length
        };
      ''');
      expect(result['subLength'], 3);
      expect(result['subValues'], orderedEquals([2, 3, 4]));
      expect(result['originalLength'], 6);
    });

    test('Uint8List buffer property', () {
      final result = executeTestScript('''
        var list = Uint8List(7);
        var buffer = list.buffer;
        return {
          'bufferLength': buffer.lengthInBytes
        };
      ''');
      expect(result['bufferLength'], 7);
    });

    test('Uint8List.fromList with non-int values throws error', () {
      expect(
        () => executeTestScript("var list = Uint8List.fromList([1, 'a', 3]);"),
        throwsA(isA<RuntimeError>()),
      );
    });

    test('Index out of bounds for Uint8List[] and []=', () {
      expect(
        () => executeTestScript("var list = Uint8List(2); list[2] = 0;"),
        throwsA(isA<RuntimeError>()),
      );
      expect(
        () => executeTestScript("var list = Uint8List(2); return list[-1];"),
        throwsA(isA<RuntimeError>()),
      );
    });
  });
}
