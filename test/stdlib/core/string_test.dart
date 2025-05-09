import '../../interpreter_test.dart';
import 'package:test/test.dart';

void main() {
  group('String methods - comprehensive', () {
    test('substring', () {
      const source = '''
      main() {
        String text = "hello world";
        return text.substring(0, 5);
      }
      ''';
      expect(execute(source), equals('hello'));
    });

    test('toUpperCase', () {
      const source = '''
      main() {
        String text = "hello";
        return text.toUpperCase();
      }
      ''';
      expect(execute(source), equals('HELLO'));
    });

    test('toLowerCase', () {
      const source = '''
      main() {
        String text = "HELLO";
        return text.toLowerCase();
      }
      ''';
      expect(execute(source), equals('hello'));
    });

    test('contains', () {
      const source = '''
      main() {
        String text = "hello world";
        return [text.contains("world"), text.contains("dart")];
      }
      ''';
      expect(execute(source), equals([true, false]));
    });

    test('startsWith', () {
      const source = '''
      main() {
        String text = "hello world";
        return [text.startsWith("hello"), text.startsWith("world")];
      }
      ''';
      expect(execute(source), equals([true, false]));
    });

    test('endsWith', () {
      const source = '''
      main() {
        String text = "hello world";
        return [text.endsWith("world"), text.endsWith("hello")];
      }
      ''';
      expect(execute(source), equals([true, false]));
    });

    test('indexOf', () {
      const source = '''
      main() {
        String text = "hello world";
        return [text.indexOf("world"), text.indexOf("dart")];
      }
      ''';
      expect(execute(source), equals([6, -1]));
    });

    test('lastIndexOf', () {
      const source = '''
      main() {
        String text = "hello world world";
        return text.lastIndexOf("world");
      }
      ''';
      expect(execute(source), equals(12));
    });

    test('trim', () {
      const source = '''
      main() {
        String text = "  hello world  ";
        return text.trim();
      }
      ''';
      expect(execute(source), equals('hello world'));
    });

    test('replaceAll', () {
      const source = '''
      main() {
        String text = "hello world";
        return text.replaceAll("world", "dart");
      }
      ''';
      expect(execute(source), equals('hello dart'));
    });

    test('split', () {
      const source = '''
      main() {
        String text = "hello world";
        return text.split(" ");
      }
      ''';
      expect(execute(source), equals(['hello', 'world']));
    });

    test('padLeft', () {
      const source = '''
      main() {
        String text = "hello";
        return text.padLeft(10, "-");
      }
      ''';
      expect(execute(source), equals('-----hello'));
    });

    test('padRight', () {
      const source = '''
      main() {
        String text = "hello";
        return text.padRight(10, "-");
      }
      ''';
      expect(execute(source), equals('hello-----'));
    });

    test('replaceFirst', () {
      const source = '''
      main() {
        String text = "hello world";
        return text.replaceFirst("world", "dart");
      }
      ''';
      expect(execute(source), equals('hello dart'));
    });

    test('replaceRange', () {
      const source = '''
      main() {
        String text = "hello world";
        return text.replaceRange(6, 11, "dart");
      }
      ''';
      expect(execute(source), equals('hello dart'));
    });

    test('codeUnitAt', () {
      const source = '''
      main() {
        String text = "hello";
        return text.codeUnitAt(0);
      }
      ''';
      expect(execute(source), equals(104));
    });

    test('toString', () {
      const source = '''
      main() {
        String text = "hello";
        return text.toString();
      }
      ''';
      expect(execute(source), equals('hello'));
    });

    test('compareTo', () {
      const source = '''
      main() {
        String text = "hello";
        return [text.compareTo("hello"), text.compareTo("world")];
      }
      ''';
      expect(execute(source), equals([0, -1]));
    });

    test('isEmpty and isNotEmpty', () {
      const source = '''
      main() {
        String text = "";
        return [text.isEmpty, text.isNotEmpty];
      }
      ''';
      expect(execute(source), equals([true, false]));
    });

    test('length', () {
      const source = '''
      main() {
        String text = "hello";
        return text.length;
      }
      ''';
      expect(execute(source), equals(5));
    });

    test('codeUnits', () {
      const source = '''
      main() {
        String text = "hello";
        return text.codeUnits;
      }
      ''';
      expect(execute(source), equals([104, 101, 108, 108, 111]));
    });

    test('runes', () {
      const source = '''
      main() {
        String text = "hello";
        return text.runes.toList();
      }
      ''';
      expect(execute(source), equals([104, 101, 108, 108, 111]));
    });

    test('replaceAllMapped', () {
      const source = '''
      main() {
        String text = "hello world";
        return text.replaceAllMapped("world", (match) => "dart");
      }
      ''';
      expect(execute(source), equals('hello dart'));
    });

    test('replaceFirstMapped', () {
      const source = '''
      main() {
        String text = "hello world world";
        return text.replaceFirstMapped("world", (match) => "dart");
      }
      ''';
      expect(execute(source), equals('hello dart world'));
    });

    test('fromCharCode', () {
      const source = '''
      main() {
        return String.fromCharCode(104);
      }
      ''';
      expect(execute(source), equals('h'));
    });

    test('fromCharCodes', () {
      const source = '''
      main() {
        return String.fromCharCodes([104, 101, 108, 108, 111]);
      }
      ''';
      expect(execute(source), equals('hello'));
    });

    test('fromEnvironment', () {
      const source = '''
      main() {
        return String.fromEnvironment("key", defaultValue: "default");
      }
      ''';
      expect(execute(source), equals('default'));
    });
  });
}
