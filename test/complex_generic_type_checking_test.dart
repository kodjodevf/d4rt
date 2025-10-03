import 'package:test/test.dart';
import 'interpreter_test.dart';

void main() {
  group('Complex Generic Type Checking', () {
    test('simple generic List type checking', () {
      const code = '''
int main() {
  var list = [1, 2, 3];
  
  // Basic List check should work
  if (list is List) {
    return 1;
  }
  return 0;
}
''';
      final result = execute(code);
      expect(result, equals(1));
    });

    test('simple generic Map type checking', () {
      const code = '''
int main() {
  var map = {'a': 1, 'b': 2};
  
  // Basic Map check should work
  if (map is Map) {
    return 1;
  }
  return 0;
}
''';
      final result = execute(code);
      expect(result, equals(1));
    });

    test('generic List<int> type checking', () {
      const code = '''
int main() {
  var list = [1, 2, 3];
  
  // Check if it's a List<int>
  if (list is List<int>) {
    return 1;
  }
  return 0;
}
''';
      final result = execute(code);
      expect(result, equals(1));
    });

    test('generic Map<String, int> type checking', () {
      const code = '''
int main() {
  var map = {'a': 1, 'b': 2};
  
  // Check if it's a Map<String, int>
  if (map is Map<String, int>) {
    return 1;
  }
  return 0;
}
''';
      final result = execute(code);
      expect(result, equals(1));
    });

    test('nested generic Map<String, List<int>> type checking', () {
      const code = '''
int main() {
  var map = {
    'a': [1, 2, 3],
    'b': [4, 5, 6]
  };
  
  // Check if it's a Map<String, List<int>>
  if (map is Map<String, List<int>>) {
    return 1;
  }
  return 0;
}
''';
      final result = execute(code);
      expect(result, equals(1));
    });

    test('negative type check - List<String> is not List<int>', () {
      const code = '''
int main() {
  var list = ['a', 'b', 'c'];
  
  // Should NOT be List<int>
  if (list is! List<int>) {
    return 1;
  }
  return 0;
}
''';
      final result = execute(code);
      expect(result, equals(1));
    });

    test('complex nested generic List<Map<String, int>> type checking', () {
      const code = '''
int main() {
  var list = [
    {'a': 1, 'b': 2},
    {'c': 3, 'd': 4}
  ];
  
  // Check if it's a List<Map<String, int>>
  if (list is List<Map<String, int>>) {
    return 1;
  }
  return 0;
}
''';
      final result = execute(code);
      expect(result, equals(1));
    });

    test(
        'triple nested generic Map<String, List<Map<String, int>>> type checking',
        () {
      const code = '''
int main() {
  var complexMap = {
    'group1': [
      {'a': 1, 'b': 2},
      {'c': 3}
    ],
    'group2': [
      {'d': 4, 'e': 5}
    ]
  };
  
  // Check if it's a Map<String, List<Map<String, int>>>
  if (complexMap is Map<String, List<Map<String, int>>>) {
    return 1;
  }
  return 0;
}
''';
      final result = execute(code);
      expect(result, equals(1));
    });

    test('type checking with nullable generics', () {
      const code = '''
int main() {
  var list = [1, null, 3];
  
  // Check if it's a List<int?>
  if (list is List<int?>) {
    return 1;
  }
  return 0;
}
''';
      final result = execute(code);
      expect(result, equals(1));
    });

    test('generic type mismatch detection', () {
      const code = '''
int main() {
  var mapOfStrings = {'a': 'hello', 'b': 'world'};
  
  // Should NOT match Map<String, int>
  if (mapOfStrings is Map<String, int>) {
    return 0;
  }
  return 1;
}
''';
      final result = execute(code);
      expect(result, equals(1));
    });
  });
}
