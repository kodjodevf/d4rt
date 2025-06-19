import 'package:test/test.dart';
import '../lib/d4rt.dart';

void main() {
  late D4rt interpreter;

  setUp(() {
    interpreter = D4rt();
    interpreter.setDebug(true);
  });

  group('Basic Generics', () {
    test('Simple generic class declaration', () {
      final code = '''
        class Box<T> {
          T value;
          Box(this.value);
          T getValue() => value;
        }
        
        main() {
          var box = Box<int>(42);
          return box.getValue();
        }
      ''';
      expect(interpreter.execute(source: code), equals(42));
    });

    test('Generic class with multiple type parameters', () {
      final code = '''
        class Pair<T, U> {
          T first;
          U second;
          
          Pair(this.first, this.second);
          
          T getFirst() => first;
          U getSecond() => second;
        }
        
        main() {
          var pair = Pair<String, int>("hello", 42);
          return [pair.getFirst(), pair.getSecond()];
        }
      ''';
      expect(interpreter.execute(source: code), equals(["hello", 42]));
    });

    test('Generic method in non-generic class', () {
      final code = '''
        class Utils {
          static T identity<T>(T value) {
            return value;
          }
          
          T instanceIdentity<T>(T value) {
            return value;
          }
        }
        
        main() {
          var util = Utils();
          return [
            Utils.identity<String>("test"),
            util.instanceIdentity<int>(123)
          ];
        }
      ''';
      expect(interpreter.execute(source: code), equals(["test", 123]));
    });
  });

  group('Generic Constraints', () {
    test('Simple type constraint with extends', () {
      final code = '''
        abstract class Comparable<T> {
          int compareTo(T other);
        }
        
        class MyString implements Comparable<MyString> {
          String value;
          MyString(this.value);
          
          int compareTo(MyString other) {
            return value.length - other.value.length;
          }
        }
        
        class Container<T extends Comparable<T>> {
          T item;
          Container(this.item);
          
          bool isGreaterThan(T other) {
            return item.compareTo(other) > 0;
          }
        }
        
        main() {
          var container = Container<MyString>(MyString("hello"));
          var other = MyString("hi");
          return container.isGreaterThan(other);
        }
      ''';
      expect(interpreter.execute(source: code), equals(true));
    });

    test('Complex constraint with multiple bounds', () {
      final code = '''
        mixin Serializable {
          String serialize();
        }
        
        abstract class Named {
          String get name;
        }
        
        class Person extends Named with Serializable {
          String name;
          int age;
          
          Person(this.name, this.age);
          
          String serialize() => "\$name:\$age";
        }
        
        // Note: Dart doesn't support multiple extends, but we can test with mixins
        class Repository<T extends Named> {
          List<T> items = [];
          
          void add(T item) {
            items.add(item);
          }
          
          T? findByName(String name) {
            for (var item in items) {
              if (item.name == name) return item;
            }
            return null;
          }
        }
        
        main() {
          var repo = Repository<Person>();
          var person = Person("Alice", 30);
          repo.add(person);
          
          var found = repo.findByName("Alice");
          return found?.name ?? "not found";
        }
      ''';
      expect(interpreter.execute(source: code), equals("Alice"));
    });

    test('Type constraint violation should throw error', () {
      final code = '''
        class Container<T extends num> {
          T value;
          Container(this.value);
        }
        
        main() {
          // This should fail at compile time in real Dart
          // but we'll simulate with runtime check
          var container = Container<String>("hello");
          return container.value;
        }
      ''';
      expect(() => interpreter.execute(source: code),
          throwsA(isA<RuntimeError>()));
    });
  });

  group('Nested Generics', () {
    test('Generic class containing another generic type', () {
      final code = '''
        class Box<T> {
          T value;
          Box(this.value);
          T getValue() => value;
        }
        
        class Container<T> {
          List<T> items = [];
          
          void add(T item) {
            items.add(item);
          }
          
          List<T> getAll() => items;
        }
        
        main() {
          var container = Container<Box<String>>();
          var box1 = Box<String>("hello");
          var box2 = Box<String>("world");
          
          container.add(box1);
          container.add(box2);
          
          var items = container.getAll();
          return [items[0].getValue(), items[1].getValue()];
        }
      ''';
      expect(interpreter.execute(source: code), equals(["hello", "world"]));
    });

    test('Deeply nested generic types', () {
      final code = '''
        class Triple<A, B, C> {
          A first;
          B second;
          C third;
          
          Triple(this.first, this.second, this.third);
        }
        
        main() {
          // List<Map<String, Triple<int, bool, String>>>
          var complexData = <Map<String, Triple<int, bool, String>>>[];
          
          var map1 = <String, Triple<int, bool, String>>{};
          map1["item1"] = Triple<int, bool, String>(42, true, "test");
          
          complexData.add(map1);
          
          var retrieved = complexData[0]["item1"];
          return [retrieved!.first, retrieved.second, retrieved.third];
        }
      ''';
      expect(interpreter.execute(source: code), equals([42, true, "test"]));
    });

    test('Generic methods with nested type parameters', () {
      final code = '''
        class Transformer<T> {
          R transform<R>(T input, R Function(T) converter) {
            return converter(input);
          }
          
          List<R> transformList<R>(List<T> inputs, R Function(T) converter) {
            var results = <R>[];
            for (var input in inputs) {
              results.add(converter(input));
            }
            return results;
          }
        }
        
        main() {
          var transformer = Transformer<String>();
          
          // Transform single value
          var result1 = transformer.transform<int>("123", (s) => int.parse(s));
          
          // Transform list
          var result2 = transformer.transformList<int>(
            ["1", "2", "3"], 
            (s) => int.parse(s)
          );
          
          return [result1, result2];
        }
      ''';
      expect(
          interpreter.execute(source: code),
          equals([
            123,
            [1, 2, 3]
          ]));
    });
  });

  group('Complex Generic Scenarios', () {
    test('Generic inheritance with type parameter propagation', () {
      final code = '''
        abstract class Animal<T> {
          T makeSound();
        }
        
        abstract class Mammal<T> extends Animal<T> {
          bool hasFur = true;
        }
        
        class Dog extends Mammal<String> {
          String makeSound() => "Woof!";
        }
        
        class Cat extends Mammal<String> {
          String makeSound() => "Meow!";
        }
        
        class Zoo<T extends Animal<String>> {
          List<T> animals = [];
          
          void addAnimal(T animal) {
            animals.add(animal);
          }
          
          List<String> getAllSounds() {
            var sounds = <String>[];
            for (var animal in animals) {
              sounds.add(animal.makeSound());
            }
            return sounds;
          }
        }
        
        main() {
          var zoo = Zoo<Dog>();
          zoo.addAnimal(Dog());
          zoo.addAnimal(Dog());
          
          return zoo.getAllSounds();
        }
      ''';
      expect(interpreter.execute(source: code), equals(["Woof!", "Woof!"]));
    });

    test('Self-referencing generic types', () {
      final code = '''
        abstract class Comparable<T extends Comparable<T>> {
          int compareTo(T other);
          
          bool operator <(T other) => compareTo(other) < 0;
          bool operator >(T other) => compareTo(other) > 0;
          bool operator <=(T other) => compareTo(other) <= 0;
          bool operator >=(T other) => compareTo(other) >= 0;
        }
        
        class MyInt implements Comparable<MyInt> {
          int value;
          MyInt(this.value);
          
          int compareTo(MyInt other) => value - other.value;
        }
        
        T max<T extends Comparable<T>>(T a, T b) {
          return a > b ? a : b;
        }
        
        main() {
          var a = MyInt(5);
          var b = MyInt(10);
          var maxValue = max<MyInt>(a, b);
          return maxValue.value;
        }
      ''';
      expect(interpreter.execute(source: code), equals(10));
    });

    test('Covariance and contravariance simulation', () {
      final code = '''
        abstract class Producer<T> {
          T produce();
        }
        
        abstract class Consumer<T> {
          void consume(T item);
        }
        
        class NumberProducer implements Producer<num> {
          num produce() => 42.5;
        }
        
        class IntConsumer implements Consumer<int> {
          int lastConsumed = 0;
          void consume(int item) {
            lastConsumed = item;
          }
        }
        
        // Simulate covariant usage
        T processProducer<T>(Producer<T> producer) {
          return producer.produce();
        }
        
        main() {
          var producer = NumberProducer();
          var result = processProducer<num>(producer);
          return result;
        }
      ''';
      expect(interpreter.execute(source: code), equals(42.5));
    });
  });

  group('Type Inference and Dynamic Behavior', () {
    test('Type inference from constructor arguments', () {
      final code = '''
        class Box<T> {
          T value;
          Box(this.value);
        }
        
        main() {
          // Should infer Box<String>
          var box1 = Box("hello");
          
          // Should infer Box<int>  
          var box2 = Box(42);
          
          return [box1.value, box2.value];
        }
      ''';
      expect(interpreter.execute(source: code), equals(["hello", 42]));
    });

    test('Generic type parameter bounds checking at runtime', () {
      final code = '''
        class NumberContainer<T extends num> {
          T value;
          NumberContainer(this.value);
          
          T add(T other) {
            if (value is int && other is int) {
              return (value as int) + (other as int) as T;
            } else {
              return (value.toDouble() + other.toDouble()) as T;
            }
          }
        }
        
        main() {
          var intContainer = NumberContainer<int>(5);
          var result1 = intContainer.add(3);
          
          var doubleContainer = NumberContainer<double>(5.5);
          var result2 = doubleContainer.add(2.5);
          
          return [result1, result2];
        }
      ''';
      expect(interpreter.execute(source: code), equals([8, 8.0]));
    });
  });
}
