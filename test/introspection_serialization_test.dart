import 'dart:convert';
import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('Introspection serialization tests', () {
    test('IntrospectionResult toMap and toJson', () {
      final d4rt = D4rt();
      final result = d4rt.analyze(source: '''
        int add(int a, int b) => a + b;

        class Person {
          String name;
          Person(this.name);
          void greet() {}
        }

        enum Status { active, pending }

        extension StringExt on String {
          int get len => length;
        }

        const appVersion = '1.0.0';
      ''');

      final map = result.toMap();
      final jsonStr = result.toJson();
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(map['functions'], isNotEmpty);
      expect(map['classes'], isNotEmpty);
      expect(map['enums'], isNotEmpty);
      expect(map['extensions'], isNotEmpty);
      expect(map['variables'], isNotEmpty);

      final funcNames =
          (decoded['functions'] as List).map((f) => f['name']).toList();
      final classNames =
          (decoded['classes'] as List).map((c) => c['name']).toList();
      final enumNames =
          (decoded['enums'] as List).map((e) => e['name']).toList();
      final extNames =
          (decoded['extensions'] as List).map((e) => e['name']).toList();
      final varNames =
          (decoded['variables'] as List).map((v) => v['name']).toList();

      expect(funcNames, contains('add'));
      expect(classNames, contains('Person'));
      expect(enumNames, contains('Status'));
      expect(extNames, contains('StringExt'));
      expect(varNames, contains('appVersion'));
    });
  });
}
