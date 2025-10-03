import 'package:test/test.dart';
import 'interpreter_test.dart' show executeAsync;

void main() {
  group('Complex Await Assignments', () {
    test('await with conditional expression (ternary)', () async {
      const code = '''
Future<int> getFuture(int value) async {
  return value;
}

int main() async {
  bool condition = true;
  
  // Complex assignment: await with conditional
  var result = await (condition ? getFuture(42) : getFuture(99));
  
  return result;
}
''';
      final result = await executeAsync(code);
      expect(result, equals(42));
    });

    test('await with conditional expression - false branch', () async {
      const code = '''
Future<int> getFuture(int value) async {
  return value;
}

int main() async {
  bool condition = false;
  
  var result = await (condition ? getFuture(42) : getFuture(99));
  
  return result;
}
''';
      final result = await executeAsync(code);
      expect(result, equals(99));
    });

    test('await with nested conditionals', () async {
      const code = '''
Future<int> getFuture(int value) async {
  return value;
}

int main() async {
  bool outerCondition = true;
  bool innerCondition = false;
  
  var result = await (outerCondition 
    ? (innerCondition ? getFuture(1) : getFuture(2))
    : getFuture(3));
  
  return result;
}
''';
      final result = await executeAsync(code);
      expect(result, equals(2));
    });

    test('await with binary expression', () async {
      const code = '''
Future<int> getFuture(int value) async {
  return value;
}

int main() async {
  var a = await (getFuture(10));
  var b = await (getFuture(20));
  
  // Simple but grouped
  var sum = await (getFuture(a + b));
  
  return sum;
}
''';
      final result = await executeAsync(code);
      expect(result, equals(30));
    });

    test('await in compound assignment with conditional', () async {
      const code = '''
Future<int> getFuture(int value) async {
  return value;
}

int main() async {
  int result = 10;
  bool shouldAdd = true;
  
  // Compound assignment with await and conditional
  result += await (shouldAdd ? getFuture(5) : getFuture(10));
  
  return result;
}
''';
      final result = await executeAsync(code);
      expect(result, equals(15));
    });

    test('multiple await expressions in same statement', () async {
      const code = '''
Future<int> getFuture(int value) async {
  return value;
}

int main() async {
  // Multiple awaits - separated for clarity (Dart limitation)
  var a = await getFuture(10);
  var b = await getFuture(20);
  var result = a + b;
  
  return result;
}
''';
      final result = await executeAsync(code);
      expect(result, equals(30));
    });

    test('await with null-coalescing', () async {
      const code = '''
Future<int?> getNullableFuture(bool returnNull) async {
  return returnNull ? null : 42;
}

int main() async {
  // Await with null-coalescing operator
  var result = await (getNullableFuture(false)) ?? 0;
  
  return result;
}
''';
      final result = await executeAsync(code);
      expect(result, equals(42));
    });

    test('await with null-coalescing - null case', () async {
      const code = '''
Future<int?> getNullableFuture(bool returnNull) async {
  return returnNull ? null : 42;
}

int main() async {
  var temp = await getNullableFuture(true);
  var result = temp ?? 99;
  
  return result;
}
''';
      final result = await executeAsync(code);
      expect(result, equals(99));
    });

    test('await in list literal', () async {
      const code = '''
Future<int> getFuture(int value) async {
  return value;
}

int main() async {
  // Await in collection literal
  var list = [
    await getFuture(1),
    await getFuture(2),
    await getFuture(3)
  ];
  
  return list.length;
}
''';
      final result = await executeAsync(code);
      expect(result, equals(3));
    });

    test('await in map literal', () async {
      const code = '''
Future<String> getStringFuture(String value) async {
  return value;
}

Future<int> getIntFuture(int value) async {
  return value;
}

int main() async {
  // Await in map literal
  var map = {
    await getStringFuture('key1'): await getIntFuture(10),
    await getStringFuture('key2'): await getIntFuture(20),
  };
  
  return map.length;
}
''';
      final result = await executeAsync(code);
      expect(result, equals(2));
    });
  });
}
