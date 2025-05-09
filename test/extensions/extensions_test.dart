import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';
import '../interpreter_test.dart';

void main() {
  group('Extension Getters and Setters', () {
    test('Access extension getter', () {
      final code = '''
        extension NumExt on int {
          int get doubled => this * 2;
        }
       main() {
          var x = 5;
          return x.doubled;
        }
      ''';
      expect(execute(code), equals(10));
    });

    test('Assign via extension setter', () {
      final code = '''
        class Counter {
          int value = 0;
        }
        extension CounterExt on Counter {
          set increment(int amount) {
            value += amount;
          }
        }
       main() {
          var c = Counter();
          c.increment = 5;
          c.increment = 3;
          return c.value;
        }
      ''';
      expect(execute(code), equals(8));
    });

    test('Access extension getter via implicit this', () {
      final code = '''
        class MyValue {
          int _val;
          MyValue(this._val);

          int process() {
             return triple; // Accessing extension getter via implicit 'this'
          }
        }
        extension MyValueExt on MyValue {
          int get triple => this._val * 3;
        }
       main() {
           var mv = MyValue(4);
           return mv.process();
        }
      ''';
      expect(execute(code), equals(12));
    });

    test('Assign via extension setter via implicit this', () {
      final code = '''
        class MyValue {
          int _val;
          MyValue(this._val);

          void update(int newVal) {
             value = newVal; // Assigning via extension setter using implicit 'this'
          }
        }
        extension MyValueExt on MyValue {
          set value(int v) {
             this._val = v + 1; // Setter adds 1
          }
          int get current => _val;
        }
       main() {
           var mv = MyValue(4);
           mv.update(10);
           return mv.current;
        }
      ''';
      expect(execute(code), equals(11));
    });
  });

  // Add other groups for operators, index, call, etc. below
  group('Extension Binary Operators', () {
    test('operator + on custom class', () {
      final code = '''
        class Vector {
          num x, y;
          Vector(this.x, this.y);
        }
        extension VectorAdd on Vector {
           Vector operator +(Vector other) => Vector(x + other.x, y + other.y);
        }
       main() {
          var v1 = Vector(1, 2);
          var v2 = Vector(3, 4);
          return v1 + v2;
        }
      ''';
      final result = execute(code);
      expect(result, isA<InterpretedInstance>());
      final instance = result as InterpretedInstance;
      expect(instance.get('x'), equals(4));
      expect(instance.get('y'), equals(6));
    });

    test('operator - on custom class', () {
      final code = '''
        class Vector {
          num x, y;
          Vector(this.x, this.y);
        }
        extension VectorSub on Vector {
           Vector operator -(Vector other) => Vector(x - other.x, y - other.y);
        }
       main() {
          var v1 = Vector(5, 8);
          var v2 = Vector(2, 1);
          return v1 - v2;
        }
      ''';
      final result = execute(code);
      expect(result, isA<InterpretedInstance>());
      final instance = result as InterpretedInstance;
      expect(instance.get('x'), equals(3));
      expect(instance.get('y'), equals(7));
    });

    test('operator * (scalar) on custom class', () {
      final code = '''
        class Vector {
          num x, y;
          Vector(this.x, this.y);
        }
        extension VectorMul on Vector {
           Vector operator *(num scalar) => Vector(x * scalar, y * scalar);
        }
       main() {
          var v1 = Vector(3, -2);
          return v1 * 3;
        }
      ''';
      final result = execute(code);
      expect(result, isA<InterpretedInstance>());
      final instance = result as InterpretedInstance;
      expect(instance.get('x'), equals(9));
      expect(instance.get('y'), equals(-6));
    });

    test('operator == on custom class (via extension)', () {
      final code = '''
        class Points {
          num x, y;
          Points(this.x, this.y);
        }
        extension PointsEq on Points {
           bool operator ==(Object other) => other is Points && x == other.x && y == other.y;
        }
       main() {
          var p1 = Points(1, 2);
          var p2 = Points(1, 2);
          var p3 = Points(1, 3);
          return [p1 == p2, p1 == p3];
        }
      ''';
      expect(execute(code), equals([true, false]));
    });

    test('operator > on custom class', () {
      final code = '''
        class Value {
          int val;
          Value(this.val);
        }
        extension ValueCompare on Value {
           bool operator >(Value other) => this.val > other.val;
        }
       main() {
          var v1 = Value(5);
          var v2 = Value(3);
          return v1 > v2;
        }
      ''';
      expect(execute(code), isTrue);
    });

    test('Bitwise OR | on custom class', () {
      final code = '''
        class Flags {
          int value;
          Flags(this.value);
        }
        extension FlagsOps on Flags {
           Flags operator |(Flags other) => Flags(this.value | other.value);
        }
       main() {
          var f1 = Flags(1);
          var f2 = Flags(2);
          return f1 | f2;
        }
      ''';
      final result = execute(code);
      expect(result, isA<InterpretedInstance>());
      final instance = result as InterpretedInstance;
      expect(instance.get('value'), equals(3));
    });
  });

  group('Extension Compound Assignment', () {
    test('+= calls extension operator +', () {
      final code = '''
        class Value {
          int val;
          Value(this.val);
        }
        extension ValueAdd on Value {
           Value operator +(int amount) => Value(this.val + amount);
        }
       main() {
          var v = Value(10);
          v += 5; // Should call extension operator +
          return v.val;
        }
      ''';
      expect(execute(code), equals(15));
    });

    test('-= calls extension operator -', () {
      final code = '''
        class Value {
          int val;
          Value(this.val);
        }
        extension ValueSub on Value {
           Value operator -(int amount) => Value(this.val - amount);
        }
       main() {
          var v = Value(10);
          v -= 3;
          return v.val;
        }
      ''';
      expect(execute(code), equals(7));
    });

    test('*= calls extension operator *', () {
      final code = '''
        class Value {
          int val;
          Value(this.val);
        }
        extension ValueMul on Value {
           Value operator *(int factor) => Value(this.val * factor);
        }
       main() {
          var v = Value(10);
          v *= 4;
          return v.val;
        }
      ''';
      expect(execute(code), equals(40));
    });
  });

  group('Extension Index Operators', () {
    test('operator [] reads via extension', () {
      final code = '''
        class MyList {
          List<int> _internal = [10, 20, 30];
        }
        extension ListLike on MyList {
          int operator [](int index) => _internal[index] * 2; // Reads and doubles
        }
       main() {
          var ml = MyList();
          return ml[1]; // Should call extension [], returns 20 * 2
        }
      ''';
      expect(execute(code), equals(40));
    });

    test('operator []= writes via extension', () {
      final code = '''
        class MyList {
          List<int> _internal = [10, 20, 30];
          int get last => _internal.last;
        }
        extension ListLike on MyList {
          // Dummy read operator needed for compound assignment tests later
          int operator [](int index) => _internal[index];
          // Write operator adds offset
          void operator []=(int index, int value) {
             _internal[index] = value + 5;
          }
        }
       main() {
          var ml = MyList();
          ml[0] = 100; // Calls extension []=, stores 100 + 5
          return ml._internal[0];
        }
      ''';
      expect(execute(code), equals(105));
    });

    test('Compound assignment with index calls extension [] and []=', () {
      final code = '''
        class MyList {
          List<int> _internal = [10, 20, 30];
        }
        extension ListLike on MyList {
          int operator [](int index) {
             return _internal[index];
          }
          void operator []=(int index, int value) {
             _internal[index] = value * 2; // Setter doubles the value
          }
        }
       main() {
          var ml = MyList();
          ml[1] += 5; // Reads 20, calculates 25, writes 25*2=50
          return ml._internal[1];
        }
      ''';
      expect(execute(code), equals(50));
    });
  });

  group('Extension Unary Operators', () {
    test('operator unary - calls extension', () {
      final code = '''
        class Value {
          int val;
          Value(this.val);
        }
        extension ValueNegate on Value {
           Value operator -() => Value(-this.val);
        }
       main() {
          var v = Value(5);
          var negV = -v; // Should call extension operator -()
          return negV.val;
        }
      ''';
      expect(execute(code), equals(-5));
    });

    test('operator ~ calls extension', () {
      final code = '''
        class Bits {
          int value;
          Bits(this.value);
        }
        // Add ~ operator to Bits via extension
        extension BitsNot on Bits {
           Bits operator ~() => Bits(~this.value);
        }
       main() {
          var b = Bits(0); // Binary ...0000
          var invertedB = ~b;
          // ~0 should result in all bits set to 1, which is -1 in two's complement
          return invertedB.value;
        }
      ''';
      expect(execute(code), equals(-1));
    });

    // Note: ++ and -- via extensions are not yet fully supported in the interpreter logic.
    // Add tests here if/when support is added.
  });

  group('Extension Call Operator', () {
    test('call() via extension with positional args', () {
      final code = '''
        extension StringCaller on String {
          String call(String suffix, int times) {
             var result = this + suffix;
             var finalResult = '';
             for(var i = 0; i < times; i++) {
                finalResult += result;
             }
             return finalResult;
           }
        }
       main() {
          var s = "Hello";
          // Call s like a function using the extension method
          return s(", world", 2);
        }
      ''';
      expect(execute(code), equals("Hello, worldHello, world"));
    });

    test('call() via extension with named args', () {
      final code = '''
        class Adder {
          int base;
          Adder(this.base);
        }
        extension AdderExt on Adder {
          int call({required int add}) => base + add;
        }
       main() {
          var adder = Adder(10);
          return adder(add: 5);
        }
      ''';
      expect(execute(code), equals(15));
    });

    test('call() via extension with mixed args', () {
      final code = '''
        class Greeter {
          String prefix;
          Greeter(this.prefix);
        }
        extension GreeterExt on Greeter {
          String call(String name, {String postfix = "!"}) {
             return prefix + " " + name + postfix;
          }
        }
       main() {
          var greet = Greeter("Hi");
          return greet("Tester", postfix: "?!");
        }
      ''';
      expect(execute(code), equals("Hi Tester?!"));
    });
    group('Extension Tests', () {
      test('Simple extension method on String', () {
        const source = '''
        extension SimpleStringExt on String {
          String exclaim() => this + '!';
        }

        main() {
          return 'Hello'.exclaim();
        }
      ''';
        expect(execute(source), equals('Hello!'));
      });

      test('Extension method with parameters on String', () {
        const source = '''
        extension ParamStringExt on String {
          String repeat(int times) => this * times;
        }

        main() {
          return 'Ho'.repeat(3);
        }
      ''';
        expect(execute(source), equals('HoHoHo'));
      });

      test('Extension method using \'this\' property (isEmpty)', () {
        const source = '''
        extension CheckEmptyExt on String {
          bool isNotEmptyOrNull() => !isEmpty; // Accesses 'this.isEmpty'
        }

        main() {
          var result1 = 'Test'.isNotEmptyOrNull();
          var result2 = ''.isNotEmptyOrNull();
          return [result1, result2];
        }
      ''';
        expect(execute(source), equals([true, false]));
      });

      test('Extension method using \'this\' method (toUpperCase)', () {
        const source = '''
        extension ShoutExt on String {
          String shout() => toUpperCase() + '!!!'; // Calls 'this.toUpperCase()'
        }

        main() {
          return 'whisper'.shout();
        }
      ''';
        expect(execute(source), equals('WHISPER!!!'));
      });

      test('Extension method using multiple \'this\' members', () {
        const source = '''
        extension ComplexStringExt on String {
          String process(String suffix) {
             if (isEmpty) return 'empty';
             return toUpperCase() + '_' + suffix;
          }
        }

        main() {
          var r1 = 'data'.process('DONE');
          var r2 = ''.process('DONE');
          return [r1, r2];
        }
      ''';
        expect(execute(source), equals(['DATA_DONE', 'empty']));
      });

      test('Simple extension method on int', () {
        const source = '''
        extension IntExt on int {
          int squared() => this * this;
        }

        main() {
          return 5.squared();
        }
      ''';
        expect(execute(source), equals(25));
      });

      test('Extension method on List', () {
        const source = '''
        extension ListExt<T> on List<T> {
          T? secondOrNull() => length >= 2 ? this[1] : null;
        }

        main() {
          var list1 = [10, 20, 30];
          var list2 = [10];
          var list3 = [];
          return [list1.secondOrNull(), list2.secondOrNull(), list3.secondOrNull()];
        }
      ''';
        expect(execute(source), equals([20, null, null]));
      });

      test('Extension on interpreted class', () {
        // NOTE: Accessing extension members on interpreted classes relies on
        // the instance being a context itself, which isn't the standard way.
        // Let's test calling an extension method that *internally* calls instance members.
        const source = '''
        class Counter {
          int value = 0;
          void increment() { value += 1; }
          int getValue() => value;
        }

        extension CounterExt on Counter {
          // Calls instance method 'increment' via implicit 'this'
          void incrementBy(int amount) {
            for (int i = 0; i < amount; i = i + 1) {
              increment();
            }
          }
          // Calls instance method 'getValue' via implicit 'this'
          int getCurrentValuePlus(int add) {
             return getValue() + add;
          }
        }

        main() {
          var counter = Counter();
          counter.incrementBy(5);
          var currentVal = counter.getValue(); // Direct call
          var calculatedVal = counter.getCurrentValuePlus(10); // Extension call
          return [currentVal, calculatedVal];
        }
      ''';
        // Expected: counter becomes 5. Then getCurrentValuePlus(10) returns 5 + 10 = 15.
        expect(execute(source), equals([5, 15]));
      });

      test('Instance member wins over extension member', () {
        // Test with String (native class)
        const source1 = '''
        extension StringExt on String {
          int get length => 1000; // Instance getter should win
        }
        main() {
          return 'hello'.length;
        }
      ''';
        expect(execute(source1), equals(5),
            reason: 'Native String.length should override extension');

        // Test with interpreted class
        const source2 = '''
        class MyData {
          String value = 'instance';
          String info() => 'From Instance';
        }
        
        extension DataExt on MyData {
            String get value => 'extension'; // Instance field should win
            String info() => 'From Extension'; // Instance method should win
        }

        main() {
          var data = MyData();
          return [data.value, data.info()];
        }
      ''';

        expect(execute(source2), equals(['instance', 'From Instance']),
            reason: 'Instance members should override extension members');
      });

      test('Correct extension selected based on type', () {
        const source = '''
        extension ExtString on String {
          String identify() => 'String Extension';
        }

        extension ExtInt on int {
          String identify() => 'Int Extension';
        }

        extension ExtList on List {
          String identify() => 'List Extension';
        }

        main() {
          var s = 'text';
          var i = 10;
          var l = [1, 2];
          return [s.identify(), i.identify(), l.identify()];
        }
      ''';
        expect(execute(source),
            equals(['String Extension', 'Int Extension', 'List Extension']));
      });

      test('Extension applies to subtype', () {
        const source = '''
       class Base {}
       class Derived extends Base {}

       extension BaseExt on Base {
         String greet() => 'Hello from BaseExt';
       }

       main() {
         var d = Derived();
         return d.greet(); // Should apply BaseExt to Derived instance
       }
      ''';
        // This depends heavily on how appliesTo and type checking work with inheritance
        expect(execute(source), equals('Hello from BaseExt'));
      });
    });
    group('Extension Tests', () {
      test('Simple extension method on String', () {
        const source = '''
        extension SimpleStringExt on String {
          String exclaim() => this + '!';
        }

        main() {
          return 'Hello'.exclaim();
        }
      ''';
        expect(execute(source), equals('Hello!'));
      });

      test('Extension method with parameters on String', () {
        const source = '''
        extension ParamStringExt on String {
          String repeat(int times) => this * times;
        }

        main() {
          return 'Ho'.repeat(3);
        }
      ''';
        expect(execute(source), equals('HoHoHo'));
      });

      test('Extension method using \'this\' property (isEmpty)', () {
        const source = '''
        extension CheckEmptyExt on String {
          bool isNotEmptyOrNull() => !isEmpty; // Accesses 'this.isEmpty'
        }

        main() {
          var result1 = 'Test'.isNotEmptyOrNull();
          var result2 = ''.isNotEmptyOrNull();
          return [result1, result2];
        }
      ''';
        expect(execute(source), equals([true, false]));
      });

      test('Extension method using \'this\' method (toUpperCase)', () {
        const source = '''
        extension ShoutExt on String {
          String shout() => toUpperCase() + '!!!'; // Calls 'this.toUpperCase()'
        }

        main() {
          return 'whisper'.shout();
        }
      ''';
        expect(execute(source), equals('WHISPER!!!'));
      });

      test('Extension method using multiple \'this\' members', () {
        const source = '''
        extension ComplexStringExt on String {
          String process(String suffix) {
             if (isEmpty) return 'empty';
             return toUpperCase() + '_' + suffix;
          }
        }

        main() {
          var r1 = 'data'.process('DONE');
          var r2 = ''.process('DONE');
          return [r1, r2];
        }
      ''';
        expect(execute(source), equals(['DATA_DONE', 'empty']));
      });

      test('Simple extension method on int', () {
        const source = '''
        extension IntExt on int {
          int squared() => this * this;
        }

        main() {
          return 5.squared();
        }
      ''';
        expect(execute(source), equals(25));
      });

      test('Extension method on List', () {
        const source = '''
        extension ListExt<T> on List<T> {
          T? secondOrNull() => length >= 2 ? this[1] : null;
        }

        main() {
          var list1 = [10, 20, 30];
          var list2 = [10];
          var list3 = [];
          return [list1.secondOrNull(), list2.secondOrNull(), list3.secondOrNull()];
        }
      ''';
        expect(execute(source), equals([20, null, null]));
      });

      test('Extension on interpreted class', () {
        // NOTE: Accessing extension members on interpreted classes relies on
        // the instance being a context itself, which isn't the standard way.
        // Let's test calling an extension method that *internally* calls instance members.
        const source = '''
        class Counter {
          int value = 0;
          void increment() { value += 1; }
          int getValue() => value;
        }

        extension CounterExt on Counter {
          // Calls instance method 'increment' via implicit 'this'
          void incrementBy(int amount) {
            for (int i = 0; i < amount; i = i + 1) {
              increment();
            }
          }
          // Calls instance method 'getValue' via implicit 'this'
          int getCurrentValuePlus(int add) {
             return getValue() + add;
          }
        }

        main() {
          var counter = Counter();
          counter.incrementBy(5);
          var currentVal = counter.getValue(); // Direct call
          var calculatedVal = counter.getCurrentValuePlus(10); // Extension call
          return [currentVal, calculatedVal];
        }
      ''';
        // Expected: counter becomes 5. Then getCurrentValuePlus(10) returns 5 + 10 = 15.
        expect(execute(source), equals([5, 15]));
      });

      test('Instance member wins over extension member', () {
        // Test with String (native class)
        const source1 = '''
        extension StringExt on String {
          int get length => 1000; // Instance getter should win
        }
        main() {
          return 'hello'.length;
        }
      ''';
        expect(execute(source1), equals(5),
            reason: 'Native String.length should override extension');

        // Test with interpreted class
        const source2 = '''
        class MyData {
          String value = 'instance';
          String info() => 'From Instance';
        }
        
        extension DataExt on MyData {
            String get value => 'extension'; // Instance field should win
            String info() => 'From Extension'; // Instance method should win
        }

        main() {
          var data = MyData();
          return [data.value, data.info()];
        }
      ''';

        expect(execute(source2), equals(['instance', 'From Instance']),
            reason: 'Instance members should override extension members');
      });

      test('Correct extension selected based on type', () {
        const source = '''
        extension ExtString on String {
          String identify() => 'String Extension';
        }

        extension ExtInt on int {
          String identify() => 'Int Extension';
        }

        extension ExtList on List {
          String identify() => 'List Extension';
        }

        main() {
          var s = 'text';
          var i = 10;
          var l = [1, 2];
          return [s.identify(), i.identify(), l.identify()];
        }
      ''';
        expect(execute(source),
            equals(['String Extension', 'Int Extension', 'List Extension']));
      });

      test('Extension applies to subtype', () {
        const source = '''
       class Base {}
       class Derived extends Base {}

       extension BaseExt on Base {
         String greet() => 'Hello from BaseExt';
       }

       main() {
         var d = Derived();
         return d.greet(); // Should apply BaseExt to Derived instance
       }
      ''';
        // This depends heavily on how appliesTo and type checking work with inheritance
        expect(execute(source), equals('Hello from BaseExt'));
      });
    });
    // test('call() on nullable type via extension', () {
    //   final code = '''
    //     extension NullableIntCall on int? {
    //       String call(String ifNull) => this?.toString() ?? ifNull;
    //     }
    //    main() {
    //       int? x = 5;
    //       int? y;
    //       return [x("was null"), y("was null")];
    //     }
    //   ''';
    //   expect(execute(code), equals(["5", "was null"]));
    // });
  });

  group('Extension Access via Implicit This', () {
    test('Extension getter and method access via implicit this', () {
      const sourceClass = '''
        class MyCounter {
          int value = 5;

          // Méthode qui accède au getter d'extension SANS 'this.'
          int getNextValueImplicitly() {
            return nextValue; // Doit trouver CounterExtension.nextValue
          }

          // Méthode qui accède à la méthode d'extension SANS 'this.'
          int getIncrementedValueImplicitly() {
            return incrementedValue(); // Doit trouver CounterExtension.incrementedValue
          }
        }
      ''';

// Définir une extension sur cette classe
      const sourceExtension = '''
        extension CounterExtension on MyCounter {
          // Getter d'extension
          int get nextValue => this.value + 1;

          // Méthode d'extension simple
          int incrementedValue() => this.value + 1;
        }
      ''';

// Code to evaluate that uses the class and the extension
      const sourceEval = '''
        $sourceClass
        $sourceExtension
       main() {
          final counter = MyCounter();
          final implicitGetterResult = counter.getNextValueImplicitly();
          final implicitMethodResult = counter.getIncrementedValueImplicitly();

          // Return a list or a map to check both results
          return [implicitGetterResult, implicitMethodResult];
        }
      ''';
      // Compile and execute
      final result = execute(sourceEval); // Use execute as in other tests

      // Check the results
      expect(result, isA<List>());
      expect(result, equals([6, 6])); // 5 + 1 for both cases
    });
  });
}
