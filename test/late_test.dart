import 'package:test/test.dart';
import 'package:d4rt/d4rt.dart';

Object? execute(String source) {
  final interpreter = D4rt();
  return interpreter.execute(source: source);
}

void main() {
  group('Late keyword tests', () {
    test('late variable declaration without initialization', () {
      final code = '''
        main() {
          late String name;
          name = "Hello";
          return name;
        }
      ''';
      expect(execute(code), equals("Hello"));
    });

    test('late variable with lazy initialization', () {
      final code = '''
        String expensiveComputation() {
          print("Computing...");
          return "Expensive result";
        }
        
        main() {
          late String result = expensiveComputation();
          // Should not compute until accessed
          return result; // This should trigger computation
        }
      ''';
      expect(execute(code), equals("Expensive result"));
    });

    test('late final variable', () {
      final code = '''
        main() {
          late final String name;
          name = "Hello";
          return name;
        }
      ''';
      expect(execute(code), equals("Hello"));
    });

    test('late instance field', () {
      final code = '''
        class Person {
          late String name;
          
          void setName(String n) {
            name = n;
          }
          
          String getName() {
            return name;
          }
        }
        
        main() {
          var person = Person();
          person.setName("Alice");
          return person.getName();
        }
      ''';
      expect(execute(code), equals("Alice"));
    });

    test('late static field', () {
      final code = '''
        class Config {
          static late String appName;
          
          static void init() {
            appName = "MyApp";
          }
        }
        
        main() {
          Config.init();
          return Config.appName;
        }
      ''';
      expect(execute(code), equals("MyApp"));
    });

    test('accessing uninitialized late variable should throw', () {
      final code = '''
        main() {
          late String name;
          return name;
        }
      ''';
      expect(() => execute(code), throwsA(isA<RuntimeError>()));
    });

    test('late variable with lazy initialization only called once', () {
      final code = '''
        int callCount = 0;
        
        String expensiveComputation() {
          callCount++;
          return "Result \$callCount";
        }
        
        main() {
          late String result = expensiveComputation();
          
          // Access multiple times
          String first = result;
          String second = result;
          
          return [first, second, callCount];
        }
      ''';
      final result = execute(code) as List;
      expect(result[0], equals("Result 1"));
      expect(result[1], equals("Result 1")); // Same result
      expect(result[2], equals(1)); // Only called once
    });

    test('late final variable reassignment should throw', () {
      final code = '''
        main() {
          late final String name;
          name = "First";
          name = "Second"; // Should throw LateInitializationError
          return name;
        }
      ''';
      expect(() => execute(code), throwsA(isA<LateInitializationError>()));
    });

    test('late final variable with initializer reassignment should throw', () {
      final code = '''
        main() {
          late final String name = "Initial";
          var first = name; // Triggers initialization
          name = "Second"; // Should throw LateInitializationError
          return name;
        }
      ''';
      expect(() => execute(code), throwsA(isA<LateInitializationError>()));
    });

    test('late variable in constructor parameter', () {
      final code = '''
        class User {
          late String email;
          
          User(String e) {
            email = e;
          }
          
          String getEmail() {
            return email;
          }
        }
        
        main() {
          var user = User("test@example.com");
          return user.getEmail();
        }
      ''';
      expect(execute(code), equals("test@example.com"));
    });

    test('late instance field with lazy initialization', () {
      final code = '''
        class DataProcessor {
          late String processedData = computeData();
          
          String computeData() {
            return "Processed: \${DateTime.now().millisecondsSinceEpoch}";
          }
          
          String getData() {
            return processedData;
          }
        }
        
        main() {
          var processor = DataProcessor();
          var data = processor.getData();
          return data.startsWith("Processed: ");
        }
      ''';
      expect(execute(code), equals(true));
    });

    test('late static field with lazy initialization', () {
      final code = '''
        class Settings {
          static late String config = loadConfig();
          
          static String loadConfig() {
            return "default-config";
          }
          
          static String getConfig() {
            return config;
          }
        }
        
        main() {
          return Settings.getConfig();
        }
      ''';
      expect(execute(code), equals("default-config"));
    });

    test('late variable with complex expression initializer', () {
      final code = '''
        List<String> createList() {
          return ["a", "b", "c"];
        }
        
        main() {
          late List<String> items = createList();
          return items.length;
        }
      ''';
      expect(execute(code), equals(3));
    });

    test('late variable with null value', () {
      final code = '''
        main() {
          late String? nullableString;
          nullableString = null;
          return nullableString;
        }
      ''';
      expect(execute(code), equals(null));
    });

    test('late variable in function scope', () {
      final code = '''
        String processInFunction() {
          late String result;
          result = "function-scope";
          return result;
        }
        
        main() {
          return processInFunction();
        }
      ''';
      expect(execute(code), equals("function-scope"));
    });

    test('late variable with conditional assignment', () {
      final code = '''
        main() {
          bool condition = true;
          late String message;
          
          if (condition) {
            message = "condition-true";
          } else {
            message = "condition-false";
          }
          
          return message;
        }
      ''';
      expect(execute(code), equals("condition-true"));
    });

    test('multiple late variables in same declaration', () {
      final code = '''
        main() {
          late String first, second;
          first = "one";
          second = "two";
          return [first, second];
        }
      ''';
      final result = execute(code) as List;
      expect(result[0], equals("one"));
      expect(result[1], equals("two"));
    });

    test('late variable with compound assignment', () {
      final code = '''
        main() {
          late int counter = 5;
          counter += 10;
          return counter;
        }
      ''';
      expect(execute(code), equals(15));
    });

    test('late variable accessing other late variable', () {
      final code = '''
        main() {
          late String base = "hello";
          late String derived = base + " world";
          return derived;
        }
      ''';
      expect(execute(code), equals("hello world"));
    });

    test('late variable in loop', () {
      final code = '''
        main() {
          var results = <String>[];
          for (int i = 0; i < 3; i++) {
            late String item = "item-\$i";
            results.add(item);
          }
          return results;
        }
      ''';
      final result = execute(code) as List;
      expect(result, equals(["item-0", "item-1", "item-2"]));
    });

    test('late variable with recursive initialization', () {
      final code = '''
        int fibonacci(int n) {
          if (n <= 1) return n;
          return fibonacci(n - 1) + fibonacci(n - 2);
        }
        
        main() {
          late int fib10 = fibonacci(10);
          return fib10;
        }
      ''';
      expect(execute(code), equals(55));
    });

    test('late static final field', () {
      final code = '''
        class Constants {
          static late final String appVersion = computeVersion();
          
          static String computeVersion() {
            return "1.0.0";
          }
          
          static String getVersion() {
            return appVersion;
          }
        }
        
        main() {
          return Constants.getVersion();
        }
      ''';
      expect(execute(code), equals("1.0.0"));
    });

    test('late static final field reassignment should throw', () {
      final code = '''
        class Constants {
          static late final String appVersion;
          
          static void setVersion(String version) {
            appVersion = version;
          }
          
          static void resetVersion() {
            appVersion = "reset"; // Should throw on second assignment
          }
        }
        
        main() {
          Constants.setVersion("1.0.0");
          Constants.resetVersion(); // This should throw
          return Constants.appVersion;
        }
      ''';
      expect(() => execute(code), throwsA(isA<RuntimeError>()));
    });

    test('late instance final field', () {
      final code = '''
        class ImmutableData {
          late final String id;
          
          ImmutableData(String identifier) {
            id = identifier;
          }
          
          String getId() {
            return id;
          }
        }
        
        main() {
          var data = ImmutableData("abc123");
          return data.getId();
        }
      ''';
      expect(execute(code), equals("abc123"));
    });

    test('late instance final field reassignment should throw', () {
      final code = '''
        class ImmutableData {
          late final String id;
          
          void setId(String identifier) {
            id = identifier;
          }
          
          void resetId() {
            id = "reset"; // Should throw if already set
          }
          
          String getId() {
            return id;
          }
        }
        
        main() {
          var data = ImmutableData();
          data.setId("first");
          try {
            data.resetId(); // This should throw
            return "no-error";
          } catch (e) {
            return "error-caught";
          }
        }
      ''';
      expect(execute(code), equals("error-caught"));
    });

    test('late variable with exception in initializer', () {
      final code = '''
        String throwingFunction() {
          throw "Initializer failed";
        }
        
        main() {
          late String result = throwingFunction();
          try {
            return result; // Should propagate the exception
          } catch (e) {
            return "caught-error";
          }
        }
      ''';
      expect(execute(code), equals("caught-error"));
    });

    test('late variable assignment in try-catch', () {
      final code = '''
        main() {
          late String result;
          
          try {
            result = "success";
          } catch (e) {
            result = "error";
          }
          
          return result;
        }
      ''';
      expect(execute(code), equals("success"));
    });

    test('late variable with getter/setter pattern', () {
      final code = '''
        class DataContainer {
          late String _data;
          
          String get data => _data;
          
          set data(String value) {
            _data = value.toUpperCase();
          }
        }
        
        main() {
          var container = DataContainer();
          container.data = "hello";
          return container.data;
        }
      ''';
      expect(execute(code), equals("HELLO"));
    });

    test('late top-level variable', () {
      final code = '''
        late String globalConfig;
        
        void initializeGlobal() {
          globalConfig = "global-value";
        }
        
        main() {
          initializeGlobal();
          return globalConfig;
        }
      ''';
      expect(execute(code), equals("global-value"));
    });

    test('late top-level variable with initializer', () {
      final code = '''
        String computeGlobal() {
          return "computed-global";
        }
        
        late String globalData = computeGlobal();
        
        main() {
          return globalData;
        }
      ''';
      expect(execute(code), equals("computed-global"));
    });

    test('late variable circular dependency should work', () {
      final code = '''
        class CircularTest {
          static late String first = "First: " + getSecond();
          static late String second = "Second";
          
          static String getFirst() {
            return first;
          }
          
          static String getSecond() {
            return second;
          }
        }
        
        main() {
          return CircularTest.getFirst();
        }
      ''';
      expect(execute(code), equals("First: Second"));
    });

    test('late variable with separate class access', () {
      final code = '''
        class Outer {
          static late String outerData = "outer";
          
          static String getOuterData() {
            return outerData;
          }
        }
        
        class Inner {
          static late String innerData = Outer.getOuterData() + "-inner";
          
          static String getInnerData() {
            return innerData;
          }
        }
        
        main() {
          return Inner.getInnerData();
        }
      ''';
      expect(execute(code), equals("outer-inner"));
    });

    test('late variable with async-like pattern', () {
      final code = '''
        String simulateAsync() {
          // Simulate some computation
          return "async-result";
        }
        
        main() {
          late String result = simulateAsync();
          
          // Do other work first
          var other = "other-work";
          
          // Now access the late variable
          return result + "-" + other;
        }
      ''';
      expect(execute(code), equals("async-result-other-work"));
    });
  });
}
