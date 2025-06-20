import 'package:test/test.dart';

import '../interpreter_test.dart';

void main() {
  group('Class Tests', () {
    test('Basic class instantiation (implicit constructor)', () {
      const source = '''
        class Simple {
          int x = 10;
        }

        main() {
          var s = Simple();
          return s.x;
        }
      ''';
      expect(execute(source), equals(10));
    });

    test('Class instantiation (explicit default constructor)', () {
      const source = '''
        class Simple {
          int x = 5;
          Simple() { // Explicit default constructor
            x = 20;
          }
        }

        main() {
          var s = Simple();
          return s.x;
        }
      ''';
      expect(execute(source), equals(20));
    });

    test('Field access and update', () {
      const source = '''
        class Box {
          var content = 'initial';
        }

        main() {
          var box = Box();
          var v1 = box.content;
          box.content = 'updated';
          var v2 = box.content;
          return [v1, v2];
        }
      ''';
      expect(execute(source), equals(['initial', 'updated']));
    });

    test('Instance method call (no parameters)', () {
      const source = '''
        class Greeter {
          String greet() {
            return 'Hello!';
          }
        }

        main() {
          var g = Greeter();
          return g.greet();
        }
      ''';
      expect(execute(source), equals('Hello!'));
    });

    test('Instance method call (with parameters)', () {
      const source = '''
        class Adder {
          int add(int a, int b) {
            return a + b;
          }
        }

        main() {
          var adder = Adder();
          return adder.add(5, 3);
        }
      ''';
      expect(execute(source), equals(8));
    });

    test('Instance method using instance fields', () {
      const source = '''
        class Counter {
          int count = 0;
          void increment() {
            count = count + 1;
          }
          int getValue() {
             return count;
          }
        }

        main() {
          var c = Counter();
          c.increment();
          c.increment();
          return c.getValue();
        }
      ''';
      expect(execute(source), equals(2));
    });

    test('Constructor with positional parameters', () {
      const source = '''
        class Points {
          int x, y;
          Points(int x_param, int y_param) {
            x = x_param;
            y = y_param;
          }
        }

        main() {
          var p = Points(10, 20);
          return [p.x, p.y];
        }
      ''';
      expect(execute(source), equals([10, 20]));
    });

    test('Constructor using \'this.fieldName\' syntax', () {
      const source = '''
        class Points {
          int x, y;
          Points(this.x, this.y);
        }

        main() {
          var p = Points(3, 4);
          return [p.x, p.y];
        }
      ''';
      expect(execute(source), equals([3, 4]));
    });

    test('Named constructor', () {
      const source = '''
        class Points {
          int x = 0, y = 0;
          Points(); // Default constructor
          Points.origin() {
            x = 0;
            y = 0;
          }
          Points.at(int pos) {
            x = pos;
            y = pos;
          }
        }

        main() {
          var p1 = Points.origin();
          var p2 = Points.at(5);
          return [p1.x, p1.y, p2.x, p2.y];
        }
      ''';

      expect(execute(source), equals([0, 0, 5, 5]));
    });

    group('Inheritance', () {
      test('Basic inheritance: Accessing superclass members', () {
        const source = '''
          class Animal {
            String name = 'Generic';
            String sound() => '?';
          }

          class Dog extends Animal {
             // Inherits name and sound
          }

          main() {
            var d = Dog();
            return [d.name, d.sound()];
          }
        ''';

        expect(execute(source), equals(['Generic', '?']));
      });

      test('Method overriding', () {
        const source = '''
          class Animal {
            String sound() => '?';
          }

          class Cat extends Animal {
            String sound() => 'Meow'; // Overrides superclass method
          }

          main() {
            Animal myPet = Cat();
            return myPet.sound(); // Should call Cat's sound()
          }
        ''';
        expect(execute(source), equals('Meow'));
      });

      test('Constructor with super call (implicit)', () {
        const source = '''
            class Base {
              String id;
              Base() { // Explicit default constructor in base
                id = 'base_default';
              }
            }
            class Derived extends Base {
              // Implicit super() call here
              Derived(); 
            }
            main() {
              var d = Derived();
              return d.id;
            }
          ''';
        expect(execute(source), equals('base_default'));
      });

      test('Constructor with explicit super call', () {
        const source = '''
          class Base {
            int value;
            Base(this.value);
          }

          class Derived extends Base {
            Derived(int val) : super(val * 2);
          }

          main() {
            var d = Derived(10);
            return d.value; // Should be 10 * 2 = 20
          }
        ''';
        // Requires parsing/execution of SuperConstructorInvocation
        expect(execute(source), equals(20));
      });
    });

    group('Getters and Setters', () {
      test('Simple getter', () {
        const source = '''
          class Box {
            int _content = 5;
            int get content => _content * 10;
          }
          main() {
            var b = Box();
            return b.content;
          }
        ''';
        expect(execute(source), equals(50));
      });

      test('Simple setter', () {
        const source = '''
          class Box {
            int _value = 0;
            int get value => _value;
            set value(int newValue) {
              _value = newValue + 1; // Add 1 in setter
            }
          }
          main() {
            var b = Box();
            b.value = 10;
            return b.value; // Getter should return 10 + 1 = 11
          }
        ''';
        expect(execute(source), equals(11));
      });

      test('Getter/Setter interaction', () {
        const source = '''
          class Circle {
            num radius = 0;
            num get area => 3.14 * radius * radius;
            set diameter(num d) {
              radius = d / 2;
            }
            num get diameter => radius * 2;
          }
          main() {
            var c = Circle();
            c.diameter = 10;
            return [c.radius, c.diameter, c.area]; 
          }
        ''';
        // area = 3.14 * 5 * 5 = 78.5
        expect(execute(source), equals([5, 10, 78.5]));
      });
    });
    test('Basic class with constructor', () {
      final result = execute('''
        class Person {
          String name;
          int age;
          
          Person(this.name, this.age);
          
          String introduce() => 'Hello, I am \$name and I am \$age years old';
        }
        
        String main() {
          final person = Person('Alice', 30);
          return person.introduce();
        }
      ''');
      expect(result, equals('Hello, I am Alice and I am 30 years old'));
    });

    test('Class with named constructor', () {
      final result = execute('''
        class Points {
          double x;
          double y;
          
          Points(this.x, this.y);
          
          Points.origin() : this(0, 0);
          
          Points.fromJson(Map<String, double> json) 
            : x = json['x'] ?? 0,
              y = json['y'] ?? 0;
        }
        
         main() {
          final p1 = Points(1, 2);
          final p2 = Points.origin();
          final p3 = Points.fromJson({'x': 3, 'y': 4});
          return [p1.x, p1.y, p2.x, p2.y, p3.x, p3.y];
        }
      ''');
      expect(result, equals([1, 2, 0, 0, 3, 4]));
    });

    test('Class with getters and setters', () {
      final result = execute('''
        class Rectangles {
          double _width;
          double _height;
          
          Rectangles(this._width, this._height);
          
          double get width => _width;
          set width(double value) => _width = value;
          
          double get height => _height;
          set height(double value) => _height = value;
          
          double get area => _width * _height;
          
          double get perimeter => 2 * (_width + _height);
        }
        
         main() {
          final rect = Rectangles(5, 10);
          rect.width = 6;
          rect.height = 12;
          return [rect.area, rect.perimeter];
        }
      ''');
      expect(result, equals([72, 36]));
    });

    test('Class inheritance with method override', () {
      final result = execute('''
        class Animal {
          String name;
          
          Animal(this.name);
          
          String speak() => '...';
        }
        
        class Dog extends Animal {
          Dog(String name) : super(name);
          
          @override
          String speak() => 'Woof!';
        }
        
        class Cat extends Animal {
          Cat(String name) : super(name);
          
          @override
          String speak() => 'Meow!';
        }
        
       main() {
          final dog = Dog('Rex');
          final cat = Cat('Whiskers');
          return [dog.speak(), cat.speak()];
        }
      ''');
      expect(result, equals(['Woof!', 'Meow!']));
    });

    test('Complex class hierarchy with abstract class', () {
      final result = execute('''
        abstract class Shape {
          Shape();
          double get area;
          double get perimeter;
        }
        
        class Circle extends Shape {
          double radius;
          
          Circle(this.radius);
          
          @override
          double get area => 3.14159 * radius * radius;
          
          @override
          double get perimeter => 2 * 3.14159 * radius;
        }
        
        class Square extends Shape {
          double side;
          
          Square(this.side);
          
          @override
          double get area => side * side;
          
          @override
          double get perimeter => 4 * side;
        }
        
         main() {
          final circle = Circle(5);
          final square = Square(4);
          return [circle.area, circle.perimeter, square.area, square.perimeter];
        }
      ''');
      expect(result, equals([78.53975, 31.4159, 16, 16]));
    });

    test('Class with mixin', () {
      final result = execute('''
        mixin Flyable {
          void fly() => print('Flying...');
        }
        
        mixin Swimmable {
          void swim() => print('Swimming...');
        }
        
        class Duck with Flyable, Swimmable {
          void doEverything() {
            fly();
            swim();
          }
        }
        
         main() {
          final duck = Duck();
          duck.doEverything();
          return true;
        }
      ''');
      expect(result, equals(true));
    });
    test('Named constructor with named parameters', () {
      const source = '''
        class Points {
          double? x;
          double? y;

          Points({this.x, this.y});  

          Points.fromJson(Map<String, double> json) {
            x = json['x'] ?? 0;
            y = json['y'] ?? 0;
          }
        }

        main() {
          final p1 = Points(x: 1, y: 2);
          final p3 = Points.fromJson({'x': 3, 'y': 4});
          return [p1.x, p1.y, p3.x, p3.y];
        }

      ''';

      expect(execute(source), equals([1, 2, 3, 4]));
    });

    test('Complex class interaction', () {
      final result = execute('''
        class BankAccount {
          String owner;
          double _balance;

          BankAccount(this.owner, this._balance);

          double get balance => _balance;

          void deposit(double amount) {
            if (amount > 0) _balance += amount;
          }

          void withdraw(double amount) {
            if (amount > 0 && amount <= _balance) _balance -= amount;
          }
        }

        class SavingsAccount extends BankAccount {
          double _interestRate;

          SavingsAccount(String owner, double balance, this._interestRate)
              : super(owner, balance);

          void addInterest() {
            final interestAmount = balance * _interestRate;
            deposit(interestAmount);
          }
        }

         main() {
          final account = SavingsAccount('Alice', 1000, 0.05);
          account.deposit(500);
          account.withdraw(200);
          account.addInterest();
          return account.balance;
        }
      ''');
      expect(result, equals(1365));
    });
    test('Simple', () {
      final result = execute('''
        class BankAccount {
          String owner;

          BankAccount(this.owner);

          double get balance => 100;

          int getBalance() {
            return balance;
          }
        }

        int main() {
          final bankAccount = BankAccount('John');
          return bankAccount.getBalance();
        }
      ''');
      expect(result, equals(100));
    });

    group('Binary Operators', () {
      test('Addition operator (+)', () {
        final result = execute('''
          class Money {
            final int cents;
            Money(this.cents);
            
            Money operator+(Money other) {
              return Money(this.cents + other.cents);
            }
            
            String toString() {
              return 'Money(\${cents} cents)';
            }
          }
          
          main() {
            var m1 = Money(100);
            var m2 = Money(200);
            var result = m1 + m2;
            return result.cents;
          }
        ''');
        expect(result, equals(300));
      });

      test('Equality operator (==)', () {
        final result = execute('''
          class Point {
            final int x;
            final int y;
            Point(this.x, this.y);
            
            bool operator==(Object other) {
              if (other is! Point) return false;
              return x == other.x && y == other.y;
            }
          }
          
          main() {
            var p1 = Point(1, 2);
            var p2 = Point(1, 2);
            var p3 = Point(2, 3);
            return [p1 == p2, p1 == p3];
          }
        ''');
        expect(result, equals([true, false]));
      });

      test('Comparison operators (< and >)', () {
        final result = execute('''
          class Temperature {
            final double celsius;
            Temperature(this.celsius);
            
            bool operator<(Temperature other) {
              return celsius < other.celsius;
            }
            
            bool operator>(Temperature other) {
              return celsius > other.celsius;
            }
          }
          
          main() {
            var t1 = Temperature(20.0);
            var t2 = Temperature(25.0);
            return [t1 < t2, t1 > t2];
          }
        ''');
        expect(result, equals([true, false]));
      });

      test('Multiple operators on same class', () {
        final result = execute('''
          class Vector {
            final double x;
            final double y;
            Vector(this.x, this.y);
            
            Vector operator+(Vector other) {
              return Vector(x + other.x, y + other.y);
            }
            
            Vector operator-(Vector other) {
              return Vector(x - other.x, y - other.y);
            }
            
            Vector operator*(double scalar) {
              return Vector(x * scalar, y * scalar);
            }
          }
          
          main() {
            var v1 = Vector(1.0, 2.0);
            var v2 = Vector(3.0, 4.0);
            var sum = v1 + v2;
            var diff = v1 - v2;
            var scaled = v1 * 2.0;
            
            return [
              [sum.x, sum.y],
              [diff.x, diff.y], 
              [scaled.x, scaled.y]
            ];
          }
        ''');
        expect(
            result,
            equals([
              [4.0, 6.0],
              [-2.0, -2.0],
              [2.0, 4.0]
            ]));
      });
    });

    group('Index Operators', () {
      test('Index operator ([])', () {
        final result = execute('''
          class NumberContainer {
            final List<int> numbers;
            NumberContainer(this.numbers);
            
            int operator[](int index) {
              return numbers[index];
            }
          }

          main() {
            var container = NumberContainer([10, 20, 30]);
            return [container[0], container[1], container[2]];
          }
        ''');
        expect(result, equals([10, 20, 30]));
      });

      test('Index assignment operator ([]=)', () {
        final result = execute('''
          class NumberContainer {
            final List<int> numbers;
            NumberContainer(this.numbers);
            
            int operator[](int index) {
              return numbers[index];
            }
            
            void operator[]=(int index, int value) {
              numbers[index] = value;
            }
          }

          main() {
            var container = NumberContainer([10, 20, 30]);
            container[1] = 99;
            return [container[0], container[1], container[2]];
          }
        ''');
        expect(result, equals([10, 99, 30]));
      });

      test('Compound assignment with index operators', () {
        final result = execute('''
          class NumberContainer {
            final List<int> numbers;
            NumberContainer(this.numbers);
            
            int operator[](int index) {
              return numbers[index];
            }
            
            void operator[]=(int index, int value) {
              numbers[index] = value;
            }
          }

          main() {
            var container = NumberContainer([10, 20, 30]);
            container[0] += 5;
            container[1] *= 2;
            container[2] -= 10;
            return [container[0], container[1], container[2]];
          }
        ''');
        expect(result, equals([15, 40, 20]));
      });

      test('String-keyed container with index operators', () {
        final result = execute('''
          class StringKeyedContainer {
            final Map<String, String> data = {};
            
            String operator[](String key) {
              return data[key] ?? 'not found';
            }
            
            void operator[]=(String key, String value) {
              data[key] = value;
            }
          }

          main() {
            var container = StringKeyedContainer();
            container['name'] = 'Alice';
            container['age'] = '30';
            
            return [container['name'], container['age'], container['unknown']];
          }
        ''');
        expect(result, equals(['Alice', '30', 'not found']));
      });

      test('Index operators with inheritance', () {
        final result = execute('''
          class BaseContainer {
            final List<dynamic> items;
            BaseContainer(this.items);
            
            dynamic operator[](int index) {
              return items[index];
            }
            
            void operator[]=(int index, dynamic value) {
              items[index] = value;
            }
          }

          class NumberContainer extends BaseContainer {
            NumberContainer(List<int> numbers) : super(numbers);
            
            // Inherited operators should work
          }

          main() {
            var container = NumberContainer([1, 2, 3]);
            container[0] = 100;
            return [container[0], container[1], container[2]];
          }
        ''');
        expect(result, equals([100, 2, 3]));
      });
    });

    group('Unary Operators', () {
      test('Unary minus operator (-)', () {
        final result = execute('''
          class Vector {
            final double x;
            final double y;
            Vector(this.x, this.y);
            
            Vector operator-() {
              return Vector(-x, -y);
            }
          }
          
          main() {
            var v = Vector(3.0, 4.0);
            var negV = -v;
            return [negV.x, negV.y];
          }
        ''');
        expect(result, equals([-3.0, -4.0]));
      });

      test('Bitwise NOT operator (~)', () {
        final result = execute('''
          class BitMask {
            final int value;
            BitMask(this.value);
            
            BitMask operator~() {
              return BitMask(~value);
            }
          }
          
          main() {
            var mask = BitMask(5); // Binary: 101
            var inverted = ~mask;  // Should invert all bits
            return inverted.value;
          }
        ''');
        expect(result, equals(~5)); // -6 in two's complement
      });

      test('Multiple unary operators on same class', () {
        final result = execute('''
          class SignedNumber {
            final int value;
            SignedNumber(this.value);
            
            SignedNumber operator-() {
              return SignedNumber(-value);
            }
            
            SignedNumber operator~() {
              return SignedNumber(~value);
            }
          }
          
          main() {
            var num = SignedNumber(10);
            var negated = -num;
            var inverted = ~num;
            
            return [negated.value, inverted.value];
          }
        ''');
        expect(result, equals([-10, ~10])); // [-10, -11]
      });

      test('Unary operators with inheritance', () {
        final result = execute('''
          class BaseNumber {
            final int value;
            BaseNumber(this.value);
            
            BaseNumber operator-() {
              return BaseNumber(-value);
            }
          }

          class ExtendedNumber extends BaseNumber {
            ExtendedNumber(int value) : super(value);
            
            // Inherited unary operator should work
          }

          main() {
            var num = ExtendedNumber(42);
            var negated = -num;
            return negated.value;
          }
        ''');
        expect(result, equals(-42));
      });

      test('Complex unary operator with custom logic', () {
        final result = execute('''
          class ComplexNumber {
            final double real;
            final double imaginary;
            ComplexNumber(this.real, this.imaginary);
            
            ComplexNumber operator-() {
              return ComplexNumber(-real, -imaginary);
            }
          }
          
          main() {
            var c = ComplexNumber(3.5, -2.1);
            var negated = -c;
            return [negated.real, negated.imaginary];
          }
        ''');
        expect(result, equals([-3.5, 2.1]));
      });

      test('Unary operator precedence over extensions', () {
        final result = execute('''
          class CustomInt {
            final int value;
            CustomInt(this.value);
            
            CustomInt operator-() {
              return CustomInt(value * -10); // Custom behavior, not just negation
            }
          }
          
          main() {
            var num = CustomInt(5);
            var result = -num;
            return result.value;
          }
        ''');
        expect(result, equals(-50)); // 5 * -10, not just -5
      });
    });

    group('Increment/Decrement Operators', () {
      test('Prefix increment on property access (++obj.field)', () {
        final result = execute('''
          class Counter {
            int count = 10;
          }
          
          main() {
            var counter = Counter();
            var newValue = ++counter.count;
            return [newValue, counter.count];
          }
        ''');
        expect(result, equals([11, 11]));
      });

      test('Postfix increment on property access (obj.field++)', () {
        final result = execute('''
          class Counter {
            int count = 5;
          }
          
          main() {
            var counter = Counter();
            var oldValue = counter.count++;
            return [oldValue, counter.count];
          }
        ''');
        expect(result, equals([5, 6]));
      });

      test('Prefix decrement on property access (--obj.field)', () {
        final result = execute('''
          class Counter {
            int count = 20;
          }
          
          main() {
            var counter = Counter();
            var newValue = --counter.count;
            return [newValue, counter.count];
          }
        ''');
        expect(result, equals([19, 19]));
      });

      test('Postfix decrement on property access (obj.field--)', () {
        final result = execute('''
          class Counter {
            int count = 15;
          }
          
          main() {
            var counter = Counter();
            var oldValue = counter.count--;
            return [oldValue, counter.count];
          }
        ''');
        expect(result, equals([15, 14]));
      });

      test('Prefix increment on index access (++array[i])', () {
        final result = execute('''
          main() {
            var list = [10, 20, 30];
            var newValue = ++list[1];
            return [newValue, list[1], list];
          }
        ''');
        expect(
            result,
            equals([
              21,
              21,
              [10, 21, 30]
            ]));
      });

      test('Postfix increment on index access (array[i]++)', () {
        final result = execute('''
          main() {
            var list = [5, 15, 25];
            var oldValue = list[0]++;
            return [oldValue, list[0], list];
          }
        ''');
        expect(
            result,
            equals([
              5,
              6,
              [6, 15, 25]
            ]));
      });

      test('Increment with custom class operators', () {
        final result = execute('''
          class CustomNumber {
            int value;
            CustomNumber(this.value);
            
            CustomNumber operator+(CustomNumber other) {
              return CustomNumber(value + other.value);
            }
          }
          
          main() {
            var num = CustomNumber(10);
            // This should use the custom + operator with CustomNumber(1)
            ++num; // Should call num = num + CustomNumber(1)
            return num.value;
          }
        ''');
        expect(result, equals(11));
      });
    });
  });
}
