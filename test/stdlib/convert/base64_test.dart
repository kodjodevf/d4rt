import '../../interpreter_test.dart';
import 'package:test/test.dart';

void main() {
  group('Base64 methods - comprehensive', () {
    test('Base64Codec encode', () {
      const source = '''
      import 'dart:convert';
      main() {
        Base64Codec codec = Base64Codec();
        return codec.encode([104, 101, 108, 108, 111]); // "hello"
      }
      ''';
      expect(execute(source), equals('aGVsbG8='));
    });

    test('Base64Codec decode', () {
      const source = '''
      import 'dart:convert';
      main() {
        Base64Codec codec = Base64Codec();
        return codec.decode("aGVsbG8="); // "hello"
      }
      ''';
      expect(execute(source), equals([104, 101, 108, 108, 111]));
    });

    test('Base64Encoder convert', () {
      const source = '''
      import 'dart:convert';
      main() {
        Base64Encoder encoder = Base64Encoder();
        return encoder.convert([104, 101, 108, 108, 111]); // "hello"
      }
      ''';
      expect(execute(source), equals('aGVsbG8='));
    });

    test('Base64Decoder convert', () {
      const source = '''
      import 'dart:convert';
      main() {
        Base64Decoder decoder = Base64Decoder();
        return decoder.convert("aGVsbG8="); // "hello"
      }
      ''';
      expect(execute(source), equals([104, 101, 108, 108, 111]));
    });

    test('Base64Codec normalize', () {
      const source = '''
      import 'dart:convert';
      main() {
        Base64Codec codec = Base64Codec();
        return codec.normalize("aGVsbG8="); // "aGVsbG8="
      }
      ''';
      expect(execute(source), equals('aGVsbG8='));
    });
  });
}
