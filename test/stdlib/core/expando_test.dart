import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('Expando stdlib tests', () {
    test('Expando attaches values to objects dynamically', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:core';

        class User {
          String name;
          User(this.name);
        }

        main() {
          final expando = Expando<int>('userScores');
          final user1 = User('Alice');
          final user2 = User('Bob');

          expando[user1] = 100;
          expando[user2] = 200;

          return [expando.name, expando[user1], expando[user2]];
        }
      ''');

      expect(result, equals(['userScores', 100, 200]));
    });
  });
}
