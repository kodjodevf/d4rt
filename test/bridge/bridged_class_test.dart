import 'package:d4rt/src/utils/extensions/interpreted_instance.dart';
import 'package:test/test.dart';
import 'package:d4rt/d4rt.dart';

// 1. Class Native for tests
class NativeCounter {
  static int _staticCounter = 0;
  int _value;
  final String id;
  bool _isDisposed = false; // Pour tester les méthodes sur état détruit

  // Default constructor
  NativeCounter(this._value, [this.id = 'default']);

  // Named constructor
  NativeCounter.withId(this.id, {int initialValue = 0}) : _value = initialValue;

  // ignore: unnecessary_getters_setters
  static int get staticValue => _staticCounter;
  static set staticValue(int v) {
    _staticCounter = v;
  }

  static String staticMethod(String prefix) {
    _staticCounter++;
    final result = '$prefix:static:$_staticCounter';
    return result;
  }

  int get value {
    if (_isDisposed) throw StateError('Instance disposed');
    return _value;
  }

  set value(int v) {
    if (_isDisposed) throw StateError('Instance disposed');
    _value = v;
  }

  String get description {
    if (_isDisposed) throw StateError('Instance disposed');
    return 'Counter($id):$_value';
  }

  void increment([int amount = 1]) {
    if (_isDisposed) throw StateError('Instance disposed');
    _value += amount;
  }

  // Method to test arguments
  int add(int otherValue, {InterpretedInstance? instance}) {
    if (_isDisposed) throw StateError('Instance disposed');
    final result = _value + otherValue;
    return result;
  }

  // Method to test passing a bridged instance
  bool isSame(NativeCounter other) {
    if (_isDisposed) throw StateError('Instance disposed');
    return id == other.id && _value == other._value;
  }

  // Method to simulate resource disposal
  void dispose() {
    _isDisposed = true;
  }
}

class AsyncProcessor {
  final String id;
  AsyncProcessor(this.id);

  Future<String> delayedSuccess(String input, Duration delay) async {
    await Future.delayed(delay);
    return "Processed ($id): $input";
  }

  Future<int> calculateAsync(int value) async {
    await Future.delayed(Duration(milliseconds: 10));
    return value * 2;
  }

  Future<void> doSomethingAsync() async {
    await Future.delayed(Duration(milliseconds: 5));
    // No return value
  }

  // Returns an instance of another bridged class
  Future<NativeCounter> createCounterAsync(
      int initialValue, String counterId) async {
    await Future.delayed(Duration(milliseconds: 15));
    return NativeCounter(initialValue, counterId);
  }

  Future<String> alwaysFail(String message) async {
    await Future.delayed(Duration(milliseconds: 5));
    throw Exception("Failure from AsyncProcessor ($id): $message");
  }

  // SYNCHRONOUS method returning a NativeCounter
  NativeCounter createCounterSync(int initialValue, String counterId) {
    return NativeCounter(initialValue, counterId);
  }
}

void main() {
  group('Bridged Class Tests', () {
    late D4rt interpreter;

    setUp(() {
      interpreter = D4rt();

      // Reset the static counter before each test
      NativeCounter._staticCounter = 0;

      // 2. Definition of the bridged class for NativeCounter
      final counterDefinition = BridgedClass(
        nativeType: NativeCounter,
        name: 'Counter', // Name in the interpreter
        constructors: {
          // Default constructor: Counter(value, [id])
          '': (InterpreterVisitor visitor, List<Object?> positionalArgs,
              Map<String, Object?> namedArgs) {
            // Check the number of arguments
            if (positionalArgs.isEmpty || positionalArgs.length > 2) {
              throw ArgumentError(
                  'Default constructor requires 1 or 2 positional arguments, got ${positionalArgs.length}');
            }
            // Check the type of the first argument (value)
            if (positionalArgs[0] is! int) {
              throw ArgumentError(
                  'Default constructor first argument (value) must be an integer, got ${positionalArgs[0]?.runtimeType}');
            }
            final value = positionalArgs[0] as int;

            // Handle the optional argument (id)
            String id = 'default';
            if (positionalArgs.length > 1) {
              // Check that the argument is a String or null
              if (positionalArgs[1] != null && positionalArgs[1] is! String) {
                throw ArgumentError(
                    'Default constructor second argument (id) must be a string or null, got ${positionalArgs[1]?.runtimeType}');
              }
              // Assign if not null, otherwise keep 'default'
              if (positionalArgs[1] != null) {
                id = positionalArgs[1] as String;
              }
            }
            // Call the native constructor
            return NativeCounter(value, id);
          },
          // Named constructor: Counter.withId(id, initialValue: 0)
          'withId': (InterpreterVisitor visitor, List<Object?> positionalArgs,
              Map<String, Object?> namedArgs) {
            // Check the positional argument (id)
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw ArgumentError(
                  'Named constructor \'withId\' expects exactly 1 positional string argument (id), got ${positionalArgs.isNotEmpty ? positionalArgs[0]?.runtimeType : 'none'}');
            }
            final id = positionalArgs[0] as String;

            // Check the optional named argument (initialValue)
            int initialValue = 0;
            if (namedArgs.containsKey('initialValue')) {
              if (namedArgs['initialValue'] is! int?) {
                throw ArgumentError(
                    'Named argument \'initialValue\' for constructor \'withId\' must be an int?, got ${namedArgs['initialValue']?.runtimeType}');
              }
              // Accept null as initialValue and treat it as 0
              initialValue = namedArgs['initialValue'] as int? ?? 0;
            }
            // Call the native named constructor
            return NativeCounter.withId(id, initialValue: initialValue);
          }
        },
        staticGetters: {
          // Counter.staticValue
          'staticValue': (InterpreterVisitor visitor) {
            return NativeCounter.staticValue;
          }
        },
        staticSetters: {
          // Counter.staticValue = ...
          'staticValue': (InterpreterVisitor visitor, Object? value) {
            if (value is! int) {
              throw ArgumentError('staticValue requires an integer');
            }
            NativeCounter.staticValue = value;
          }
        },
        staticMethods: {
          // Counter.staticMethod(prefix)
          'staticMethod': (InterpreterVisitor visitor,
              List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw ArgumentError('staticMethod expects 1 string argument');
            }
            return NativeCounter.staticMethod(positionalArgs[0] as String);
          }
        },
        getters: {
          // counter.value
          'value': (InterpreterVisitor? visitor, Object target) {
            if (target is NativeCounter) return target.value;
            throw TypeError();
          },
          // counter.id
          'id': (InterpreterVisitor? visitor, Object target) {
            if (target is NativeCounter) return target.id;
            throw TypeError();
          },
          // counter.description
          'description': (InterpreterVisitor? visitor, Object target) {
            if (target is NativeCounter) return target.description;
            throw TypeError();
          }
        },
        setters: {
          // counter.value = ...
          'value': (InterpreterVisitor? visitor, Object target, Object? value) {
            if (target is NativeCounter && value is int) {
              target.value = value;
            } else {
              throw ArgumentError(
                  'Instance setter $value requires NativeCounter target and int value');
            }
          }
        },
        methods: {
          // counter.increment([amount])
          'increment': (InterpreterVisitor visitor, Object target,
              List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
            if (target is NativeCounter) {
              if (positionalArgs.isEmpty) {
                target.increment();
              } else if (positionalArgs.length == 1 &&
                  positionalArgs[0] is int) {
                target.increment(positionalArgs[0] as int);
              } else {
                throw ArgumentError(
                    'increment expects 0 or 1 integer argument');
              }
            } else {
              throw TypeError();
            }
            return null; // void method
          },
          // counter.add(otherValue)
          'add': (InterpreterVisitor visitor, Object target,
              List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
            if (target is NativeCounter &&
                positionalArgs.length == 1 &&
                positionalArgs[0] is int) {
              return target.add(positionalArgs[0] as int);
            }
            throw ArgumentError(
                'add expects NativeCounter target and 1 integer argument');
          },
          // counter.isSame(otherCounter)
          'isSame': (InterpreterVisitor visitor, Object target,
              List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
            // Check the target and arguments
            if (target is NativeCounter && positionalArgs.length == 1) {
              final arg = positionalArgs[0];
              NativeCounter? otherNative;

              // Accept either a BridgedInstance containing a NativeCounter,
              // or a NativeCounter directly (due to possible unwrapping)
              if (arg is BridgedInstance && arg.nativeObject is NativeCounter) {
                otherNative = arg.nativeObject as NativeCounter;
              } else if (arg is NativeCounter) {
                otherNative = arg;
              }

              if (otherNative != null) {
                // Call the native isSame method
                return target.isSame(otherNative);
              }
              // Error: Argument is neither a BridgedInstance<NativeCounter> nor a NativeCounter
              throw ArgumentError(
                  'Invalid argument for isSame: Expected BridgedInstance<NativeCounter> or NativeCounter, got ${arg?.runtimeType}.');
            }
            // Error: Wrong target type or wrong number of arguments
            String errorDetails;
            if (target is! NativeCounter) {
              errorDetails =
                  'Target must be NativeCounter, got ${target.runtimeType}.';
            } else {
              // Only other possibility here: wrong number of args
              errorDetails =
                  'Expected exactly 1 argument, got ${positionalArgs.length}.';
            }
            throw ArgumentError('Invalid arguments for isSame: $errorDetails');
          },
          // counter.dispose()
          'dispose': (InterpreterVisitor visitor, Object target,
              List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
            if (target is NativeCounter && positionalArgs.isEmpty) {
              target.dispose();
              return null; // void
            }
            throw ArgumentError('Invalid arguments for dispose');
          }
        },
      );

      // Register the bridged class
      interpreter.registerBridgedClass(
          counterDefinition, 'package:test/counter.dart');

      // 3. Definition of the bridge for AsyncProcessor
      final asyncProcessorDefinition = BridgedClass(
        nativeType: AsyncProcessor,
        name: 'AsyncProcessor', // Name in the interpreter
        constructors: {
          // Constructor: AsyncProcessor(id)
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length == 1 && positionalArgs[0] is String) {
              return AsyncProcessor(positionalArgs[0] as String);
            }
            throw ArgumentError(
                'AsyncProcessor constructor expects 1 string argument (id)');
          }
        },
        methods: {
          // processor.delayedSuccess(input, duration) -> Future<String>
          'delayedSuccess': (visitor, target, positionalArgs, namedArgs) {
            if (target is AsyncProcessor &&
                positionalArgs.length == 2 &&
                positionalArgs[0] is String &&
                positionalArgs[1] is Duration) {
              // Assume that Duration is bridged or native
              return target.delayedSuccess(
                  positionalArgs[0] as String, positionalArgs[1] as Duration);
            }
            throw ArgumentError('Invalid arguments for delayedSuccess');
          },
          // processor.calculateAsync(value) -> Future<int>
          'calculateAsync': (visitor, target, positionalArgs, namedArgs) {
            if (target is AsyncProcessor &&
                positionalArgs.length == 1 &&
                positionalArgs[0] is int) {
              return target.calculateAsync(positionalArgs[0] as int);
            }
            throw ArgumentError('Invalid arguments for calculateAsync');
          },
          // processor.doSomethingAsync() -> Future<void>
          'doSomethingAsync': (visitor, target, positionalArgs, namedArgs) {
            if (target is AsyncProcessor && positionalArgs.isEmpty) {
              return target.doSomethingAsync();
            }
            throw ArgumentError('Invalid arguments for doSomethingAsync');
          },
          // processor.createCounterAsync(value, id) -> Future<Counter>
          'createCounterAsync': (visitor, target, positionalArgs, namedArgs) {
            if (target is AsyncProcessor &&
                positionalArgs.length == 2 &&
                positionalArgs[0] is int &&
                positionalArgs[1] is String) {
              // The adapter returns directly the Future<NativeCounter>.
              // The interpreter will handle the waiting and bridging of the NativeCounter result.
              return target
                  .createCounterAsync(
                      positionalArgs[0] as int, positionalArgs[1] as String)
                  .then((nativeCounter) {
                return nativeCounter;
              });
            }
            throw ArgumentError('Invalid arguments for createCounterAsync');
          },
          // processor.alwaysFail(message) -> Future<String> (which fails)
          'alwaysFail': (visitor, target, positionalArgs, namedArgs) {
            if (target is AsyncProcessor &&
                positionalArgs.length == 1 &&
                positionalArgs[0] is String) {
              return target.alwaysFail(positionalArgs[0] as String);
            }
            throw ArgumentError('Invalid arguments for alwaysFail');
          },
          // processor.createCounterSync(value, id) -> Counter (sync)
          'createCounterSync': (visitor, target, positionalArgs, namedArgs) {
            if (target is AsyncProcessor &&
                positionalArgs.length == 2 &&
                positionalArgs[0] is int &&
                positionalArgs[1] is String) {
              // Call the native synchronous method
              return target.createCounterSync(
                  positionalArgs[0] as int, positionalArgs[1] as String);
            }
            throw ArgumentError('Invalid arguments for createCounterSync');
          }
        },
        // No static members or getters/setters for this example
        staticGetters: {},
        staticSetters: {},
        getters: {},
      );

      // Register AsyncProcessor
      interpreter.registerBridgedClass(
          asyncProcessorDefinition, 'package:test/async_processor.dart');
    });

    test('Call default constructor', () {
      final code = '''
        import 'package:test/counter.dart';
        main() {
          var c = Counter(10);
          return c.value;
        }
      ''';
      expect(interpreter.execute(source: code), equals(10));
    });

    test('Call default constructor with optional ID', () {
      final code = '''
        import 'package:test/counter.dart';
        main() {
          var c = Counter(20, 'my-counter');
          return c.id;
        }
      ''';
      expect(interpreter.execute(source: code), equals('my-counter'));
    });

    test('Call named constructor', () {
      final code = '''
        import 'package:test/counter.dart';
        main() {
          var c = Counter.withId('specific-id');
          return [c.id, c.value];
        }
      ''';
      expect(interpreter.execute(source: code), equals(['specific-id', 0]));
    });

    test('Call named constructor with named argument', () {
      final code = '''
        import 'package:test/counter.dart';
        main() {
          var c = Counter.withId('other-id', initialValue: 55);
           return [c.id, c.value];
        }
      ''';
      expect(interpreter.execute(source: code), equals(['other-id', 55]));
    });

    test('Access static getter', () {
      NativeCounter.staticValue = 99; // Set native value directly
      final code = '''
        import 'package:test/counter.dart';
        main() { return Counter.staticValue; }
      ''';
      expect(interpreter.execute(source: code), equals(99));
    });

    test('Use static setter', () {
      final code = '''
        import 'package:test/counter.dart';
        main() {
           Counter.staticValue = 123;
           return Counter.staticValue;
         }
      ''';
      expect(interpreter.execute(source: code), equals(123));
      expect(
          NativeCounter.staticValue, equals(123)); // Verify native side effect
    });

    test('Call static method', () {
      NativeCounter.staticValue = 0; // Reset static counter
      final code = '''
        import 'package:test/counter.dart';
        main() {
          var r1 = Counter.staticMethod('prefix1');
          var r2 = Counter.staticMethod('prefix2');
          return [r1, r2, Counter.staticValue];
        }
      ''';
      expect(interpreter.execute(source: code),
          equals(['prefix1:static:1', 'prefix2:static:2', 2]));
    });

    test('Access instance getter', () {
      final code = '''
        import 'package:test/counter.dart';
        main() {
          var c = Counter(7, 'getter-test');
          return [c.value, c.id, c.description];
        }
      ''';
      expect(interpreter.execute(source: code),
          equals([7, 'getter-test', 'Counter(getter-test):7']));
    });

    test('Use instance setter', () {
      final code = '''
        import 'package:test/counter.dart';
         main() {
           var c = Counter(5);
           c.value = 25;
           return c.value;
         }
       ''';
      expect(interpreter.execute(source: code), equals(25));
    });

    test('Call instance method (no args)', () {
      final code = '''
        import 'package:test/counter.dart';
         main() {
           var c = Counter(100);
           c.increment();
           return c.value;
         }
       ''';
      expect(interpreter.execute(source: code), equals(101));
    });

    test('Call instance method (with args)', () {
      final code = '''
        import 'package:test/counter.dart';
         main() {
           var c = Counter(10);
           c.increment(5);
           var sum = c.add(3);
           return [c.value, sum];
         }
       ''';
      expect(interpreter.execute(source: code), equals([15, 18]));
    });

    test('Pass bridged instance as argument', () {
      final code = '''
        import 'package:test/counter.dart';
         main() {
           var c1 = Counter(50, 'ID-A');
           var c2 = Counter(50, 'ID-A');
           var c3 = Counter(55, 'ID-A');
           var c4 = Counter(50, 'ID-B');
           return [c1.isSame(c2), c1.isSame(c3), c1.isSame(c4)];
         }
       ''';
      expect(interpreter.execute(source: code), equals([true, false, false]));
    });

    test('Error: Call non-existent constructor', () {
      final code = '''
        import 'package:test/counter.dart';
        main() { return Counter.nonExistent(); }
      ''';
      expect(
          () => interpreter.execute(source: code),
          throwsA(isA<RuntimeError>().having(
              (e) => e.message,
              'message',
              contains(
                  "Bridged class 'Counter' has no constructor or static method named 'nonExistent'"))));
    });

    test('Error: Call default constructor with wrong arg type', () {
      final code = '''
        import 'package:test/counter.dart';
        main() { return Counter('wrong'); }
      '''; // Expects int
      expect(
          () => interpreter.execute(source: code),
          throwsA(isA<RuntimeError>().having(
              (e) => e.message,
              'message',
              contains(
                  "Native error during default bridged constructor for 'Counter'"))));
    });

    test('Error: Call named constructor with wrong arg type', () {
      final code = '''
        import 'package:test/counter.dart';
        main() { return Counter.withId(123); }
      '''; // Expects String
      expect(
          () => interpreter.execute(source: code),
          throwsA(isA<RuntimeError>().having((e) => e.message, 'message',
              contains("Native error during bridged constructor"))));
    });

    test('Error: Access non-existent static member', () {
      final code = '''
        import 'package:test/counter.dart';
        main() { return Counter.nonExistentStatic; }
      ''';
      expect(
          () => interpreter.execute(source: code),
          throwsA(isA<RuntimeError>().having((e) => e.message, 'message',
              contains("Undefined static member 'nonExistentStatic'"))));
    });

    test('Error: Call non-existent static method', () {
      final code = '''
        import 'package:test/counter.dart';
        main() { return Counter.nonExistentStaticMethod(); }
      ''';
      expect(
          () => interpreter.execute(source: code),
          throwsA(isA<RuntimeError>().having(
              (e) => e.message,
              'message',
              contains(
                  "Bridged class 'Counter' has no constructor or static method named 'nonExistentStaticMethod'"))));
    });

    test('Error: Access non-existent instance member', () {
      final code = '''
        import 'package:test/counter.dart';
         main() {
           var c = Counter(1);
           return c.nonExistentMember;
         }
       ''';
      // This error comes from the fallback mechanism after bridge check fails
      expect(
          () => interpreter.execute(source: code),
          throwsA(isA<RuntimeError>().having(
              (e) => e.message,
              'message',
              contains(
                  "Undefined property or method 'nonExistentMember' on bridged instance of 'Counter'"))));
    });

    test('Error: Call non-existent instance method', () {
      final code = '''
        import 'package:test/counter.dart';
         main() {
           var c = Counter(1);
           return c.nonExistentMethod();
         }
       ''';
      expect(
          () => interpreter.execute(source: code),
          throwsA(isA<RuntimeError>().having(
              (e) => e.message,
              'message',
              contains(
                  "Bridged class 'Counter' has no instance method named 'nonExistentMethod'"))));
    });

    test('Error: Call instance method with wrong args', () {
      final code = '''
        import 'package:test/counter.dart';
         main() {
           var c = Counter(1);
           return c.add('wrong'); // Expects int
         }
       ''';
      expect(
          () => interpreter.execute(source: code),
          throwsA(isA<RuntimeError>().having((e) => e.message, 'message',
              contains("Native error during bridged method call 'add'"))));
    });

    test('Error: Call method on disposed instance', () {
      final code = '''
        import 'package:test/counter.dart';
         main() {
           var c = Counter(1);
           c.dispose();
           return c.value; // Should throw
         }
       ''';
      expect(
          () => interpreter.execute(source: code),
          throwsA(isA<RuntimeError>().having((e) => e.message, 'message',
              contains("Unexpected error: Bad state: Instance disposed"))));
    });

    test('Dart class inheriting from bridged class', () {
      final source = '''
        import 'package:test/counter.dart';
        class Employee extends Counter {
          String department;

          // Constructor calling super() by default
          Employee(int initialValue, String id, this.department)
              : super(initialValue, id); // Calls Counter(value, id)

          // Constructor calling super.withId()
          Employee.withIdDept(String id, this.department, {int initialValue = 5})
              : super.withId(id, initialValue: initialValue); // Calls Counter.withId(id, initialValue: x)

          String getEmployeeInfo() {
            // Access to 'id' and 'value' (inherited) and 'department' (derived)
            return "Employee \$id in \$department, value: \$value";
          }
        }

        main() {
         final emp1 = Employee(10, 'emp1', 'Sales');
        final emp2 = Employee.withIdDept('emp2', 'Tech', initialValue: 25);

        emp1.increment(); // Inherited method
        final emp1Value = emp1.value; // Inherited getter
        final emp1Info = emp1.getEmployeeInfo(); // Derived method

        final emp2Value = emp2.value;
        final emp2Info = emp2.getEmployeeInfo();

        // Return the results for verification
        return {
          'emp1_id': emp1.id,
          'emp1_value_after_inc': emp1Value,
          'emp1_dept': emp1.department,
          'emp1_info': emp1Info,
          'emp2_id': emp2.id,
          'emp2_value': emp2Value,
          'emp2_dept': emp2.department,
          'emp2_info': emp2Info,
        };
        }
      ''';

      final result = interpreter.execute(source: source);

      // Verifications
      expect(result, isNotNull);
      final resultMap = result as Map;

      expect(resultMap, isA<Map>());
      expect(resultMap['emp1_id'], 'emp1');
      expect(resultMap['emp1_value_after_inc'], 11); // 10 + 1
      expect(resultMap['emp1_dept'], 'Sales');
      expect(resultMap['emp1_info'], 'Employee emp1 in Sales, value: 11');

      expect(resultMap['emp2_id'], 'emp2');
      expect(resultMap['emp2_value'], 25);
      expect(resultMap['emp2_dept'], 'Tech');
      expect(resultMap['emp2_info'], 'Employee emp2 in Tech, value: 25');
    });

    test('Await bridged method returning Future<String>', () async {
      final code = '''
        import 'package:test/async_processor.dart';
        main() async {
          final processor = AsyncProcessor('p1');
          final result = await processor.delayedSuccess('hello', Duration(milliseconds: 20));
          return result;
        }
      ''';
      // Use execute for async main functions
      final result = await interpreter.execute(source: code);
      expect(result, equals('Processed (p1): hello'));
    });

    test('Await bridged method returning Future<int> with args', () async {
      final code = '''
        import 'package:test/async_processor.dart';
        main() async {
          final processor = AsyncProcessor('p2');
          final value = await processor.calculateAsync(15);
          return value;
        }
      ''';
      final result = await interpreter.execute(source: code);
      expect(result, equals(30));
    });

    test('Await bridged method returning Future', () async {
      final code = '''
        import 'package:test/async_processor.dart';
        main() async {
          final processor = AsyncProcessor('p3');
          await processor.doSomethingAsync();
          return 'done'; // Retourne quelque chose pour vérifier que l'await a terminé
        }
      ''';
      final result = await interpreter.execute(source: code);
      expect(result, equals('done'));
      // We can also check the console logs if necessary
    });

    test('Await bridged method returning Future<BridgedInstance>', () async {
      final code = '''
        import 'package:test/async_processor.dart';
        import 'package:test/counter.dart';
         main() async {
           final processor = AsyncProcessor('p4');
           // Attend que le Future<NativeCounter> se résolve.
           // Le résultat devrait être une BridgedInstance<NativeCounter>
           final counter = await processor.createCounterAsync(100, 'async-ctr');
           // Vérifier le type et accéder aux membres du compteur ponté
           counter.increment(5);
           final val = counter.value;
           return val;
         }
       ''';
      final result = await interpreter.execute(source: code);
      expect(result, equals(105));
    });

    test('Try/catch await on bridged method returning Future.error', () async {
      final code = '''
        import 'package:test/async_processor.dart';
         main() async {
           final processor = AsyncProcessor('p5');
           String errorMessage = 'initial';
           try {
             await processor.alwaysFail('something went wrong');
             errorMessage = 'should have failed';
           } catch (e, s) {
             // Attraper l'erreur propagée depuis le Future natif
             errorMessage = 'Caught: \$e'; // Convertir l'erreur en string
           }
           return errorMessage;
         }
       ''';
      final result = await interpreter.execute(source: code);
      expect(
          result,
          contains(
              'Caught: Exception: Failure from AsyncProcessor (p5): something went wrong'));
    });

    test('Sync bridged method returning BridgedInstance', () {
      final source = '''
        import 'package:test/async_processor.dart';
        import 'package:test/counter.dart';
         main() {
           final processor = AsyncProcessor('p-sync');
           // Appelle la méthode sync. On s'attend à ce que le résultat soit
           // automatiquement ponté en BridgedInstance par l'interpréteur.
           final counter = processor.createCounterSync(200, 'sync-ctr');

           // Appelle directement les méthodes sur l'instance (supposée pontée)
           counter.increment(10); // Si ça marche, c'est une BridgedInstance
           final val = counter.value;
           return val; // Doit être 200 + 10 = 210
         }
       ''';
      // End of multi-line string
      // Use execute (synchronous)
      final result = interpreter.execute(source: source);
      expect(result, equals(210));
    });

    test('Override bridged class methods', () {
      final source = '''
        import 'package:test/counter.dart';
        // Interpreted class that inherits from the native bridged class 'Counter'
        class OverridenCounter extends Counter {

          // Constructor using the bridged constructor of the superclass
          OverridenCounter(int initialValue, String id) : super(initialValue, id);

          // Override the 'increment' method
          @override
          void increment([int amount = 1]) {
            // Access state via the bridged superclass getters/setters
            int currentValue = super.value;
            int newValue = currentValue + currentValue * amount; // Logic: val += val * amount
            super.value = newValue;
          }

          // Override the 'add' method
          @override
          int add(int otherValue) {
            // Access state via the bridged superclass getter
            int currentValue = super.value;
            final result = (currentValue + otherValue) * 2; // Logic: (val + other) * 2
            return result;
          }
        }

        main() {
          final oc = OverridenCounter(10, 'override-test');

          // Call the overridden increment() method (amount = 1 by default)
          // Expected value: 10 + 10 * 1 = 20
          oc.increment();
          final valueAfterIncrement = oc.value;

          // Call the overridden add(5) method
          // Current value is 20. Expected result: (20 + 5) * 2 = 50
          final addResult = oc.add(5);

          // Return the results for verification
          return [valueAfterIncrement, addResult];
        }
      ''';

      final result = interpreter.execute(source: source);

      // Check that the results match the overridden logic
      expect(result, equals([20, 50]));
    });

    test('Call native methods on extracted native object', () {
      final source = '''
        import 'package:test/counter.dart';
        // Interpreted class inheriting from the bridged class
        class OverridenCounter extends Counter {
          OverridenCounter(int initialValue, String id) : super(initialValue, id);

          // Overload (will NOT be called by the native Dart test)
          @override
          void increment([int amount = 1]) {
            super.value = super.value + super.value * amount; // Different logic
          }

          // Overload (will NOT be called by the native Dart test)
          @override
          int add(int otherValue) {
            return (super.value + otherValue) * 2; // Different logic
          }
        }

        main() {
          // Return the interpreted instance
          return OverridenCounter(10, 'native-call-test');
        }
      ''';

      // Execute the interpreted code
      final result = interpreter.execute(source: source);

      // Check that the result is an interpreted instance
      expect(result, isA<InterpretedInstance>());
      final interpretedInstance = result as InterpretedInstance;

      // Check that the super bridged object is a NativeCounter
      expect(interpretedInstance.bridgedSuperObject, isA<NativeCounter>());
      final nativeCounter =
          interpretedInstance.bridgedSuperObject as NativeCounter;

      // Call increment() DIRECTLY on the NativeCounter object
      nativeCounter
          .increment(2); // Must use NativeCounter.increment: 10 + 2 = 12
      expect(nativeCounter.value, equals(12),
          reason: 'Native increment(2) should result in 12');

      // Call add() DIRECTLY on the NativeCounter object
      final addResult =
          nativeCounter.add(5); // Must use NativeCounter.add: 12 + 5 = 17
      expect(addResult, equals(17),
          reason: 'Native add(5) should result in 17');
      expect(nativeCounter.value,
          equals(12), // The value should not change with native add()
          reason: 'Value should still be 12 after native add()');
    });

    test('Invoke overridden methods via interpreter.invoke', () {
      final source = '''
        import 'package:test/counter.dart';
        class OverridenCounter extends Counter {
          OverridenCounter(int initialValue, String id) : super(initialValue, id);

          @override
          void increment([int amount = 1]) {
            // Overridden logic: val += val * amount
            super.value = super.value + super.value * amount;
          }

          @override
          int add(int otherValue) {
             // Overridden logic: (val + other) * 2
            final result = (super.value + otherValue) * 2;
            return result;
          }
        }

        main() {
          return OverridenCounter(10, 'invoke-test');
        }
      ''';

      // Get the interpreted instance
      final result = interpreter.execute(source: source);
      expect(result, isA<InterpretedInstance>(),
          reason: 'Interpreter should return InterpretedInstance');
      final interpretedInstance = result as InterpretedInstance;
      final nativeObject = result.getNativeObject<NativeCounter>();
      if (nativeObject != null) {
        nativeObject.add(5, instance: interpretedInstance);
      }

      // Call 'increment(2)' via invoke - MUST use the override
      // Initial value = 10. Logic: 10 + 10 * 2 = 30
      interpreter.invoke(
        'increment',
        [2], // Positional argument
      );

      // Check the resulting value by calling the 'value' getter via invoke
      final valueAfterIncrement = interpreter.invoke(
        'value', // Call the getter as a method with no arguments
        [], // No arguments for a getter
      );
      expect(valueAfterIncrement, equals(30),
          reason: 'Value should be 30 after overridden increment(2)');

      // Call 'add(5)' via invoke - MUST use the overload
      // Current value = 30. Logic: (30 + 5) * 2 = 70
      final addResult = interpreter.invoke(
        'add',
        [5], // Positional argument
      );
      expect(addResult, equals(70),
          reason: 'add(5) should return 70 based on overridden logic');

      // Re-check the value - it should not change due to add()
      final valueAfterAdd = interpreter.invoke(
        'value',
        [],
      );
      expect(valueAfterAdd, equals(30),
          reason: 'Value should remain 30 after overridden add(5)');
    });

    test('invoke on simple interpreted instance method', () {
      final source = '''
        import 'package:test/counter.dart';
        class Simple {
          String message = "initial";
          String doWork(String prefix) {
            message = prefix + ": worked";
            return message;
          }
        }
        main() => Simple(); // Returns the instance
      ''';

      final instance =
          interpreter.execute(source: source) as InterpretedInstance;
      expect(instance, isNotNull);

      final result = interpreter.invoke('doWork', ['TestPrefix']);
      expect(result, equals('TestPrefix: worked'));

      // Check that the state has been modified
      // (requires a getter or another invoke call)
      // Let's add a getter to verify
    });

    test('invoke on simple interpreted instance getter', () {
      final source = '''
        import 'package:test/counter.dart';
        class Simple {
          String _data = "secret";
          String get data => _data;
          void setData(String val) { _data = val; }
        }
        main() => Simple(); // Returns the instance
      ''';
      final instance =
          interpreter.execute(source: source) as InterpretedInstance;
      expect(instance, isNotNull);

      // Call the getter
      var result = interpreter.invoke('data', []);
      expect(result, equals('secret'));

      // Modify the data via a method to prove that the getter reads the current state
      interpreter.invoke('setData', ['new_value']);
      result = interpreter.invoke('data', []);
      expect(result, equals('new_value'));
    });

    test('invoke on overridden method with interpreted super call', () {
      final source = '''
        class Base {
          String work(String input) => "Base:" + input;
        }
        class Derived extends Base {
          @override
          String work(String input) => "Derived:" + super.work(input);
        }
        main() => Derived();
      ''';
      final instance =
          interpreter.execute(source: source) as InterpretedInstance;
      expect(instance, isNotNull);

      final result = interpreter.invoke('work', ['data']);
      expect(result, equals('Derived:Base:data'));
    });

    test('invoke throws error for non-existent method/getter', () {
      final source = '''
        class Empty {}
        main() => Empty();
      ''';
      final instance =
          interpreter.execute(source: source) as InterpretedInstance;
      expect(instance, isNotNull);

      expect(
        () => interpreter.invoke('nonExistent', []),
        throwsA(isA<RuntimeError>().having(
          (e) => e.message,
          'message',
          contains('Method or getter "nonExistent" not found'),
        )),
      );
    });

    test('Invoke overridden methods on instance with extra field via invoke',
        () {
      final source = '''
        import 'package:test/counter.dart';
        class OverridenCounter extends Counter {
          final String stock;
          // Constructor using the bridged constructor of the superclass
          // and initializing the extra field 'stock'.
          OverridenCounter(int initialValue, String id, this.stock) : super(initialValue, id);

          // Getter to access the 'stock' field from outside via invoke
          String get myStock => this.stock;

          // Override the 'increment' method
          @override
          void increment([int amount = 1]) {
            // Use this.stock (or just stock) to access the field of this class
            // Overridden logic: val += val * amount
            super.value = super.value + super.value * amount;
          }

          // Override the 'add' method
          @override
          int add(int otherValue) {
             // Overridden logic: (val + other) * 2
            final result = (super.value + otherValue) * 2;
            return result;
          }
        }

        main() {
          // Returns the interpreted instance of OverridenCounter
          return OverridenCounter(10, 'invoke-test-stock', 'stockXYZ');
        }
      ''';

      interpreter.execute(source: source);
      // final instance = interpreter.execute(source: source) as InterpretedInstance;

      // 1. Check the initial state (via invoke on the 'value' getter of Counter)
      var currentValue = interpreter.invoke('value', []);
      expect(currentValue, equals(10), reason: "Initial value should be 10");

      // 2. Call the overloaded 'increment'
      // The logic is: super.value = super.value + super.value * amount
      // 10 + 10 * 2 = 30
      interpreter.invoke('increment', [2]);
      currentValue = interpreter.invoke('value', []);
      expect(currentValue, equals(30),
          reason: "Value should be 30 after overridden increment(2)");

      // 3. Call the overloaded 'add'
      // The logic is: (super.value + otherValue) * 2
      // (30 + 5) * 2 = 70
      final addResult = interpreter.invoke('add', [5]);
      expect(addResult, equals(70),
          reason: "Result of overridden add(5) should be 70");

      // Check that 'value' has not been modified by 'add' (since add does not do super.value = ...)
      currentValue = interpreter.invoke('value', []);
      expect(currentValue, equals(30),
          reason:
              "Value should still be 30 after add(), as add is non-mutating for value");

      // 4. Check the access to the 'stock' field via the 'myStock' getter
      final stockValue = interpreter.invoke('myStock', []);
      expect(stockValue, equals('stockXYZ'),
          reason: "Stock value should be 'stockXYZ'");
    });
    test('Invoke static method on instance with extra field via invoke', () {
      final source = '''
        import 'package:test/counter.dart';
        class OverridenCounter extends Counter {
          final String stock;
          OverridenCounter(int initialValue, String id, this.stock) : super(initialValue, id);
          static const String test1 = 'test1';

          String getTest1() => test1;

        }

      String main() {
          return OverridenCounter(10, 'invoke-test-stock', 'stockXYZ').getTest1();
        }
      ''';

      expect(interpreter.execute(source: source), equals('test1'));
    });
  });
}
