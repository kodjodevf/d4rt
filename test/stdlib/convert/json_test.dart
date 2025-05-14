import '../../interpreter_test.dart';
import 'package:test/test.dart';

void main() {
  group('Json tests', () {
    test('JsonCodec encode and decode', () {
      const source = '''
      import 'dart:convert';
      main() {
        JsonCodec codec = JsonCodec();
        Map<String, dynamic> data = {"key": "value", "number": 42};
        String encoded = codec.encode(data);
        Map<String, dynamic> decoded = codec.decode(encoded);
        return [encoded, decoded];
      }
      ''';
      final result = execute(source) as List;
      expect(result[0], equals('{"key":"value","number":42}'));
      expect(result[1], equals({"key": "value", "number": 42}));
    });

    test('JsonEncoder convert', () {
      const source = '''
      import 'dart:convert';
      main() {
        JsonEncoder encoder = JsonEncoder();
        Map<String, dynamic> data = {"key": "value", "number": 42};
        String encoded = encoder.convert(data);
        return encoded;
      }
      ''';
      expect(execute(source), equals('{"key":"value","number":42}'));
    });

    test('JsonDecoder convert', () {
      const source = '''
      import 'dart:convert';
      main() {
        JsonDecoder decoder = JsonDecoder();
        String json = '{"key":"value","number":42}';
        Map<String, dynamic> decoded = decoder.convert(json);
        return decoded;
      }
      ''';
      expect(execute(source), equals({"key": "value", "number": 42}));
    });

    test('jsonEncode', () {
      const source = '''
      import 'dart:convert';
      main() {
        Map<String, dynamic> data = {"key": "value", "number": 42};
        String encoded = jsonEncode(data);
        return encoded;
      }
      ''';
      expect(execute(source), equals('{"key":"value","number":42}'));
    });

    test('jsonDecode', () {
      const source = '''
      import 'dart:convert';
      main() {
        String json = '{"key":"value","number":42}';
        Map<String, dynamic> decoded = jsonDecode(json);
        return decoded;
      }
      ''';
      expect(execute(source), equals({"key": "value", "number": 42}));
    });

    test('jsonEncode with toEncodable', () {
      const source = '''
      import 'dart:convert';
      main() {
        Map<String, dynamic> data = {"key": "value", "date": DateTime(2023, 1, 1)};
        String encoded = jsonEncode(data, toEncodable: (nonEncodable) {
          if (nonEncodable is DateTime) {
            return nonEncodable.toIso8601String();
          }
          return nonEncodable.toString();
        });
        return encoded;
      }
      ''';
      expect(execute(source), contains('"key":"value"'));
      expect(execute(source), contains('"date":"2023-01-01T00:00:00.000'));
    });

    test('jsonDecode with reviver', () {
      const source = '''
      import 'dart:convert';
      main() {
        String json = '{"key":"value","date":"2023-01-01T00:00:00.000Z"}';
        Map<String, dynamic> decoded = jsonDecode(json, reviver: (key, value) {
          if (key == "date") {
            return DateTime.parse(value);
          }
          return value;
        });
        return decoded;
      }
      ''';
      final result = execute(source) as Map;
      expect(result['key'], equals('value'));
      expect(result['date'], isA<DateTime>());
      expect((result['date'] as DateTime).isUtc, isTrue);
      expect((result['date'] as DateTime).year, equals(2023));
    });

    test('JsonCodec with toEncodable and reviver', () {
      const source = '''
      import 'dart:convert';
      main() {
        JsonCodec codec = JsonCodec(
          toEncodable: (nonEncodable) {
            if (nonEncodable is DateTime) {
              return nonEncodable.toIso8601String();
            }
            return nonEncodable.toString();
          },
          reviver: (key, value) {
            if (key == "date" && value is String) {
              return DateTime.parse(value);
            }
            return value;
          },
        );
        Map<String, dynamic> data = {"key": "value", "date": DateTime.utc(2023, 1, 1)};
        String encoded = codec.encode(data);
        Map<String, dynamic> decoded = codec.decode(encoded);
        return [encoded, decoded];
      }
      ''';
      final result = execute(source) as List;
      expect(result[0],
          equals('{"key":"value","date":"2023-01-01T00:00:00.000Z"}'));
      final decodedMap = result[1] as Map;
      expect(decodedMap['key'], equals('value'));
      expect(decodedMap['date'], isA<DateTime>());
      expect((decodedMap['date'] as DateTime).isUtc, isTrue);
      expect((decodedMap['date'] as DateTime).year, equals(2023));
    });
  });
}
