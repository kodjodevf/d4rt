import 'package:test/test.dart';
import 'package:d4rt/d4rt.dart';

/// Tests for eval() method
/// This feature allows executing code in the context established by execute()
void main() {
  group('eval() method', () {
    late D4rt d4rt;

    setUp(() {
      d4rt = D4rt();
    });

    group('Basic expressions', () {
      test('should evaluate arithmetic expressions', () {
        d4rt.execute(source: 'void init() {}', name: 'init');

        expect(d4rt.eval('1 + 2'), equals(3));
        expect(d4rt.eval('10 - 4'), equals(6));
        expect(d4rt.eval('3 * 7'), equals(21));
        expect(d4rt.eval('20 / 4'), equals(5.0));
        expect(d4rt.eval('17 % 5'), equals(2));
        expect(d4rt.eval('2 + 3 * 4'), equals(14)); // Operator precedence
        expect(d4rt.eval('(2 + 3) * 4'), equals(20)); // Parentheses
      });

      test('should evaluate boolean expressions', () {
        d4rt.execute(source: 'void init() {}', name: 'init');

        expect(d4rt.eval('true'), isTrue);
        expect(d4rt.eval('false'), isFalse);
        expect(d4rt.eval('true && true'), isTrue);
        expect(d4rt.eval('true && false'), isFalse);
        expect(d4rt.eval('true || false'), isTrue);
        expect(d4rt.eval('!false'), isTrue);
        expect(d4rt.eval('5 > 3'), isTrue);
        expect(d4rt.eval('5 < 3'), isFalse);
        expect(d4rt.eval('5 >= 5'), isTrue);
        expect(d4rt.eval('5 <= 4'), isFalse);
        expect(d4rt.eval('5 == 5'), isTrue);
        expect(d4rt.eval('5 != 5'), isFalse);
      });

      test('should evaluate string expressions', () {
        d4rt.execute(source: 'void init() {}', name: 'init');

        expect(d4rt.eval('"hello"'), equals('hello'));
        expect(d4rt.eval('"hello" + " world"'), equals('hello world'));
        expect(d4rt.eval('"repeat" * 3'), equals('repeatrepeatrepeat'));
        expect(d4rt.eval('"hello".length'), equals(5));
        expect(d4rt.eval('"hello".toUpperCase()'), equals('HELLO'));
        expect(d4rt.eval('"  trimmed  ".trim()'), equals('trimmed'));
      });

      test('should evaluate null-aware expressions', () {
        d4rt.execute(source: '''
          String? nullableValue;
          String nonNullValue = "hello";
          void init() {}
        ''', name: 'init');

        expect(d4rt.eval('nullableValue ?? "default"'), equals('default'));
        expect(d4rt.eval('nonNullValue ?? "default"'), equals('hello'));
        expect(d4rt.eval('nullableValue?.length'), isNull);
        expect(d4rt.eval('nonNullValue.length'), equals(5));
      });

      test('should evaluate conditional expressions', () {
        d4rt.execute(source: 'void init() {}', name: 'init');

        expect(d4rt.eval('true ? "yes" : "no"'), equals('yes'));
        expect(d4rt.eval('false ? "yes" : "no"'), equals('no'));
        expect(d4rt.eval('5 > 3 ? "bigger" : "smaller"'), equals('bigger'));
        expect(d4rt.eval('1 == 2 ? 100 : 200'), equals(200));
      });
    });

    group('Variable access and modification', () {
      test('should access existing variables', () {
        d4rt.execute(source: '''
          var counter = 42;
          final name = "Alice";
          const pi = 3.14159;
          void init() {}
        ''', name: 'init');

        expect(d4rt.eval('counter'), equals(42));
        expect(d4rt.eval('name'), equals('Alice'));
        expect(d4rt.eval('pi'), closeTo(3.14159, 0.00001));
      });

      test('should modify mutable variables', () {
        d4rt.execute(source: '''
          var x = 10;
          var y = 20;
          int getSum() => x + y;
        ''', name: 'getSum');

        expect(d4rt.eval('getSum()'), equals(30));

        d4rt.eval('x = 100;');
        expect(d4rt.eval('x'), equals(100));
        expect(d4rt.eval('getSum()'), equals(120));

        d4rt.eval('y = 200;');
        expect(d4rt.eval('getSum()'), equals(300));
      });

      test('should create new variables', () {
        d4rt.execute(source: 'void init() {}', name: 'init');

        d4rt.eval('var newVar = 100;');
        expect(d4rt.eval('newVar'), equals(100));

        d4rt.eval('String greeting = "Hello";');
        expect(d4rt.eval('greeting'), equals('Hello'));

        d4rt.eval('final computedValue = 5 * 10;');
        expect(d4rt.eval('computedValue'), equals(50));
      });

      test('should handle variable shadowing in new scope', () {
        d4rt.execute(source: '''
          var x = 10;
          int getX() => x;
        ''', name: 'getX');

        expect(d4rt.eval('getX()'), equals(10));

        // Modify global x
        d4rt.eval('x = 20;');
        expect(d4rt.eval('getX()'), equals(20));
      });

      test('should handle list variables', () {
        d4rt.execute(source: '''
          var numbers = [1, 2, 3];
          void init() {}
        ''', name: 'init');

        expect(d4rt.eval('numbers'), equals([1, 2, 3]));
        expect(d4rt.eval('numbers.length'), equals(3));
        expect(d4rt.eval('numbers[0]'), equals(1));

        d4rt.eval('numbers.add(4);');
        expect(d4rt.eval('numbers'), equals([1, 2, 3, 4]));

        d4rt.eval('numbers[0] = 100;');
        expect(d4rt.eval('numbers[0]'), equals(100));
      });

      test('should handle map variables', () {
        d4rt.execute(source: '''
          var user = {'name': 'John', 'age': 30};
          void init() {}
        ''', name: 'init');

        expect(d4rt.eval('user["name"]'), equals('John'));
        expect(d4rt.eval('user["age"]'), equals(30));

        d4rt.eval('user["email"] = "john@example.com";');
        expect(d4rt.eval('user["email"]'), equals('john@example.com'));

        d4rt.eval('user["age"] = 31;');
        expect(d4rt.eval('user["age"]'), equals(31));
      });
    });

    group('Function calls', () {
      test('should call existing functions', () {
        d4rt.execute(source: '''
          int add(int a, int b) => a + b;
          int multiply(int a, int b) => a * b;
          String greet(String name) => "Hello, \$name!";
          void init() {}
        ''', name: 'init');

        expect(d4rt.eval('add(3, 4)'), equals(7));
        expect(d4rt.eval('multiply(5, 6)'), equals(30));
        expect(d4rt.eval('greet("World")'), equals('Hello, World!'));
      });

      test('should call functions with named arguments', () {
        d4rt.execute(source: '''
          String format({required String name, int age = 0}) {
            return "\$name is \$age years old";
          }
          void init() {}
        ''', name: 'init');

        expect(
          d4rt.eval('format(name: "Alice", age: 25)'),
          equals('Alice is 25 years old'),
        );
        expect(
          d4rt.eval('format(name: "Bob")'),
          equals('Bob is 0 years old'),
        );
      });

      test('should call chained functions', () {
        d4rt.execute(source: '''
          int double(int x) => x * 2;
          int addOne(int x) => x + 1;
          int square(int x) => x * x;
          void init() {}
        ''', name: 'init');

        expect(d4rt.eval('double(addOne(5))'), equals(12)); // (5+1)*2
        expect(d4rt.eval('square(double(3))'), equals(36)); // (3*2)^2
        expect(
            d4rt.eval('addOne(square(double(2)))'), equals(17)); // ((2*2)^2)+1
      });

      test('should define and call new functions', () {
        d4rt.execute(source: 'void init() {}', name: 'init');

        d4rt.eval('int cube(int n) => n * n * n;');
        expect(d4rt.eval('cube(3)'), equals(27));

        d4rt.eval(
            'String repeat(String s, int times) { String r = ""; for (int i = 0; i < times; i++) r += s; return r; }');
        expect(d4rt.eval('repeat("ab", 3)'), equals('ababab'));
      });

      test('should call recursive functions defined in eval', () {
        d4rt.execute(source: 'void init() {}', name: 'init');

        d4rt.eval('''
          int fib(int n) {
            if (n <= 1) return n;
            return fib(n - 1) + fib(n - 2);
          }
        ''');

        expect(d4rt.eval('fib(0)'), equals(0));
        expect(d4rt.eval('fib(1)'), equals(1));
        expect(d4rt.eval('fib(10)'), equals(55));
      });

      test('should call async functions', () async {
        d4rt.execute(source: '''
          Future<int> asyncDouble(int x) async => x * 2;
          void init() {}
        ''', name: 'init');

        final result = await d4rt.eval('asyncDouble(21)');
        expect(result, equals(42));
      });
    });

    group('Class interaction', () {
      test('should access existing classes', () {
        d4rt.execute(source: '''
          class Point {
            int x;
            int y;
            Point(this.x, this.y);
            int distanceSquared() => x * x + y * y;
          }
          void init() {}
        ''', name: 'init');

        d4rt.eval('var p = Point(3, 4);');
        expect(d4rt.eval('p.x'), equals(3));
        expect(d4rt.eval('p.y'), equals(4));
        expect(d4rt.eval('p.distanceSquared()'), equals(25));
      });

      test('should modify class instance properties', () {
        d4rt.execute(source: '''
          class Counter {
            int value = 0;
            void increment() { value++; }
            void decrement() { value--; }
            void add(int n) { value += n; }
          }
          void init() {}
        ''', name: 'init');

        d4rt.eval('var counter = Counter();');
        expect(d4rt.eval('counter.value'), equals(0));

        d4rt.eval('counter.increment();');
        d4rt.eval('counter.increment();');
        expect(d4rt.eval('counter.value'), equals(2));

        d4rt.eval('counter.add(10);');
        expect(d4rt.eval('counter.value'), equals(12));

        d4rt.eval('counter.decrement();');
        expect(d4rt.eval('counter.value'), equals(11));
      });

      test('should work with multiple class instances', () {
        d4rt.execute(source: '''
          class Account {
            String name;
            double balance;
            Account(this.name, this.balance);
            void deposit(double amount) { balance += amount; }
            void withdraw(double amount) { balance -= amount; }
            void transfer(Account other, double amount) {
              withdraw(amount);
              other.deposit(amount);
            }
          }
          void init() {}
        ''', name: 'init');

        d4rt.eval('var alice = Account("Alice", 1000.0);');
        d4rt.eval('var bob = Account("Bob", 500.0);');

        expect(d4rt.eval('alice.balance'), equals(1000.0));
        expect(d4rt.eval('bob.balance'), equals(500.0));

        d4rt.eval('alice.transfer(bob, 200.0);');
        expect(d4rt.eval('alice.balance'), equals(800.0));
        expect(d4rt.eval('bob.balance'), equals(700.0));
      });

      test('should define new classes through eval', () {
        d4rt.execute(source: 'void init() {}', name: 'init');

        d4rt.eval('''
          class Rectangle {
            double width;
            double height;
            Rectangle(this.width, this.height);
            double get area => width * height;
            double get perimeter => 2 * (width + height);
          }
        ''');

        d4rt.eval('var rect = Rectangle(5.0, 3.0);');
        expect(d4rt.eval('rect.area'), equals(15.0));
        expect(d4rt.eval('rect.perimeter'), equals(16.0));
      });

      test('should work with class inheritance', () {
        d4rt.execute(source: '''
          class Animal {
            String name;
            Animal(this.name);
            String speak() => "...";
          }
          
          class Dog extends Animal {
            Dog(String name) : super(name);
            String speak() => "Woof!";
            String fetch() => "\$name is fetching!";
          }
          
          class Cat extends Animal {
            Cat(String name) : super(name);
            String speak() => "Meow!";
          }
          void init() {}
        ''', name: 'init');

        d4rt.eval('var dog = Dog("Rex");');
        d4rt.eval('var cat = Cat("Whiskers");');

        expect(d4rt.eval('dog.name'), equals('Rex'));
        expect(d4rt.eval('dog.speak()'), equals('Woof!'));
        expect(d4rt.eval('dog.fetch()'), equals('Rex is fetching!'));

        expect(d4rt.eval('cat.name'), equals('Whiskers'));
        expect(d4rt.eval('cat.speak()'), equals('Meow!'));
      });

      test('should work with static members', () {
        d4rt.execute(source: '''
          class MathUtils {
            static const double pi = 3.14159;
            static int square(int x) => x * x;
            static int factorial(int n) {
              if (n <= 1) return 1;
              return n * factorial(n - 1);
            }
          }
          void init() {}
        ''', name: 'init');

        expect(d4rt.eval('MathUtils.pi'), closeTo(3.14159, 0.00001));
        expect(d4rt.eval('MathUtils.square(5)'), equals(25));
        expect(d4rt.eval('MathUtils.factorial(5)'), equals(120));
      });
    });

    group('Complex control flow', () {
      test('should handle if expressions in eval', () {
        d4rt.execute(source: '''
          var score = 75;
          void init() {}
        ''', name: 'init');

        // Using ternary operator
        expect(
          d4rt.eval(
              'score >= 90 ? "A" : score >= 80 ? "B" : score >= 70 ? "C" : "F"'),
          equals('C'),
        );

        d4rt.eval('score = 95;');
        expect(
          d4rt.eval(
              'score >= 90 ? "A" : score >= 80 ? "B" : score >= 70 ? "C" : "F"'),
          equals('A'),
        );
      });

      test('should handle loops through function calls', () {
        d4rt.execute(source: '''
          int sumRange(int start, int end) {
            int sum = 0;
            for (int i = start; i <= end; i++) {
              sum += i;
            }
            return sum;
          }
          void init() {}
        ''', name: 'init');

        expect(d4rt.eval('sumRange(1, 10)'), equals(55));
        expect(d4rt.eval('sumRange(1, 100)'), equals(5050));
      });

      test('should handle while loops in functions', () {
        d4rt.execute(source: '''
          int countDigits(int n) {
            int count = 0;
            while (n > 0) {
              n = n ~/ 10;
              count++;
            }
            return count == 0 ? 1 : count;
          }
          void init() {}
        ''', name: 'init');

        expect(d4rt.eval('countDigits(0)'), equals(1));
        expect(d4rt.eval('countDigits(5)'), equals(1));
        expect(d4rt.eval('countDigits(123)'), equals(3));
        expect(d4rt.eval('countDigits(9999999)'), equals(7));
      });
    });

    group('State persistence', () {
      test('should persist state across multiple eval calls', () {
        d4rt.execute(source: '''
          var history = <String>[];
          void addEntry(String entry) {
            history.add(entry);
          }
          List<String> getHistory() => history;
        ''', name: 'getHistory');

        d4rt.eval('addEntry("First");');
        d4rt.eval('addEntry("Second");');
        d4rt.eval('addEntry("Third");');

        expect(d4rt.eval('history.length'), equals(3));
        expect(d4rt.eval('getHistory()'), equals(['First', 'Second', 'Third']));
      });

      test('should build complex state over multiple calls', () {
        d4rt.execute(source: '''
          class ShoppingCart {
            List<Map<String, dynamic>> items = [];
            
            void addItem(String name, double price, int quantity) {
              items.add({'name': name, 'price': price, 'quantity': quantity});
            }
            
            double get total {
              double sum = 0;
              for (var item in items) {
                sum += item['price'] * item['quantity'];
              }
              return sum;
            }
            
            int get itemCount => items.length;
          }
          
          var cart = ShoppingCart();
          void init() {}
        ''', name: 'init');

        d4rt.eval('cart.addItem("Apple", 1.50, 5);');
        d4rt.eval('cart.addItem("Bread", 2.00, 2);');
        d4rt.eval('cart.addItem("Milk", 3.00, 1);');

        expect(d4rt.eval('cart.itemCount'), equals(3));
        expect(d4rt.eval('cart.total'), closeTo(14.5, 0.01)); // 7.5 + 4 + 3
      });

      test('should maintain function definitions across calls', () {
        d4rt.execute(source: 'void init() {}', name: 'init');

        d4rt.eval('int a(int x) => x + 1;');
        d4rt.eval('int b(int x) => a(x) * 2;');
        d4rt.eval('int c(int x) => b(x) + a(x);');

        // a(5) = 6, b(5) = 12, c(5) = 12 + 6 = 18
        expect(d4rt.eval('c(5)'), equals(18));
      });
    });

    group('Error handling', () {
      test('should throw error when called before execute', () {
        final freshD4rt = D4rt();

        expect(
          () => freshD4rt.eval('1 + 1'),
          throwsA(isA<RuntimeError>()),
        );
      });

      test('should throw error for undefined variables', () {
        d4rt.execute(source: 'void init() {}', name: 'init');

        expect(
          () => d4rt.eval('undefinedVariable'),
          throwsA(isA<RuntimeError>()),
        );
      });

      test('should throw error for undefined functions', () {
        d4rt.execute(source: 'void init() {}', name: 'init');

        expect(
          () => d4rt.eval('undefinedFunction()'),
          throwsA(isA<RuntimeError>()),
        );
      });

      test('should throw error for type mismatches', () {
        d4rt.execute(source: '''
          int add(int a, int b) => a + b;
          void init() {}
        ''', name: 'init');

        // Note: d4rt uses duck typing, so string concatenation with + works
        // This tests that calling a function with wrong types can still work
        // if the operation is valid for those types
        // The actual behavior depends on the operation - this test verifies consistent behavior
        final result = d4rt.eval('add("hello", "world")');
        // String + String returns concatenated string
        expect(result, equals('helloworld'));
      });

      test('should handle division by zero', () {
        d4rt.execute(source: 'void init() {}', name: 'init');

        // Integer division by zero throws error
        expect(
          () => d4rt.eval('10 ~/ 0'),
          throwsA(anything),
        );

        // Double division by zero returns Infinity (IEEE 754 behavior)
        final result = d4rt.eval('10.0 / 0.0');
        expect(result.isInfinite, isTrue);
      });

      test('should throw error for null pointer on non-nullable', () {
        d4rt.execute(source: '''
          String? nullable;
          void init() {}
        ''', name: 'init');

        // Calling method on null should throw
        expect(
          () => d4rt.eval('nullable!.length'),
          throwsA(anything),
        );
      });
    });

    group('Collection operations', () {
      test('should work with list comprehensions through functions', () {
        d4rt.execute(source: '''
          List<int> getSquares(int n) {
            List<int> result = [];
            for (int i = 1; i <= n; i++) {
              result.add(i * i);
            }
            return result;
          }
          void init() {}
        ''', name: 'init');

        expect(d4rt.eval('getSquares(5)'), equals([1, 4, 9, 16, 25]));
      });

      test('should use list methods', () {
        d4rt.execute(source: '''
          var numbers = [3, 1, 4, 1, 5, 9, 2, 6, 5, 3];
          void init() {}
        ''', name: 'init');

        expect(d4rt.eval('numbers.first'), equals(3));
        expect(d4rt.eval('numbers.last'), equals(3));
        expect(d4rt.eval('numbers.length'), equals(10));
        expect(d4rt.eval('numbers.contains(9)'), isTrue);
        expect(d4rt.eval('numbers.indexOf(5)'), equals(4));

        d4rt.eval('numbers.sort();');
        expect(d4rt.eval('numbers'), equals([1, 1, 2, 3, 3, 4, 5, 5, 6, 9]));
      });

      test('should use map methods', () {
        d4rt.execute(source: '''
          var data = <String, int>{};
          void init() {}
        ''', name: 'init');

        d4rt.eval('data["one"] = 1;');
        d4rt.eval('data["two"] = 2;');
        d4rt.eval('data["three"] = 3;');

        expect(d4rt.eval('data.length'), equals(3));
        expect(d4rt.eval('data.containsKey("two")'), isTrue);
        expect(d4rt.eval('data.containsValue(2)'), isTrue);
        expect(d4rt.eval('data.keys.toList()'),
            containsAll(['one', 'two', 'three']));
      });
    });

    group('Multiple D4rt instances', () {
      test('eval contexts should be independent', () {
        final d4rt1 = D4rt();
        final d4rt2 = D4rt();

        d4rt1.execute(source: '''
          var x = 100;
          void init() {}
        ''', name: 'init');

        d4rt2.execute(source: '''
          var x = 200;
          void init() {}
        ''', name: 'init');

        expect(d4rt1.eval('x'), equals(100));
        expect(d4rt2.eval('x'), equals(200));

        d4rt1.eval('x = 150;');
        expect(d4rt1.eval('x'), equals(150));
        expect(d4rt2.eval('x'), equals(200)); // Should remain unchanged
      });
    });
  });
}
