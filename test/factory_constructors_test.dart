import 'package:test/test.dart';
import 'interpreter_test.dart';

void main() {
  test('Factory constructors should work correctly', () {
    final source = '''
      class User {
        final String name;
        final String email;
        
        User(this.name, this.email);
        
        factory User.fromMap(Map<String, dynamic> map) {
          return User(
            map['name'] ?? '',
            map['email'] ?? '',
          );
        }
      }

      main() {
        final map = {'name': 'John Doe', 'email': 'john@example.com'};
        final user = User.fromMap(map);
        return user.name; // Should return "John Doe", not null
      }
    ''';

    final result = execute(source);
    expect(result, equals('John Doe'));
  });

  test('Factory constructor with multiple parameters', () {
    final source = '''
      class Person {
        final String firstName;
        final String lastName;
        final int age;
        
        Person(this.firstName, this.lastName, this.age);
        
        factory Person.create(String first, String last, int years) {
          return Person(first, last, years);
        }
      }

      main() {
        final person = Person.create('Jane', 'Smith', 25);
        return '\${person.firstName} \${person.lastName} is \${person.age} years old';
      }
    ''';

    final result = execute(source);
    expect(result, equals('Jane Smith is 25 years old'));
  });

  test('Factory constructor with validation', () {
    final source = '''
      class Email {
        final String value;
        
        Email._(this.value);
        
        factory Email.create(String input) {
          if (input.contains('@')) {
            return Email._(input);
          } else {
            return Email._('invalid@example.com');
          }
        }
      }

      main() {
        final email1 = Email.create('test@domain.com');
        final email2 = Email.create('invalid-email');
        return [email1.value, email2.value];
      }
    ''';

    final result = execute(source);
    expect(result, isA<List>());
    final list = result as List;
    expect(list[0], equals('test@domain.com'));
    expect(list[1], equals('invalid@example.com'));
  });
}
