import 'package:test/test.dart';
import '../interpreter_test.dart';

void main() {
  group('Bridged Static Method as Value', () {
    test('can pass bridged static method as value - int.parse', () {
      const code = '''
int main() {
  // Get the static method as a value
  var parseFunc = int.parse;
  
  // Call it with a string
  var result = parseFunc('42');
  
  return result; // 42
}
''';
      final result = execute(code);
      expect(result, equals(42));
    });

    test('can pass bridged static method to higher-order function', () {
      const code = '''
int applyToString(Function f, String s) {
  return f(s);
}

int main() {
  // Pass int.parse as a function value
  return applyToString(int.parse, '100');
}
''';
      final result = execute(code);
      expect(result, equals(100));
    });

    test('can store bridged static methods in collections', () {
      const code = '''
int main() {
  // Store static methods in a list
  var parsers = [int.parse, double.parse];
  
  // Call them
  var intResult = parsers[0]('42');
  var doubleResult = parsers[1]('3.14');
  
  return intResult + doubleResult.toInt();
}
''';
      final result = execute(code);
      expect(result, equals(45)); // 42 + 3
    });

    test('can map with bridged static method', () {
      const code = '''
int main() {
  var strings = ['1', '2', '3'];
  var numbers = strings.map(int.parse).toList();
  
  return numbers.length;
}
''';
      final result = execute(code);
      expect(result, equals(3));
    });

    test('can use multiple bridged static methods', () {
      const code = '''
import 'dart:math';

int main() {
  // Get static methods as values
  var maxFunc = max;
  var minFunc = min;
  
  var maxResult = maxFunc(10, 20);
  var minResult = minFunc(10, 20);
  
  return maxResult + minResult;
}
''';
      final result = execute(code);
      expect(result, equals(30)); // 20 + 10
    });
  });
}
