import 'package:d4rt/src/utils/extensions/interpreted_instance.dart';
import 'package:test/test.dart';
import 'package:d4rt/d4rt.dart';

// 1. Classe Native pour les tests
class NativeCounter {
  static int _staticCounter = 0;
  int _value;
  final String id;
  bool _isDisposed = false; // Pour tester les méthodes sur état détruit

  // Constructeur par défaut
  NativeCounter(this._value, [this.id = 'default']);

  // Constructeur nommé
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

  // Méthode pour tester les arguments
  int add(int otherValue, {InterpretedInstance? instance}) {
    if (_isDisposed) throw StateError('Instance disposed');
    final result = _value + otherValue;
    return result;
  }

  // Méthode pour tester le passage d'instance pontée
  bool isSame(NativeCounter other) {
    if (_isDisposed) throw StateError('Instance disposed');
    return id == other.id && _value == other._value;
  }

  // Méthode pour simuler la libération de ressources
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

      // Réinitialiser le compteur statique avant chaque test
      NativeCounter._staticCounter = 0;

      // 2. Définition de la classe pontée pour NativeCounter
      final counterDefinition = BridgedClassDefinition(
        nativeType: NativeCounter,
        name: 'Counter', // Nom dans l'interpréteur
        constructors: {
          // Constructeur par défaut: Counter(value, [id])
          '': (InterpreterVisitor visitor, List<Object?> positionalArgs,
              Map<String, Object?> namedArgs) {
            // Vérifier le nombre d'arguments
            if (positionalArgs.isEmpty || positionalArgs.length > 2) {
              throw ArgumentError(
                  'Default constructor requires 1 or 2 positional arguments, got ${positionalArgs.length}');
            }
            // Vérifier le type du premier argument (value)
            if (positionalArgs[0] is! int) {
              throw ArgumentError(
                  'Default constructor first argument (value) must be an integer, got ${positionalArgs[0]?.runtimeType}');
            }
            final value = positionalArgs[0] as int;

            // Gérer l'argument optionnel (id)
            String id = 'default';
            if (positionalArgs.length > 1) {
              // Vérifier que l'argument est bien un String ou null
              if (positionalArgs[1] != null && positionalArgs[1] is! String) {
                throw ArgumentError(
                    'Default constructor second argument (id) must be a string or null, got ${positionalArgs[1]?.runtimeType}');
              }
              // Assigner si non null, sinon garder 'default'
              if (positionalArgs[1] != null) {
                id = positionalArgs[1] as String;
              }
            }
            // Appeler le constructeur natif
            return NativeCounter(value, id);
          },
          // Constructeur nommé: Counter.withId(id, initialValue: 0)
          'withId': (InterpreterVisitor visitor, List<Object?> positionalArgs,
              Map<String, Object?> namedArgs) {
            // Vérifier l'argument positionnel (id)
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw ArgumentError(
                  'Named constructor \'withId\' expects exactly 1 positional string argument (id), got ${positionalArgs.isNotEmpty ? positionalArgs[0]?.runtimeType : 'none'}');
            }
            final id = positionalArgs[0] as String;

            // Vérifier l'argument nommé optionnel (initialValue)
            int initialValue = 0;
            if (namedArgs.containsKey('initialValue')) {
              if (namedArgs['initialValue'] is! int?) {
                throw ArgumentError(
                    'Named argument \'initialValue\' for constructor \'withId\' must be an int?, got ${namedArgs['initialValue']?.runtimeType}');
              }
              // Accepter null comme initialValue et le traiter comme 0
              initialValue = namedArgs['initialValue'] as int? ?? 0;
            }
            // Appeler le constructeur natif nommé
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

      // Enregistrer la classe pontée
      interpreter.registerBridgedClass(counterDefinition);

      // 3. Définition du pont pour AsyncProcessor
      final asyncProcessorDefinition = BridgedClassDefinition(
        nativeType: AsyncProcessor,
        name: 'AsyncProcessor', // Nom dans l'interpréteur
        constructors: {
          // Constructeur: AsyncProcessor(id)
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
              // Assumons que Duration est ponté ou natif
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
              // L'adaptateur retourne directement le Future<NativeCounter>.
              // L'interpréteur devra gérer l'attente et le pontage du résultat NativeCounter.
              return target
                  .createCounterAsync(
                      positionalArgs[0] as int, positionalArgs[1] as String)
                  .then((nativeCounter) {
                return nativeCounter;
              });
            }
            throw ArgumentError('Invalid arguments for createCounterAsync');
          },
          // processor.alwaysFail(message) -> Future<String> (qui échoue)
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
              // Appelle la méthode native synchrone
              return target.createCounterSync(
                  positionalArgs[0] as int, positionalArgs[1] as String);
            }
            throw ArgumentError('Invalid arguments for createCounterSync');
          }
        },
        // Pas de membres statiques ou de getters/setters pour cet exemple
        staticGetters: {},
        staticSetters: {},
        staticMethods: {},
        getters: {},
        setters: {},
      );

      // Enregistrer AsyncProcessor
      interpreter.registerBridgedClass(asyncProcessorDefinition);
    });

    test('Call default constructor', () {
      final code = '''
        main() {
          var c = Counter(10);
          return c.value;
        }
      ''';
      expect(interpreter.execute(code), equals(10));
    });

    test('Call default constructor with optional ID', () {
      final code = '''
        main() {
          var c = Counter(20, 'my-counter');
          return c.id;
        }
      ''';
      expect(interpreter.execute(code), equals('my-counter'));
    });

    test('Call named constructor', () {
      final code = '''
        main() {
          var c = Counter.withId('specific-id');
          return [c.id, c.value];
        }
      ''';
      expect(interpreter.execute(code), equals(['specific-id', 0]));
    });

    test('Call named constructor with named argument', () {
      final code = '''
        main() {
          var c = Counter.withId('other-id', initialValue: 55);
           return [c.id, c.value];
        }
      ''';
      expect(interpreter.execute(code), equals(['other-id', 55]));
    });

    test('Access static getter', () {
      NativeCounter.staticValue = 99; // Set native value directly
      final code = '''
        main() { return Counter.staticValue; }
      ''';
      expect(interpreter.execute(code), equals(99));
    });

    test('Use static setter', () {
      final code = '''
        main() {
           Counter.staticValue = 123;
           return Counter.staticValue;
         }
      ''';
      expect(interpreter.execute(code), equals(123));
      expect(
          NativeCounter.staticValue, equals(123)); // Verify native side effect
    });

    test('Call static method', () {
      NativeCounter.staticValue = 0; // Reset static counter
      final code = '''
        main() {
          var r1 = Counter.staticMethod('prefix1');
          var r2 = Counter.staticMethod('prefix2');
          return [r1, r2, Counter.staticValue];
        }
      ''';
      expect(interpreter.execute(code),
          equals(['prefix1:static:1', 'prefix2:static:2', 2]));
    });

    test('Access instance getter', () {
      final code = '''
        main() {
          var c = Counter(7, 'getter-test');
          return [c.value, c.id, c.description];
        }
      ''';
      expect(interpreter.execute(code),
          equals([7, 'getter-test', 'Counter(getter-test):7']));
    });

    test('Use instance setter', () {
      final code = '''
         main() {
           var c = Counter(5);
           c.value = 25;
           return c.value;
         }
       ''';
      expect(interpreter.execute(code), equals(25));
    });

    test('Call instance method (no args)', () {
      final code = '''
         main() {
           var c = Counter(100);
           c.increment();
           return c.value;
         }
       ''';
      expect(interpreter.execute(code), equals(101));
    });

    test('Call instance method (with args)', () {
      final code = '''
         main() {
           var c = Counter(10);
           c.increment(5);
           var sum = c.add(3);
           return [c.value, sum];
         }
       ''';
      expect(interpreter.execute(code), equals([15, 18]));
    });

    test('Pass bridged instance as argument', () {
      final code = '''
         main() {
           var c1 = Counter(50, 'ID-A');
           var c2 = Counter(50, 'ID-A');
           var c3 = Counter(55, 'ID-A');
           var c4 = Counter(50, 'ID-B');
           return [c1.isSame(c2), c1.isSame(c3), c1.isSame(c4)];
         }
       ''';
      expect(interpreter.execute(code), equals([true, false, false]));
    });

    test('Error: Call non-existent constructor', () {
      final code = "main() { return Counter.nonExistent(); }";
      expect(
          () => interpreter.execute(code),
          throwsA(isA<RuntimeError>().having(
              (e) => e.message,
              'message',
              contains(
                  "Bridged class 'Counter' has no constructor or static method named 'nonExistent'"))));
    });

    test('Error: Call default constructor with wrong arg type', () {
      final code = "main() { return Counter('wrong'); }"; // Expects int
      expect(
          () => interpreter.execute(code),
          throwsA(isA<RuntimeError>().having(
              (e) => e.message,
              'message',
              contains(
                  "Native error during default bridged constructor for 'Counter'"))));
    });

    test('Error: Call named constructor with wrong arg type', () {
      final code = "main() { return Counter.withId(123); }"; // Expects String
      expect(
          () => interpreter.execute(code),
          throwsA(isA<RuntimeError>().having((e) => e.message, 'message',
              contains("Native error during bridged constructor"))));
    });

    test('Error: Access non-existent static member', () {
      final code = "main() { return Counter.nonExistentStatic; }";
      expect(
          () => interpreter.execute(code),
          throwsA(isA<RuntimeError>().having((e) => e.message, 'message',
              contains("Undefined static member 'nonExistentStatic'"))));
    });

    test('Error: Call non-existent static method', () {
      final code = "main() { return Counter.nonExistentStaticMethod(); }";
      expect(
          () => interpreter.execute(code),
          throwsA(isA<RuntimeError>().having(
              (e) => e.message,
              'message',
              contains(
                  "Bridged class 'Counter' has no constructor or static method named 'nonExistentStaticMethod'"))));
    });

    test('Error: Access non-existent instance member', () {
      final code = '''
         main() {
           var c = Counter(1);
           return c.nonExistentMember;
         }
       ''';
      // This error comes from the fallback mechanism after bridge check fails
      expect(
          () => interpreter.execute(code),
          throwsA(isA<RuntimeError>().having(
              (e) => e.message,
              'message',
              contains(
                  "Undefined property or method 'nonExistentMember' on bridged instance of 'Counter'"))));
    });

    test('Error: Call non-existent instance method', () {
      final code = '''
         main() {
           var c = Counter(1);
           return c.nonExistentMethod();
         }
       ''';
      expect(
          () => interpreter.execute(code),
          throwsA(isA<RuntimeError>().having(
              (e) => e.message,
              'message',
              contains(
                  "Bridged class 'Counter' has no instance method named 'nonExistentMethod'"))));
    });

    test('Error: Call instance method with wrong args', () {
      final code = '''
         main() {
           var c = Counter(1);
           return c.add('wrong'); // Expects int
         }
       ''';
      expect(
          () => interpreter.execute(code),
          throwsA(isA<RuntimeError>().having((e) => e.message, 'message',
              contains("Native error during bridged method call 'add'"))));
    });

    test('Error: Call method on disposed instance', () {
      final code = '''
         main() {
           var c = Counter(1);
           c.dispose();
           return c.value; // Should throw
         }
       ''';
      expect(
          () => interpreter.execute(code),
          throwsA(isA<RuntimeError>().having((e) => e.message, 'message',
              contains("Unexpected error: Bad state: Instance disposed"))));
    });

    test('Dart class inheriting from bridged class', () {
      final source = '''
        class Employee extends Counter {
          String department;

          // Constructeur appelant super() par défaut
          Employee(int initialValue, String id, this.department)
              : super(initialValue, id); // Appelle Counter(value, id)

          // Constructeur appelant super.withId()
          Employee.withIdDept(String id, this.department, {int initialValue = 5})
              : super.withId(id, initialValue: initialValue); // Appelle Counter.withId(id, initialValue: x)

          String getEmployeeInfo() {
            // Accès à 'id' et 'value' (hérités) et 'department' (dérivé)
            return "Employee \$id in \$department, value: \$value";
          }
        }

        main() {
         final emp1 = Employee(10, 'emp1', 'Sales');
        final emp2 = Employee.withIdDept('emp2', 'Tech', initialValue: 25);

        emp1.increment(); // Méthode héritée
        final emp1Value = emp1.value; // Getter hérité
        final emp1Info = emp1.getEmployeeInfo(); // Méthode dérivée

        final emp2Value = emp2.value;
        final emp2Info = emp2.getEmployeeInfo();

        // Retourner les résultats pour vérification
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

      final result = interpreter.execute(source);

      // Vérifications
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
        import 'dart:async'; // Import nécessaire pour Duration

        main() async {
          final processor = AsyncProcessor('p1');
          final result = await processor.delayedSuccess('hello', Duration(milliseconds: 20));
          return result;
        }
      ''';
      // Utiliser execute pour les fonctions main async
      final result = await interpreter.execute(code);
      expect(result, equals('Processed (p1): hello'));
    });

    test('Await bridged method returning Future<int> with args', () async {
      final code = '''
        main() async {
          final processor = AsyncProcessor('p2');
          final value = await processor.calculateAsync(15);
          return value;
        }
      ''';
      final result = await interpreter.execute(code);
      expect(result, equals(30));
    });

    test('Await bridged method returning Future', () async {
      final code = '''
        main() async {
          final processor = AsyncProcessor('p3');
          await processor.doSomethingAsync();
          return 'done'; // Retourne quelque chose pour vérifier que l'await a terminé
        }
      ''';
      final result = await interpreter.execute(code);
      expect(result, equals('done'));
      // On peut aussi vérifier les logs de la console si nécessaire
    });

    test('Await bridged method returning Future<BridgedInstance>', () async {
      final code = '''
         import 'dart:async';

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
      final result = await interpreter.execute(code);
      expect(result, equals(105));
    });

    test('Try/catch await on bridged method returning Future.error', () async {
      final code = '''
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
      final result = await interpreter.execute(code);
      expect(
          result,
          contains(
              'Caught: Exception: Failure from AsyncProcessor (p5): something went wrong'));
    });

    test('Sync bridged method returning BridgedInstance', () {
      final source = '''
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
      // Fin de la chaîne multi-lignes
      // Utiliser execute (synchrone)
      final result = interpreter.execute(source);
      expect(result, equals(210));
    });

    test('Override bridged class methods', () {
      final source = '''
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

      final result = interpreter.execute(source);

      // Check that the results match the overridden logic
      expect(result, equals([20, 50]));
    });

    test('Call native methods on extracted native object', () {
      final source = '''
        // Classe interprétée héritant de classe pontée
        class OverridenCounter extends Counter {
          OverridenCounter(int initialValue, String id) : super(initialValue, id);

          // Surcharge (ne sera PAS appelée par le test Dart natif)
          @override
          void increment([int amount = 1]) {
            super.value = super.value + super.value * amount; // Logique différente
          }

          // Surcharge (ne sera PAS appelée par le test Dart natif)
          @override
          int add(int otherValue) {
            return (super.value + otherValue) * 2; // Logique différente
          }
        }

        main() {
          // Retourne l'instance interprétée
          return OverridenCounter(10, 'native-call-test');
        }
      ''';

      // Exécuter le code interprété
      final result = interpreter.execute(source);

      // Vérifier que le résultat est une instance interprétée
      expect(result, isA<InterpretedInstance>());
      final interpretedInstance = result as InterpretedInstance;

      // Vérifier que l'objet super ponté est bien un NativeCounter
      expect(interpretedInstance.bridgedSuperObject, isA<NativeCounter>());
      final nativeCounter =
          interpretedInstance.bridgedSuperObject as NativeCounter;

      // Appeler increment() DIRECTEMENT sur l'objet NATIVECOUNTER
      nativeCounter
          .increment(2); // Doit utiliser NativeCounter.increment: 10 + 2 = 12
      expect(nativeCounter.value, equals(12),
          reason: 'Native increment(2) should result in 12');

      // Appeler add() DIRECTEMENT sur l'objet NATIVECOUNTER
      final addResult =
          nativeCounter.add(5); // Doit utiliser NativeCounter.add: 12 + 5 = 17
      expect(addResult, equals(17),
          reason: 'Native add(5) should result in 17');
      expect(nativeCounter.value,
          equals(12), // La valeur ne change pas avec add() natif
          reason: 'Value should still be 12 after native add()');
    });

    test('Invoke overridden methods via interpreter.invoke', () {
      final source = '''
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
      final result = interpreter.execute(source);
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

      // Appeler 'add(5)' via invoke - DOIT utiliser la surcharge
      // Valeur courante = 30. Logique: (30 + 5) * 2 = 70
      final addResult = interpreter.invoke(
        'add',
        [5], // Argument positionnel
      );
      expect(addResult, equals(70),
          reason: 'add(5) should return 70 based on overridden logic');

      // Revérifier la valeur - elle ne devrait pas changer à cause de add()
      final valueAfterAdd = interpreter.invoke(
        'value',
        [],
      );
      expect(valueAfterAdd, equals(30),
          reason: 'Value should remain 30 after overridden add(5)');
    });

    test('invoke on simple interpreted instance method', () {
      final source = '''
        class Simple {
          String message = "initial";
          String doWork(String prefix) {
            message = prefix + ": worked";
            return message;
          }
        }
        main() => Simple(); // Retourne l'instance
      ''';

      final instance = interpreter.execute(source) as InterpretedInstance;
      expect(instance, isNotNull);

      final result = interpreter.invoke('doWork', ['TestPrefix']);
      expect(result, equals('TestPrefix: worked'));

      // Vérifier que l'état a été modifié
      // (nécessite un getter ou un autre appel invoke)
      // Ajoutons un getter pour vérifier
    });

    test('invoke on simple interpreted instance getter', () {
      final source = '''
        class Simple {
          String _data = "secret";
          String get data => _data;
          void setData(String val) { _data = val; }
        }
        main() => Simple(); // Retourne l'instance
      ''';
      final instance = interpreter.execute(source) as InterpretedInstance;
      expect(instance, isNotNull);

      // Appeler le getter
      var result = interpreter.invoke('data', []);
      expect(result, equals('secret'));

      // Modifier la donnée via une méthode pour prouver que le getter lit l'état actuel
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
      final instance = interpreter.execute(source) as InterpretedInstance;
      expect(instance, isNotNull);

      final result = interpreter.invoke('work', ['data']);
      expect(result, equals('Derived:Base:data'));
    });

    test('invoke throws error for non-existent method/getter', () {
      final source = '''
        class Empty {}
        main() => Empty();
      ''';
      final instance = interpreter.execute(source) as InterpretedInstance;
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

      interpreter.execute(source);
      // final instance = interpreter.execute(source) as InterpretedInstance;

      // 1. Vérifier l'état initial (via invoke sur le getter 'value' de Counter)
      var currentValue = interpreter.invoke('value', []);
      expect(currentValue, equals(10), reason: "Initial value should be 10");

      // 2. Appeler 'increment' surchargé
      // La logique est: super.value = super.value + super.value * amount
      // 10 + 10 * 2 = 30
      interpreter.invoke('increment', [2]);
      currentValue = interpreter.invoke('value', []);
      expect(currentValue, equals(30),
          reason: "Value should be 30 after overridden increment(2)");

      // 3. Appeler 'add' surchargé
      // La logique est: (super.value + otherValue) * 2
      // (30 + 5) * 2 = 70
      final addResult = interpreter.invoke('add', [5]);
      expect(addResult, equals(70),
          reason: "Result of overridden add(5) should be 70");

      // Vérifier que 'value' n'a pas été modifié par 'add' (car add ne fait pas super.value = ...)
      currentValue = interpreter.invoke('value', []);
      expect(currentValue, equals(30),
          reason:
              "Value should still be 30 after add(), as add is non-mutating for value");

      // 4. Vérifier l'accès au champ 'stock' via le getter 'myStock'
      final stockValue = interpreter.invoke('myStock', []);
      expect(stockValue, equals('stockXYZ'),
          reason: "Stock value should be 'stockXYZ'");
    });
    test('Invoke static method on instance with extra field via invoke', () {
      final source = '''
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

      expect(interpreter.execute(source), equals('test1'));
    });
  });
}
