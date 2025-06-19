import 'package:test/test.dart';
import 'interpreter_test.dart';

void main() {
  group('Basic Generic Support', () {
    test('Simple class without generics should still work', () {
      final code = '''
        class Box {
          var value;
          Box(this.value);
          getValue() => value;
        }
        
        main() {
          var box = Box(42);
          return box.getValue();
        }
      ''';
      expect(execute(code), equals(42));
    });

    test('Class with generic syntax should parse but work as dynamic', () {
      final code = '''
        class Box<T> {
          var value;
          Box(this.value);
          getValue() => value;
        }
        
        main() {
          var box = Box("hello");
          return box.getValue();
        }
      ''';
      expect(execute(code), equals("hello"));
    });

    test('Function with type parameter should parse and work', () {
      final code = '''
        T identity<T>(T value) {
          return value;
        }
        
        main() {
          var result1 = identity(42);
          var result2 = identity("hello");
          return [result1, result2];
        }
      ''';
      expect(execute(code), equals([42, "hello"]));
    });

    test('Multiple type parameters should parse', () {
      final code = '''
        class Pair<T, U> {
          var first;
          var second;
          Pair(this.first, this.second);
          getFirst() => first;
          getSecond() => second;
        }
        
        main() {
          var pair = Pair(42, "hello");
          return [pair.getFirst(), pair.getSecond()];
        }
      ''';
      expect(execute(code), equals([42, "hello"]));
    });

    test('Type parameters with bounds should parse (but bounds ignored)', () {
      final code = '''
        class Container<T extends Object> {
          var item;
          Container(this.item);
          getItem() => item;
        }
        
        main() {
          var container = Container("test");
          return container.getItem();
        }
      ''';
      expect(execute(code), equals("test"));
    });

    test('Generic method should parse', () {
      final code = '''
        class Utils {
          static T convert<T>(dynamic value) {
            return value;
          }
        }
        
        main() {
          var result = Utils.convert("converted");
          return result;
        }
      ''';
      expect(execute(code), equals("converted"));
    });

    test('Instantiation with explicit type arguments should parse', () {
      final code = '''
        class Box<T> {
          var value;
          Box(this.value);
          getValue() => value;
        }
        
        main() {
          var box = Box<int>(42);
          return box.getValue();
        }
      ''';
      expect(execute(code), equals(42));
    });

    test('Nested generics should parse', () {
      final code = '''
        class Wrapper<T> {
          var content;
          Wrapper(this.content);
          getContent() => content;
        }
        
        main() {
          var nested = Wrapper(Wrapper("hello"));
          return nested.getContent().getContent();
        }
      ''';
      expect(execute(code), equals("hello"));
    });
  });

  group('Advanced Generic Support', () {
    test('Generic class with type-specific methods', () {
      final code = '''
        class Repository<T> {
          List<T> items = [];
          
          void add(T item) {
            items.add(item);
          }
          
          T? getAt(int index) {
            if (index < items.length) {
              return items[index];
            }
            return null;
          }
          
          int get length => items.length;
        }
        
        main() {
          var stringRepo = Repository<String>();
          stringRepo.add("hello");
          stringRepo.add("world");
          
          var intRepo = Repository<int>();
          intRepo.add(42);
          intRepo.add(100);
          
          return [
            stringRepo.getAt(0),
            stringRepo.getAt(1),
            stringRepo.length,
            intRepo.getAt(0),
            intRepo.getAt(1),
            intRepo.length
          ];
        }
      ''';
      expect(execute(code), equals(["hello", "world", 2, 42, 100, 2]));
    });

    test('Generic function with constraints', () {
      final code = '''
        T max<T extends Comparable>(T a, T b) {
          return a.compareTo(b) > 0 ? a : b;
        }
        
        main() {
          var maxInt = max(10, 20);
          var maxString = max("apple", "banana");
          return [maxInt, maxString];
        }
      ''';
      // Note: This test might fail until we implement proper bounds checking
      expect(execute(code), equals([20, "banana"]));
    });

    test('Generic inheritance', () {
      final code = '''
        class Container<T> {
          T? value;
          Container(this.value);
          T? getValue() => value;
        }
        
        class NumberContainer<T extends num> extends Container<T> {
          NumberContainer(T value) : super(value);
          
          double asDouble() {
            return value?.toDouble() ?? 0.0;
          }
        }
        
        main() {
          var intContainer = NumberContainer<int>(42);
          var doubleContainer = NumberContainer<double>(3.14);
          
          return [
            intContainer.getValue(),
            intContainer.asDouble(),
            doubleContainer.getValue(),
            doubleContainer.asDouble()
          ];
        }
      ''';
      expect(execute(code), equals([42, 42.0, 3.14, 3.14]));
    });

    test('Multiple generic constraints', () {
      final code = '''
        class Serializable<T extends Object> {
          T data;
          Serializable(this.data);
          
          String serialize() {
            return data.toString();
          }
        }
        
        class ValidatedContainer<T extends Object> extends Serializable<T> {
          ValidatedContainer(T data) : super(data);
          
          bool isValid() {
            return data != null;
          }
        }
        
        main() {
          var container = ValidatedContainer<String>("test data");
          return [
            container.serialize(),
            container.isValid(),
            container.data
          ];
        }
      ''';
      expect(execute(code), equals(["test data", true, "test data"]));
    });

    test('Generic factory constructors', () {
      final code = '''
        class Optional<T> {
          T? _value;
          
          Optional._(this._value);
          
          factory Optional.of(T value) {
            return Optional._(value);
          }
          
          factory Optional.empty() {
            return Optional._(null);
          }
          
          bool get hasValue => _value != null;
          T? get value => _value;
        }
        
        main() {
          var opt1 = Optional<String>.of("hello");
          var opt2 = Optional<int>.empty();
          
          return [
            opt1.hasValue,
            opt1.value,
            opt2.hasValue,
            opt2.value
          ];
        }
      ''';
      expect(execute(code), equals([true, "hello", false, null]));
    });

    test('Complex generic collection operations', () {
      final code = '''
        class GenericList<T> {
          List<T> _items = [];
          
          void add(T item) => _items.add(item);
          
          GenericList<U> map<U>(U Function(T) transform) {
            var result = GenericList<U>();
            for (var item in _items) {
              result.add(transform(item));
            }
            return result;
          }
          
          List<T> toList() => List.from(_items);
        }
        
        main() {
          var numbers = GenericList<int>();
          numbers.add(1);
          numbers.add(2);
          numbers.add(3);
          
          // Transform numbers to strings
          var strings = numbers.map<String>((x) => "num_\$x");
          
          return [
            numbers.toList(),
            strings.toList()
          ];
        }
      ''';
      expect(
          execute(code),
          equals([
            [1, 2, 3],
            ["num_1", "num_2", "num_3"]
          ]));
    });

    test('Generic mixin support', () {
      final code = '''
        mixin Comparable<T> {
          int compare(T other);
          
          bool operator >(T other) => compare(other) > 0;
          bool operator <(T other) => compare(other) < 0;
          bool operator >=(T other) => compare(other) >= 0;
          bool operator <=(T other) => compare(other) <= 0;
        }
        
        class Version with Comparable<Version> {
          final int major;
          final int minor;
          
          Version(this.major, this.minor);
          
          @override
          int compare(Version other) {
            if (major != other.major) {
              return major - other.major;
            }
            return minor - other.minor;
          }
        }
        
        main() {
          var v1 = Version(1, 0);
          var v2 = Version(2, 1);
          var v3 = Version(1, 5);
          
          return [
            v1 < v2,   // true
            v2 > v1,   // true
            v1 < v3,   // true
            v3 > v1    // true
          ];
        }
      ''';
      expect(execute(code), equals([true, true, true, true]));
    });
  });

  group('Generic Error Handling', () {
    test('Type mismatch should be caught (when bounds checking implemented)',
        () {
      final code = '''
        class NumberOnly<T extends num> {
          T value;
          NumberOnly(this.value);
        }
        
        main() {
          // This should work
          var intContainer = NumberOnly<int>(42);
          
          // This should eventually fail when bounds checking is implemented
          // var stringContainer = NumberOnly<String>("invalid");
          
          return intContainer.value;
        }
      ''';
      expect(execute(code), equals(42));
    });

    test('Null safety with generics', () {
      final code = '''
        class SafeContainer<T> {
          T? _value;
          
          SafeContainer([this._value]);
          
          void setValue(T value) {
            _value = value;
          }
          
          T? getValue() => _value;
          
          bool get hasValue => _value != null;
        }
        
        main() {
          var container = SafeContainer<String>();
          var initialHasValue = container.hasValue;
          
          container.setValue("test");
          var afterSetHasValue = container.hasValue;
          var value = container.getValue();
          
          return [initialHasValue, afterSetHasValue, value];
        }
      ''';
      expect(execute(code), equals([false, true, "test"]));
    });
  });
}
