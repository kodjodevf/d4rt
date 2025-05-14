import 'package:test/test.dart';
import 'package:d4rt/d4rt.dart';

// 1. Define a simple native enum
enum NativeColor { red, green, blue }

// 2. Define a complex native enum
enum ComplexEnum {
  itemA('Data A', 10),
  itemB('Data B', 20);

  final String data;
  final int number;
  const ComplexEnum(this.data, this.number);

  String get info => '$data-$number';
  int multiply(int factor) => number * factor;
  bool isItemA() => this == ComplexEnum.itemA;
}

void main() {
  group('Bridged Enum Tests - Simple', () {
    late D4rt interpreter;

    setUp(() {
      interpreter = D4rt();
      // Register the simple enum
      final colorDefinition = BridgedEnumDefinition<NativeColor>(
        name: 'BridgedColor',
        values: NativeColor.values,
        // No adapters for the simple enum initially
      );
      interpreter.registerBridgedEnum(
          colorDefinition, 'package:test/color.dart');
    });

    test('Register and access bridged enum value', () {
      final code = '''
        import 'package:test/color.dart';
        var color = BridgedColor.green;
        main() { return color; }
      ''';
      final result = interpreter.execute(source: code);
      final value = result as NativeColor;
      expect(value.name, equals('green'));
      expect(value.index, equals(1));
      expect(value, equals(NativeColor.green));
    });

    test('Access standard property (.index) on bridged enum value', () {
      final code = '''
        import 'package:test/color.dart';
        main() { return BridgedColor.blue.index; }
      ''';
      final result = interpreter.execute(source: code);
      expect(result, equals(2));
    });

    test('Access toString() on bridged enum value via get', () {
      final code = '''
        import 'package:test/color.dart';
        main() {
          var color = BridgedColor.red;
          return color.toString(); // Should return 'BridgedColor.red'
        }
      ''';
      final result = interpreter.execute(source: code);
      // Ensure that the get() implementation returns the expected string
      expect(result, equals('BridgedColor.red'));
    });

    test('Call toString() method on bridged enum value', () {
      final code = '''
        import 'package:test/color.dart';
         main() {
           var color = BridgedColor.blue;
           return color.toString();
         }
       ''';
      final result = interpreter.execute(source: code);
      expect(result, equals('BridgedColor.blue'));
    });

    test('Compare bridged enum values', () {
      final code = '''
        import 'package:test/color.dart';
        main() {
          var c1 = BridgedColor.green;
          var c2 = BridgedColor.blue;
          var c3 = BridgedColor.green;
          return [c1 == c2, c1 == c3, c1 != c2];
        }
      ''';
      final result = interpreter.execute(source: code);
      expect(result, equals([false, true, true]));
    });
  });

  group('Bridged Enum Tests - Complex', () {
    late D4rt interpreter;

    setUp(() {
      interpreter = D4rt();

      // Define the adapters for ComplexEnum
      final complexEnumDefinition = BridgedEnumDefinition<ComplexEnum>(
        name: 'MyComplexEnum', // Name in the interpreter
        values: ComplexEnum.values,
        getters: {
          // Accessor for the 'data' field
          'data': (InterpreterVisitor? visitor, Object target) {
            if (target is ComplexEnum) {
              return target.data; // Return the native value
            }
            throw Exception('Target is not ComplexEnum');
          },
          // Accessor for the 'number' field
          'number': (InterpreterVisitor? visitor, Object target) {
            if (target is ComplexEnum) {
              return target.number;
            }
            throw Exception('Target is not ComplexEnum');
          },
          // Accessor for the 'info' getter
          'info': (InterpreterVisitor? visitor, Object target) {
            if (target is ComplexEnum) {
              return target.info; // Call the native getter
            }
            throw Exception('Target is not ComplexEnum');
          },
        },
        methods: {
          // Adapter for the 'multiply' method
          'multiply': (InterpreterVisitor visitor, Object target,
              List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
            if (target is ComplexEnum &&
                positionalArgs.length == 1 &&
                positionalArgs[0] is int) {
              final factor = positionalArgs[0] as int;
              return target.multiply(factor); // Calls the native method
            }
            // Provide a more specific error message
            String errorDetails;
            if (target is! ComplexEnum) {
              errorDetails =
                  'Target is not ComplexEnum (${target.runtimeType})';
            } else if (positionalArgs.length != 1) {
              errorDetails =
                  'Expected 1 argument, got ${positionalArgs.length}';
            } else {
              errorDetails =
                  'Argument must be an integer, got ${positionalArgs[0]?.runtimeType}';
            }
            throw ArgumentError(
                'Invalid arguments for multiply: $errorDetails');
          },
          // Adapter for the 'isItemA' method
          'isItemA': (InterpreterVisitor visitor, Object target,
              List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
            if (target is ComplexEnum &&
                positionalArgs.isEmpty &&
                namedArgs.isEmpty) {
              return target.isItemA(); // Calls the native method
            }
            throw ArgumentError(
                'Invalid arguments for isItemA: Expected 0 arguments');
          },
          // Adapter for 'toString'
          // This adapter will be used by invoke() if we do item.toString()
          'toString': (InterpreterVisitor visitor, Object target,
              List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
            if (target is ComplexEnum &&
                positionalArgs.isEmpty &&
                namedArgs.isEmpty) {
              // We could return target.toString() if the native enum overrides it,
              // but for consistency with simple enums, let's return the bridged name.
              return 'MyComplexEnum.${target.name}';
            }
            throw ArgumentError('Invalid arguments for toString');
          },
        },
      );

      // Register the complex definition
      interpreter.registerBridgedEnum(
          complexEnumDefinition, 'package:test/complex_enum.dart');
    });

    test('Access complex enum value', () {
      final code = '''
        import 'package:test/complex_enum.dart';
        main() { return MyComplexEnum.itemB; }
      ''';
      final result = interpreter.execute(source: code);
      final bridgedValue = result as ComplexEnum;
      expect(bridgedValue.name, equals('itemB'));
      expect(bridgedValue.index, equals(1));
      expect(bridgedValue, equals(ComplexEnum.itemB));
    });

    test('Access field on complex enum value', () {
      final code = '''
        import 'package:test/complex_enum.dart';
        main() {
          var item = MyComplexEnum.itemA;
          return item.data; // Access the 'data' field
        }
      ''';
      final result = interpreter.execute(source: code);
      expect(result, equals('Data A'));
    });

    test('Access getter on complex enum value', () {
      final code = '''
        import 'package:test/complex_enum.dart';
        main() {
          var item = MyComplexEnum.itemB;
          return item.info; // Access the 'info' getter
        }
      ''';
      final result = interpreter.execute(source: code);
      expect(result, equals('Data B-20'));
    });

    test('Call method with argument on complex enum value', () {
      final code = '''
        import 'package:test/complex_enum.dart';
        main() {
          var item = MyComplexEnum.itemA;
          return item.multiply(5); // Call the 'multiply' method
        }
      ''';
      final result = interpreter.execute(source: code);
      expect(result, equals(50)); // 10 * 5
    });

    test('Call method without argument on complex enum value', () {
      final code = '''
        import 'package:test/complex_enum.dart';
        main() {
          var item1 = MyComplexEnum.itemA;
          var item2 = MyComplexEnum.itemB;
          return [item1.isItemA(), item2.isItemA()]; // Appel de 'isItemA'
        }
      ''';
      final result = interpreter.execute(source: code);
      expect(result, equals([true, false]));
    });

    test('Call toString() method on complex enum value', () {
      final code = '''
        import 'package:test/complex_enum.dart';
         main() {
           var item = MyComplexEnum.itemA;
           return item.toString();
         }
       ''';
      final result = interpreter.execute(source: code);
      expect(result, equals('MyComplexEnum.itemA'));
    });

    test('Compare complex bridged enum values', () {
      final code = '''
        import 'package:test/complex_enum.dart';
        main() {
          var v1 = MyComplexEnum.itemA;
          var v2 = MyComplexEnum.itemB;
          var v3 = MyComplexEnum.itemA;
          return [v1 == v2, v1 == v3, v1 != v2];
        }
      ''';
      final result = interpreter.execute(source: code);
      expect(result, equals([false, true, true]));
    });

    test('Error on calling non-existent method', () {
      final code = '''
        import 'package:test/complex_enum.dart';
         main() {
           var item = MyComplexEnum.itemA;
           return item.nonExistentMethod();
         }
       ''';
      expect(
          () => interpreter.execute(source: code),
          throwsA(isA<RuntimeError>().having((e) => e.message, 'message',
              contains('Method "nonExistentMethod" not found'))));
    });

    test('Error on accessing non-existent property', () {
      final code = '''
        import 'package:test/complex_enum.dart';
         main() {
           var item = MyComplexEnum.itemB;
           return item.nonExistentProp;
         }
       ''';
      expect(
          () => interpreter.execute(source: code),
          throwsA(isA<RuntimeError>().having((e) => e.message, 'message',
              contains('Property "nonExistentProp" not found'))));
    });

    test('Error on calling method with wrong arguments', () {
      final code = '''
        import 'package:test/complex_enum.dart';
         main() {
           var item = MyComplexEnum.itemA;
           return item.multiply('wrong_type'); // Argument invalide
         }
       ''';
      expect(
          () => interpreter.execute(source: code),
          throwsA(isA<RuntimeError>().having((e) => e.message, 'message',
              contains('Error executing bridged method "multiply"'))));
    });
  });
}
