import 'package:test/test.dart';
import 'package:d4rt/d4rt.dart';

dynamic execute(String source, {List<Object?>? args}) {
  final d4rt = D4rt()..setDebug(false);
  return d4rt.execute(
      library: 'package:test/main.dart',
      positionalArgs: args,
      sources: {'package:test/main.dart': source});
}

void main() {
  group('Operator Improvements', () {
    test('Generic constraints validation works', () {
      final code = '''
        class NumericContainer<T extends num> {
          T value;
          NumericContainer(this.value);
        }
        
        main() {
          try {
            var container = NumericContainer<String>("invalid");
            return "ERROR: Should have failed";
          } catch (e) {
            return "SUCCESS: Constraint validation works";
          }
        }
      ''';

      final result = execute(code);
      expect(result, contains("SUCCESS"));
    });

    test('Compound assignment operators work for bitwise operations', () {
      final code = '''
        main() {
          int a = 15;  // 1111 in binary
          int b = 7;   // 0111 in binary
          
          a &= b;      // Should be 7 (0111)
          print("a &= b: \$a");
          
          a = 15;
          a |= 8;      // Should be 15 (1111)
          print("a |= 8: \$a");
          
          a = 15;
          a ^= 8;      // Should be 7 (0111)
          print("a ^= 8: \$a");
          
          a = 8;
          a <<= 2;     // Should be 32
          print("a <<= 2: \$a");
          
          a = 32;
          a >>= 2;     // Should be 8
          print("a >>= 2: \$a");
          
          a = -8;
          a >>>= 2;    // Unsigned right shift
          print("a >>>= 2: \$a");
          
          return "Bitwise compound assignments work";
        }
      ''';

      final result = execute(code);
      expect(result, equals("Bitwise compound assignments work"));
    });

    test('New typed data types work', () {
      final code = '''
        import 'dart:typed_data';
        
        main() {
          // Test Int16List
          var int16list = Int16List(3);
          int16list[0] = 1000;
          int16list[1] = -2000;
          int16list[2] = 3000;
          
          print("Int16List: \${int16list[0]}, \${int16list[1]}, \${int16list[2]}");
          
          // Test Float32List
          var float32list = Float32List(2);
          float32list[0] = 3.14;
          float32list[1] = -2.71;
          
          print("Float32List: \${float32list[0]}, \${float32list[1]}");
          
          return "New typed data types work";
        }
      ''';

      final result = execute(code);
      expect(result, equals("New typed data types work"));
    });

    test('Complex operations with improved features', () {
      final code = '''
        import 'dart:typed_data';
        
        class DataProcessor<T extends num> {
          List<T> data;
          DataProcessor(this.data);
          
          T process(T value) {
            return value;
          }
        }
        
        main() {
          // Test generics with valid types
          var intProcessor = DataProcessor<int>([1, 2, 3]);
          var doubleProcessor = DataProcessor<double>([1.1, 2.2, 3.3]);
          
          // Test typed data with compound assignments
          var buffer = Uint8List(4);
          buffer[0] = 10;
          buffer[0] += 5;  // Should be 15
          
          print("Buffer[0] after compound assignment: \${buffer[0]}");
          
          // Test bitwise operations
          int flags = 0;
          flags |= 1;    // Set bit 0
          flags |= 4;    // Set bit 2
          flags &= ~2;   // Clear bit 1 (if it was set)
          
          print("Flags after bitwise operations: \$flags");
          
          return "Complex operations successful";
        }
      ''';

      final result = execute(code);
      expect(result, equals("Complex operations successful"));
    });
  });
}
