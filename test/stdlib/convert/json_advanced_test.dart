import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('Advanced JSON Encoding & Decoding stdlib tests', () {
    test('JsonEncoder.withIndent formats multiline indented json', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:convert';

        main() {
          final data = {'name': 'd4rt', 'version': 1};
          final indented = JsonEncoder.withIndent('  ').convert(data);
          final indented4 = JsonEncoder.withIndent('    ').convert(data);
          return [indented.contains('\\n  "name"'), indented4.contains('\\n    "version"')];
        }
      ''') as List;

      expect(result[0], isTrue);
      expect(result[1], isTrue);
    });

    test('jsonEncode automatically serializes InterpretedInstance with toJson() method', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:convert';

        class User {
          final String name;
          final int age;
          User(this.name, this.age);

          Map<String, dynamic> toJson() => {'name': name, 'age': age};
        }

        main() {
          final u = User('Alice', 30);
          final jsonStr = jsonEncode(u);
          final decoded = jsonDecode(jsonStr);
          return [decoded['name'], decoded['age']];
        }
      ''') as List;

      expect(result[0], equals('Alice'));
      expect(result[1], equals(30));
    });

    test('jsonDecode with reviver converts values', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:convert';

        main() {
          final jsonStr = '{"count": 10, "label": "test"}';
          final decoded = jsonDecode(jsonStr, reviver: (key, value) {
            if (key == 'count') return value * 2;
            return value;
          });
          return decoded['count'];
        }
      ''');

      expect(result, equals(20));
    });
  });
}
