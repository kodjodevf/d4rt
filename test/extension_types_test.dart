import 'package:test/test.dart';
import 'interpreter_test.dart';

void main() {
  group('Extension Types:', () {
    test('Basic extension type creation and value access', () {
      const code = '''
extension type UserId(int value) {
}

int main() {
  var id = UserId(42);
  return id.value;
}
      ''';
      expect(execute(code), equals(42));
    });

    test('Extension type with getter accessing representation field', () {
      const code = '''
extension type UserId(int value) {
  bool get isValid => value > 0;
}

bool main() {
  var id = UserId(42);
  return id.isValid;
}
      ''';
      expect(execute(code), equals(true));
    });

    test('Extension type getter returns false for invalid value', () {
      const code = '''
extension type UserId(int value) {
  bool get isValid => value > 0;
}

bool main() {
  var id = UserId(-5);
  return id.isValid;
}
      ''';
      expect(execute(code), equals(false));
    });

    test('Extension type with method', () {
      const code = '''
extension type UserId(int value) {
  String describe() => 'User #\$value';
}

String main() {
  var id = UserId(42);
  return id.describe();
}
      ''';
      expect(execute(code), equals('User #42'));
    });

    test('Extension type with multiple methods', () {
      const code = '''
extension type Price(double amount) {
  double get withTax => amount * 1.1;
  double get formatted => (amount * 100).toInt() / 100;
  String description() => '\\\$\$amount';
}

List main() {
  var price = Price(10.5);
  return [price.amount, price.withTax, price.formatted, price.description()];
}
      ''';
      final result = execute(code) as List;
      expect(result[0], equals(10.5));
      expect(result[1], closeTo(11.55, 0.01));
      expect(result[2], equals(10.5));
      expect(result[3], equals('\$10.5'));
    });

    test('Extension type with string representation', () {
      const code = '''
extension type Email(String address) {
  bool get isValid => address.contains('@');
  String get domain => address.split('@')[1];
}

List main() {
  var email = Email('user@example.com');
  return [email.isValid, email.domain];
}
      ''';
      final result = execute(code) as List;
      expect(result[0], equals(true));
      expect(result[1], equals('example.com'));
    });

    test('Extension type with list representation', () {
      const code = '''
extension type IntList(List<int> items) {
  int get sum {
    int total = 0;
    for (final item in items) {
      total = total + item;
    }
    return total;
  }
  int get count => items.length;
}

List main() {
  var list = IntList([1, 2, 3, 4, 5]);
  return [list.sum, list.count];
}
      ''';
      final result = execute(code) as List;
      expect(result[0], equals(15));
      expect(result[1], equals(5));
    });

    test('Extension type can access underlying type through value field', () {
      const code = '''
extension type UserId(int value) {
  bool get isAdmin => value == 1;
}

List main() {
  var id = UserId(1);
  return [id.value, id.isAdmin];
}
      ''';
      final result = execute(code) as List;
      expect(result[0], equals(1));
      expect(result[1], equals(true));
    });
  });
}
