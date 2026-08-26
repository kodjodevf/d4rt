import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('DateTime.copyWith tests', () {
    test('copyWith modifies specific fields', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:core';

        main() {
          final dt = DateTime(2023, 5, 10, 14, 30);
          final updated = dt.copyWith(year: 2024, day: 25);
          return [updated.year, updated.month, updated.day, updated.hour, updated.minute];
        }
      ''');

      expect(result, equals([2024, 5, 25, 14, 30]));
    });

    test('Uri constructor and replace with dynamic collections', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:core';

        main() {
          final uri = Uri(
            scheme: 'https',
            host: 'example.com',
            pathSegments: ['api', 'v1', 'users'],
            queryParameters: {'page': '1', 'limit': '10'},
          );

          final replaced = uri.replace(
            pathSegments: ['api', 'v2', 'items'],
            queryParameters: {'filter': 'active'},
          );

          return [uri.toString(), replaced.toString()];
        }
      ''');

      expect(result, equals([
        'https://example.com/api/v1/users?page=1&limit=10',
        'https://example.com/api/v2/items?filter=active',
      ]));
    });
  });
}
