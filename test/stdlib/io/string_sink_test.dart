import '../../interpreter_test.dart';
import 'package:test/test.dart';

void main() {
  group('StringSink methods - comprehensive', () {
    test('StringSink write method with StringBuffer', () {
      const source = '''
     import 'dart:core';
     main() {
        var buffer = StringBuffer();
        buffer.write('Hello');
        buffer.write(' ');
        buffer.write('World');
        return buffer.toString();
      }
      ''';
      final result = execute(source);
      expect(result, equals('Hello World'));
    });

    test('StringSink writeln method with StringBuffer', () {
      const source = '''
     import 'dart:core';
     main() {
        var buffer = StringBuffer();
        buffer.writeln('Line 1');
        buffer.writeln('Line 2');
        buffer.write('Line 3');
        return buffer.toString();
      }
      ''';
      final result = execute(source);
      expect(result, equals('Line 1\nLine 2\nLine 3'));
    });

    test('StringSink writeln with no arguments', () {
      const source = '''
     import 'dart:core';
     main() {
        var buffer = StringBuffer();
        buffer.write('Before');
        buffer.writeln();
        buffer.write('After');
        return buffer.toString();
      }
      ''';
      final result = execute(source);
      expect(result, equals('Before\nAfter'));
    });

    test('StringSink writeAll method with list', () {
      const source = '''
     import 'dart:core';
     main() {
        var buffer = StringBuffer();
        var items = ['A', 'B', 'C', 'D'];
        buffer.writeAll(items);
        return buffer.toString();
      }
      ''';
      final result = execute(source);
      expect(result, equals('ABCD'));
    });

    test('StringSink writeAll method with separator', () {
      const source = '''
     import 'dart:core';
     main() {
        var buffer = StringBuffer();
        var items = ['Apple', 'Banana', 'Cherry'];
        buffer.writeAll(items, ', ');
        return buffer.toString();
      }
      ''';
      final result = execute(source);
      expect(result, equals('Apple, Banana, Cherry'));
    });

    test('StringSink writeCharCode method', () {
      const source = '''
     import 'dart:core';
     main() {
        var buffer = StringBuffer();
        buffer.writeCharCode(72);  // 'H'
        buffer.writeCharCode(101); // 'e'
        buffer.writeCharCode(108); // 'l'
        buffer.writeCharCode(108); // 'l'
        buffer.writeCharCode(111); // 'o'
        return buffer.toString();
      }
      ''';
      final result = execute(source);
      expect(result, equals('Hello'));
    });

    test('StringSink write with different data types', () {
      const source = '''
     import 'dart:core';
     main() {
        var buffer = StringBuffer();
        buffer.write(42);
        buffer.write(' ');
        buffer.write(3.14);
        buffer.write(' ');
        buffer.write(true);
        buffer.write(' ');
        buffer.write(null);
        return buffer.toString();
      }
      ''';
      final result = execute(source);
      expect(result, equals('42 3.14 true null'));
    });

    test('StringSink writeAll with mixed types', () {
      const source = '''
     import 'dart:core';
     main() {
        var buffer = StringBuffer();
        var items = [1, 2.5, 'text', true, null];
        buffer.writeAll(items, '|');
        return buffer.toString();
      }
      ''';
      final result = execute(source);
      expect(result, equals('1|2.5|text|true|null'));
    });

    test('StringSink complex usage with multiple operations', () {
      const source = '''
     import 'dart:core';
     main() {
        var buffer = StringBuffer();
        
        // Header
        buffer.writeln('=== Report ===');
        buffer.writeln();
        
        // Content
        buffer.write('Items: ');
        buffer.writeAll(['Item1', 'Item2', 'Item3'], ', ');
        buffer.writeln();
        
        // Numbers
        buffer.write('Numbers: ');
        for (int i = 1; i <= 3; i++) {
          if (i > 1) buffer.write(', ');
          buffer.write(i);
        }
        buffer.writeln();
        
        // Footer
        buffer.writeln();
        buffer.writeCharCode(45); // '-'
        buffer.writeCharCode(45); // '-'
        buffer.writeCharCode(45); // '-'
        buffer.writeln(' END');
        
        return buffer.toString();
      }
      ''';
      final result = execute(source);
      final expected =
          '=== Report ===\n\nItems: Item1, Item2, Item3\nNumbers: 1, 2, 3\n\n--- END\n';
      expect(result, equals(expected));
    });

    test('StringSink isEmpty and isNotEmpty properties', () {
      const source = '''
     import 'dart:core';
     main() {
        var buffer = StringBuffer();
        var empty1 = buffer.isEmpty;
        var notEmpty1 = buffer.isNotEmpty;
        
        buffer.write('content');
        var empty2 = buffer.isEmpty;
        var notEmpty2 = buffer.isNotEmpty;
        
        return [empty1, notEmpty1, empty2, notEmpty2];
      }
      ''';
      final result = execute(source);
      expect(result, equals([true, false, false, true]));
    });

    test('StringSink length property', () {
      const source = '''
     import 'dart:core';
     main() {
        var buffer = StringBuffer();
        var len1 = buffer.length;
        
        buffer.write('Hello');
        var len2 = buffer.length;
        
        buffer.write(' World');
        var len3 = buffer.length;
        
        return [len1, len2, len3];
      }
      ''';
      final result = execute(source);
      expect(result, equals([0, 5, 11]));
    });

    test('StringSink clear method', () {
      const source = '''
     import 'dart:core';
     main() {
        var buffer = StringBuffer();
        buffer.write('This will be cleared');
        
        var before = buffer.toString();
        buffer.clear();
        var after = buffer.toString();
        
        buffer.write('New content');
        var final_content = buffer.toString();
        
        return [before, after, final_content];
      }
      ''';
      final result = execute(source);
      expect(result, equals(['This will be cleared', '', 'New content']));
    });
  });
}
