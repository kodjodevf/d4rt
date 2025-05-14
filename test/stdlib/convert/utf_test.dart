import '../../interpreter_test.dart';
import 'package:test/test.dart';

void main() {
  group('Utf8 tests', () {
    test('Utf8Codec encode and decode', () {
      const source = '''
      import 'dart:convert';
      main() {
        Utf8Codec codec = Utf8Codec();
        String original = "Hello, UTF-8!";
        List<int> encoded = codec.encode(original);
        String decoded = codec.decode(encoded);
        return [encoded, decoded];
      }
      ''';
      expect(
          execute(source),
          equals([
            [72, 101, 108, 108, 111, 44, 32, 85, 84, 70, 45, 56, 33],
            'Hello, UTF-8!'
          ]));
    });

    test('Utf8Encoder convert', () {
      const source = '''
      import 'dart:convert';
      main() {
        Utf8Encoder encoder = Utf8Encoder();
        String original = "Encode this!";
        List<int> encoded = encoder.convert(original);
        return encoded;
      }
      ''';
      expect(execute(source),
          equals([69, 110, 99, 111, 100, 101, 32, 116, 104, 105, 115, 33]));
    });

    test('Utf8Decoder convert', () {
      const source = '''
      import 'dart:convert';
      main() {
        Utf8Decoder decoder = Utf8Decoder();
        List<int> encoded = [68, 101, 99, 111, 100, 101, 32, 116, 104, 105, 115, 33];
        String decoded = decoder.convert(encoded);
        return decoded;
      }
      ''';
      expect(execute(source), equals('Decode this!'));
    });
  });
}
