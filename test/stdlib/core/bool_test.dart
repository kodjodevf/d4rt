import '../../interpreter_test.dart';
import 'package:test/test.dart';

void main() {
  group('bool tests', () {
    test('bool.parse', () {
      const source = '''
      main() {
        bool value1 = bool.parse("true");
        bool value2 = bool.parse("false");
        return [value1, value2];
      }
      ''';
      expect(execute(source), equals([true, false]));
    });

    test('bool.tryParse', () {
      const source = '''
      main() {
        bool? value1 = bool.tryParse("true");
        bool? value2 = bool.tryParse("false");
        bool? value3 = bool.tryParse("invalid");
        return [value1, value2, value3];
      }
      ''';
      expect(execute(source), equals([true, false, null]));
    });

    test('bool.toString', () {
      const source = '''
      main() {
        bool value1 = true;
        bool value2 = false;
        return [value1.toString(), value2.toString()];
      }
      ''';
      expect(execute(source), equals(['true', 'false']));
    });

    test('bool.hashCode', () {
      const source = '''
      main() {
        bool value1 = true;
        bool value2 = false;
        return [value1.hashCode, value2.hashCode];
      }
      ''';
      final result = execute(source) as List;
      expect(result[0], isA<int>());
      expect(result[1], isA<int>());
      expect(result[0], isNot(equals(result[1])));
    });

    test('bool logical operators', () {
      const source = '''
      main() {
        bool value1 = true;
        bool value2 = false;
        return [value1 && value2, value1 || value2, !value1];
      }
      ''';
      expect(execute(source), equals([false, true, false]));
    });

    test('bool equality', () {
      const source = '''
      main() {
        bool value1 = true;
        bool value2 = false;
        return [value1 == value2, value1 != value2];
      }
      ''';
      expect(execute(source), equals([false, true]));
    });

    test('bool.parse with caseSensitive', () {
      const source = '''
      main() {
        bool value1 = bool.parse("TRUE", caseSensitive: false);
        bool value2 = bool.parse("FALSE", caseSensitive: false);
        return [value1, value2];
      }
      ''';
      expect(execute(source), equals([true, false]));
    });

    test('bool.tryParse with caseSensitive', () {
      const source = '''
      main() {
        bool? value1 = bool.tryParse("TRUE", caseSensitive: false);
        bool? value2 = bool.tryParse("FALSE", caseSensitive: false);
        bool? value3 = bool.tryParse("INVALID", caseSensitive: false);
        return [value1, value2, value3];
      }
      ''';
      expect(execute(source), equals([true, false, null]));
    });
  });
}
