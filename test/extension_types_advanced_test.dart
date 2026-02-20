import 'package:test/test.dart';
import 'interpreter_test.dart';

void main() {
  group('Extension Type Getters and Setters', () {
    test('Access extension type getter', () {
      const code = '''
extension type Value(int number) {
  int get doubled => number * 2;
}

int main() {
  var v = Value(5);
  return v.doubled;
}
      ''';
      expect(execute(code), equals(10));
    });

    test('Extension type with multiple getters', () {
      const code = '''
extension type Measurement(double value) {
  double get inMeters => value;
  double get inCentimeters => value * 100;
  double get inMillimeters => value * 1000;
}

List main() {
  var m = Measurement(5.0);
  return [m.inMeters, m.inCentimeters, m.inMillimeters];
}
      ''';
      final result = execute(code) as List;
      expect(result[0], equals(5.0));
      expect(result[1], equals(500.0));
      expect(result[2], equals(5000.0));
    });

    test('Extension type getter using representation field', () {
      const code = '''
extension type UserId(int id) {
  int get nextId => id + 1;
  bool get isValid => id > 0;
}

List main() {
  var userId = UserId(42);
  return [userId.nextId, userId.isValid];
}
      ''';
      expect(execute(code), equals([43, true]));
    });
  });

  group('Extension Type Binary Operators', () {
    test('operator + on extension type', () {
      const code = '''
extension type Amount(int cents) {
  Amount operator +(Amount other) => Amount(cents + other.cents);
}

int main() {
  var a1 = Amount(100);
  var a2 = Amount(200);
  var result = a1 + a2;
  return result.cents;
}
      ''';
      expect(execute(code), equals(300));
    });

    test('operator * on extension type', () {
      const code = '''
extension type Distance(double meters) {
  Distance operator *(double factor) => Distance(meters * factor);
}

double main() {
  var d = Distance(10.0);
  var scaled = d * 2.5;
  return scaled.meters;
}
      ''';
      expect(execute(code), equals(25.0));
    });

    test('operator > on extension type', () {
      const code = '''
extension type Priority(int level) {
  bool operator >(Priority other) => level > other.level;
}

bool main() {
  var high = Priority(10);
  var low = Priority(5);
  return high > low;
}
      ''';
      expect(execute(code), isTrue);
    });
  });

  group('Extension Type Compound Assignment', () {
    test('+= with extension type operator +', () {
      const code = '''
extension type Counter(int count) {
  Counter operator +(int amount) => Counter(count + amount);
}

int main() {
  var c = Counter(10);
  c += 5;
  return c.count;
}
      ''';
      expect(execute(code), equals(15));
    });

    test('*= with extension type operator *', () {
      const code = '''
extension type Value(int val) {
  Value operator *(int factor) => Value(val * factor);
}

int main() {
  var v = Value(10);
  v *= 4;
  return v.val;
}
      ''';
      expect(execute(code), equals(40));
    });
  });

  group('Extension Type Unary Operators', () {
    test('operator unary - on extension type', () {
      const code = '''
extension type Temperature(double celsius) {
  Temperature operator -() => Temperature(-celsius);
}

double main() {
  var temp = Temperature(25.0);
  var inverted = -temp;
  return inverted.celsius;
}
      ''';
      expect(execute(code), equals(-25.0));
    });

    test('operator ~ on extension type', () {
      const code = '''
extension type Flags(int value) {
  Flags operator ~() => Flags(~value);
}

int main() {
  var f = Flags(0);
  var inverted = ~f;
  return inverted.value;
}
      ''';
      expect(execute(code), equals(-1));
    });
  });

  group('Extension Type Call Operator', () {
    test('call() on extension type', () {
      const code = '''
extension type Calculator(int base) {
  int call(int x) => base + x;
}

int main() {
  var calc = Calculator(10);
  return calc(5);
}
      ''';
      expect(execute(code), equals(15));
    });

    test('call() with multiple args on extension type', () {
      const code = '''
extension type Multiplier(int factor) {
  int call(int a, int b) => (a * b) * factor;
}

int main() {
  var mult = Multiplier(2);
  return mult(3, 4);
}
      ''';
      expect(execute(code), equals(24));
    });

    test('call() with named args on extension type', () {
      const code = '''
extension type Formula(int base) {
  int call({required int add, required int multiply}) {
    return (base + add) * multiply;
  }
}

int main() {
  var f = Formula(10);
  return f(add: 5, multiply: 2);
}
      ''';
      expect(execute(code), equals(30));
    });
  });

  group('Extension Type Methods Accessing Representation', () {
    test('Method accessing representation field directly', () {
      const code = '''
extension type Email(String address) {
  String domain() {
    var parts = address.split('@');
    return parts.length > 1 ? parts[1] : '';
  }
  bool isValid() => address.contains('@');
}

List main() {
  var email = Email('user@example.com');
  return [email.domain(), email.isValid()];
}
      ''';
      expect(execute(code), equals(['example.com', true]));
    });

    test('Method modifying representation field values', () {
      const code = '''
extension type UserId(int id) {
  String describe() => 'User #\${id}';
  bool isSpecial() => id == 1 || id == 42;
}

List main() {
  var u1 = UserId(1);
  var u2 = UserId(42);
  var u3 = UserId(10);
  return [u1.describe(), u1.isSpecial(), u2.isSpecial(), u3.isSpecial()];
}
      ''';
      expect(execute(code), equals(['User #1', true, true, false]));
    });

    test('Method with loops using representation field', () {
      const code = '''
extension type IntList(List<int> items) {
  int sum() {
    int total = 0;
    for (final item in items) {
      total = total + item;
    }
    return total;
  }
  int count() => items.length;
}

List main() {
  var list = IntList([1, 2, 3, 4, 5]);
  return [list.sum(), list.count()];
}
      ''';
      expect(execute(code), equals([15, 5]));
    });
  });

  group('Extension Type Index Operators', () {
    test('operator [] on extension type', () {
      const code = '''
extension type IntArray(List<int> items) {
  int operator [](int index) => items[index] * 2;
}

int main() {
  var arr = IntArray([10, 20, 30]);
  return arr[1];
}
      ''';
      expect(execute(code), equals(40));
    });

    test('operator []= on extension type', () {
      const code = '''
extension type MutableArray(List<int> items) {
  int operator [](int index) => items[index];
  void operator []=(int index, int value) {
    items[index] = value + 10;
  }
}

int main() {
  var arr = MutableArray([1, 2, 3]);
  arr[0] = 5;
  return arr[0];
}
      ''';
      expect(execute(code), equals(15));
    });
  });

  group('Extension Type Advanced Features', () {
    test('Extension type with conditional logic', () {
      const code = '''
extension type Score(int points) {
  String grade() {
    if (points >= 90) return 'A';
    if (points >= 80) return 'B';
    if (points >= 70) return 'C';
    return 'F';
  }
}

List main() {
  var s1 = Score(95);
  var s2 = Score(85);
  var s3 = Score(75);
  var s4 = Score(65);
  return [s1.grade(), s2.grade(), s3.grade(), s4.grade()];
}
      ''';
      expect(execute(code), equals(['A', 'B', 'C', 'F']));
    });

    test('Extension type with string representation', () {
      const code = '''
extension type Person(String name) {
  String greet() => 'Hello, \${name}!';
  String shout() => name.toUpperCase() + '!!!';
  int nameLength() => name.length;
}

List main() {
  var p = Person('Alice');
  return [p.greet(), p.shout(), p.nameLength()];
}
      ''';
      expect(execute(code), equals(['Hello, Alice!', 'ALICE!!!', 5]));
    });

    test('Extension type chaining operations', () {
      const code = '''
extension type Value(int val) {
  Value double() => Value(val * 2);
  Value addTen() => Value(val + 10);
  Value triple() => Value(val * 3);
}

int main() {
  var result = Value(5).double().addTen().triple().val;
  return result;
}
      ''';
      expect(
          execute(code), equals(60)); // 5 * 2 = 10, 10 + 10 = 20, 20 * 3 = 60
    });

    test('Extension type with type validation', () {
      const code = '''
extension type UserId(int id) {
  bool isValid() => id > 0 && id < 1000000;
  String validate() {
    if (!isValid()) return 'Invalid ID';
    return 'Valid ID: \${id}';
  }
}

List main() {
  var valid = UserId(100);
  var invalid = UserId(-1);
  return [valid.validate(), invalid.validate()];
}
      ''';
      expect(execute(code), equals(['Valid ID: 100', 'Invalid ID']));
    });
  });
}
