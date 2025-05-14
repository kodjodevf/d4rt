import '../../interpreter_test.dart';
import 'package:test/test.dart';

void main() {
  group('Encoding tests', () {
    test('utf8 encode and decode', () {
      const source = '''
      import 'dart:convert';
      main() {
        Encoding encoding = utf8;
        String original = "Hello, UTF-8!";
        List<int> encoded = encoding.encode(original);
        String decoded = encoding.decode(encoded);
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

    test('ascii encode and decode', () {
      const source = '''
      import 'dart:convert';
      main() {
        Encoding encoding = ascii;
        String original = "Hello, ASCII!";
        List<int> encoded = encoding.encode(original);
        String decoded = encoding.decode(encoded);
        return [encoded, decoded];
      }
      ''';
      expect(
          execute(source),
          equals([
            [72, 101, 108, 108, 111, 44, 32, 65, 83, 67, 73, 73, 33],
            'Hello, ASCII!'
          ]));
    });

    test('latin1 encode and decode', () {
      const source = '''
      import 'dart:convert';
      main() {
        Encoding encoding = latin1;
        String original = "Hello, Latin1!";
        List<int> encoded = encoding.encode(original);
        String decoded = encoding.decode(encoded);
        return [encoded, decoded];
      }
      ''';
      expect(
          execute(source),
          equals([
            [72, 101, 108, 108, 111, 44, 32, 76, 97, 116, 105, 110, 49, 33],
            'Hello, Latin1!'
          ]));
    });

    test('utf8 decoder', () {
      const source = '''
      import 'dart:convert';
      main() {
        Encoding encoding = utf8;
        return encoding.decoder.runtimeType.toString();
      }
      ''';
      expect(execute(source), equals('Utf8Decoder'));
    });

    test('ascii decoder', () {
      const source = '''
      import 'dart:convert';
      main() {
        Encoding encoding = ascii;
        return encoding.decoder.runtimeType.toString();
      }
      ''';
      expect(execute(source), equals('AsciiDecoder'));
    });

    test('latin1 decoder', () {
      const source = '''
      import 'dart:convert';
      main() {
        Encoding encoding = latin1;
        return encoding.decoder.runtimeType.toString();
      }
      ''';
      expect(execute(source), equals('Latin1Decoder'));
    });

    test('utf8 encoder', () {
      const source = '''
      import 'dart:convert';
      main() {
        Encoding encoding = utf8;
        return encoding.encoder.runtimeType.toString();
      }
      ''';
      expect(execute(source), equals('Utf8Encoder'));
    });

    test('ascii encoder', () {
      const source = '''
      import 'dart:convert';
      main() {
        Encoding encoding = ascii;
        return encoding.encoder.runtimeType.toString();
      }
      ''';
      expect(execute(source), equals('AsciiEncoder'));
    });

    test('latin1 encoder', () {
      const source = '''
      import 'dart:convert';
      main() {
        Encoding encoding = latin1;
        return encoding.encoder.runtimeType.toString();
      }
      ''';
      expect(execute(source), equals('Latin1Encoder'));
    });
  });
}
