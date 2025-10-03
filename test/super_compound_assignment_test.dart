import 'package:test/test.dart';
import 'package:d4rt/d4rt.dart';

import 'interpreter_test.dart';

void main() {
  group('Compound Assignment on Super', () {
    test('super.property += value works in interpreted classes', () {
      final code = '''
        class Parent {
          int value = 10;
        }
        
        class Child extends Parent {
          void increment(int amount) {
            super.value += amount;
          }
          
          void decrement(int amount) {
            super.value -= amount;
          }
          
          void multiply(int factor) {
            super.value *= factor;
          }
          
          void divide(int divisor) {
            super.value ~/= divisor;
          }
        }
        
        main() {
          final child = Child();
          
          // Test +=
          child.increment(5);
          if (child.value != 15) return -1;
          
          // Test -=
          child.decrement(3);
          if (child.value != 12) return -2;
          
          // Test *=
          child.multiply(2);
          if (child.value != 24) return -3;
          
          // Test ~/=
          child.divide(4);
          if (child.value != 6) return -4;
          
          return child.value;
        }
      ''';

      final result = execute(code);
      expect(result, equals(6));
    });

    test('super.property with all compound operators', () {
      final code = '''
        class Base {
          int number = 100;
          String text = 'Hello';
        }
        
        class Derived extends Base {
          void testOperators() {
            // Arithmetic
            super.number += 20;   // 120
            super.number -= 10;   // 110
            super.number *= 2;    // 220
            super.number ~/= 4;   // 55
            super.number %= 10;   // 5
            
            // String concatenation
            super.text += ' World';
          }
          
          int getNumber() => super.number;
          String getText() => super.text;
        }
        
        main() {
          final d = Derived();
          d.testOperators();
          return {'number': d.getNumber(), 'text': d.getText()};
        }
      ''';

      final result = execute(code) as Map;
      expect(result['number'], equals(5));
      expect(result['text'], equals('Hello World'));
    });

    test('compound assignment on super with getters/setters', () {
      final code = '''
        class Parent {
          int _value = 10;
          
          int get value => _value;
          set value(int v) {
            _value = v;
          }
        }
        
        class Child extends Parent {
          void doubleValue() {
            super.value *= 2;
          }
        }
        
        main() {
          final child = Child();
          child.doubleValue();
          return child.value;
        }
      ''';

      final result = execute(code);
      expect(result, equals(20));
    });

    test('nested super compound assignments', () {
      final code = '''
        class GrandParent {
          int value = 5;
        }
        
        class Parent extends GrandParent {
          void addTen() {
            super.value += 10;
          }
        }
        
        class Child extends Parent {
          void doubleIt() {
            super.value *= 2;
          }
        }
        
        main() {
          final child = Child();
          child.addTen();    // value = 15
          child.doubleIt();  // value = 30
          return child.value;
        }
      ''';

      final result = execute(code);
      expect(result, equals(30));
    });

    test('super compound assignment with different types', () {
      final code = '''
        class Base {
          double amount = 10.5;
          List<int> items = [1, 2, 3];
        }
        
        class Extended extends Base {
          void updateAmount() {
            super.amount += 5.5;
            super.amount *= 2.0;
          }
          
          void addItems() {
            super.items += [4, 5];
          }
        }
        
        main() {
          final e = Extended();
          e.updateAmount();
          e.addItems();
          return {'amount': e.amount, 'itemCount': e.items.length};
        }
      ''';

      final result = execute(code) as Map;
      expect(result['amount'], equals(32.0));
      expect(result['itemCount'], equals(5));
    });
  });

  group('Compound Assignment on Bridged Super', () {
    test('compound assignments on bridged super properties', () {
      final interpreter = D4rt();

      // Create a native Dart class to bridge
      final bridgedClass = BridgedClass(
        nativeType: _TestNativeParent,
        name: 'NativeParent',
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            return _TestNativeParent();
          },
        },
        getters: {
          'counter': (visitor, instance) =>
              (instance as _TestNativeParent).counter,
          'amount': (visitor, instance) =>
              (instance as _TestNativeParent).amount,
          'text': (visitor, instance) => (instance as _TestNativeParent).text,
        },
        setters: {
          'counter': (visitor, instance, value) =>
              (instance as _TestNativeParent).counter = value as int,
          'amount': (visitor, instance, value) =>
              (instance as _TestNativeParent).amount = value as double,
          'text': (visitor, instance, value) =>
              (instance as _TestNativeParent).text = value as String,
        },
      );

      interpreter.registerBridgedClass(
          bridgedClass, 'package:test/native_parent.dart');

      final source = '''
        import 'package:test/native_parent.dart';
        
        class Child extends NativeParent {
          Child() : super();
          
          void testCompoundAssignments() {
            // Test += on int property
            super.counter += 5;  // 10 + 5 = 15
            
            // Test *= on int property
            super.counter *= 2;  // 15 * 2 = 30
            
            // Test -= on double property
            super.amount -= 2.5;  // 100.0 - 2.5 = 97.5
            
            // Test /= on double property
            super.amount /= 2.0;  // 97.5 / 2.0 = 48.75
            
            // Test += on String property
            super.text += ' World';  // 'Hello' + ' World' = 'Hello World'
          }
        }
        
        main() {
          final child = Child();
          child.testCompoundAssignments();
          return {
            'counter': child.counter,
            'amount': child.amount,
            'text': child.text,
          };
        }
      ''';

      final result = interpreter.execute(source: source) as Map;
      expect(result['counter'], equals(30));
      expect(result['amount'], equals(48.75));
      expect(result['text'], equals('Hello World'));
    });

    test('compound assignments on bridged super with getter/setter', () {
      final interpreter = D4rt();

      // Create a bridged class with explicit getter/setter
      final bridgedClass = BridgedClass(
        nativeType: _TestNativeParent,
        name: 'NativeBase',
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            return _TestNativeParent();
          },
        },
        getters: {
          'value': (visitor, instance) =>
              (instance as _TestNativeParent).counter,
        },
        setters: {
          'value': (visitor, instance, value) =>
              (instance as _TestNativeParent).counter = value as int,
        },
      );

      interpreter.registerBridgedClass(
          bridgedClass, 'package:test/native_base.dart');

      final source = '''
        import 'package:test/native_base.dart';
        
        class Derived extends NativeBase {
          Derived() : super();
          
          void multiplyValue(int factor) {
            super.value *= factor;
          }
          
          void addToValue(int amount) {
            super.value += amount;
          }
        }
        
        main() {
          final obj = Derived();
          obj.addToValue(15);    // 10 + 15 = 25
          obj.multiplyValue(4);  // 25 * 4 = 100
          return obj.value;
        }
      ''';

      final result = interpreter.execute(source: source);
      expect(result, equals(100));
    });

    test('all compound operators on bridged super', () {
      final interpreter = D4rt();

      final bridgedClass = BridgedClass(
        nativeType: _TestNativeParent,
        name: 'NativeNumber',
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final instance = _TestNativeParent();
            instance.counter = 100;
            return instance;
          },
        },
        getters: {
          'value': (visitor, instance) =>
              (instance as _TestNativeParent).counter,
        },
        setters: {
          'value': (visitor, instance, value) =>
              (instance as _TestNativeParent).counter = value as int,
        },
      );

      interpreter.registerBridgedClass(
          bridgedClass, 'package:test/native_number.dart');

      final source = '''
        import 'package:test/native_number.dart';
        
        class Calculator extends NativeNumber {
          Calculator() : super();
          
          void runOperations() {
            super.value += 20;   // 100 + 20 = 120
            super.value -= 10;   // 120 - 10 = 110
            super.value *= 2;    // 110 * 2 = 220
            super.value ~/= 4;   // 220 ~/ 4 = 55
            super.value %= 10;   // 55 % 10 = 5
          }
        }
        
        main() {
          final calc = Calculator();
          calc.runOperations();
          return calc.value;
        }
      ''';

      final result = interpreter.execute(source: source);
      expect(result, equals(5));
    });

    test('nested inheritance with bridged super compound assignment', () {
      final interpreter = D4rt();

      final bridgedClass = BridgedClass(
        nativeType: _TestNativeParent,
        name: 'BridgedGrandParent',
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final instance = _TestNativeParent();
            instance.counter = 10;
            return instance;
          },
        },
        getters: {
          'value': (visitor, instance) =>
              (instance as _TestNativeParent).counter,
        },
        setters: {
          'value': (visitor, instance, value) =>
              (instance as _TestNativeParent).counter = value as int,
        },
      );

      interpreter.registerBridgedClass(
          bridgedClass, 'package:test/bridged_grand_parent.dart');

      final source = '''
        import 'package:test/bridged_grand_parent.dart';
        
        class InterpretedParent extends BridgedGrandParent {
          InterpretedParent() : super();
          
          void addFive() {
            super.value += 5;
          }
        }
        
        class InterpretedChild extends InterpretedParent {
          InterpretedChild() : super();
          
          void doubleit() {
            super.value *= 2;
          }
        }
        
        main() {
          final child = InterpretedChild();
          child.addFive();    // 10 + 5 = 15
          child.doubleit();   // 15 * 2 = 30
          return child.value;
        }
      ''';

      final result = interpreter.execute(source: source);
      expect(result, equals(30));
    });

    test('compound assignment on bridged super with type conversions', () {
      final interpreter = D4rt();

      final bridgedClass = BridgedClass(
        nativeType: _TestNativeParent,
        name: 'NativeMixed',
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            return _TestNativeParent();
          },
        },
        getters: {
          'intValue': (visitor, instance) =>
              (instance as _TestNativeParent).counter,
          'doubleValue': (visitor, instance) =>
              (instance as _TestNativeParent).amount,
        },
        setters: {
          'intValue': (visitor, instance, value) =>
              (instance as _TestNativeParent).counter = value as int,
          'doubleValue': (visitor, instance, value) =>
              (instance as _TestNativeParent).amount = value as double,
        },
      );

      interpreter.registerBridgedClass(
          bridgedClass, 'package:test/native_mixed.dart');

      final source = '''
        import 'package:test/native_mixed.dart';
        
        class Mixed extends NativeMixed {
          Mixed() : super();
          
          void testMixedOperations() {
            // Integer division
            super.intValue ~/= 3;  // 10 ~/ 3 = 3
            
            // Modulo
            super.intValue %= 2;  // 3 % 2 = 1
            
            // Multiply by larger number
            super.intValue *= 50;  // 1 * 50 = 50
            
            // Double operations
            super.doubleValue += 23.5;  // 100.0 + 23.5 = 123.5
            super.doubleValue /= 2.5;   // 123.5 / 2.5 = 49.4
          }
        }
        
        main() {
          final m = Mixed();
          m.testMixedOperations();
          return {
            'int': m.intValue,
            'double': m.doubleValue,
          };
        }
      ''';

      final result = interpreter.execute(source: source) as Map;
      expect(result['int'], equals(50));
      expect(result['double'], equals(49.4));
    });
  });
}

// Helper native class for testing
class _TestNativeParent {
  int counter = 10;
  double amount = 100.0;
  String text = 'Hello';
}
