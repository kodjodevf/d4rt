import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('base64 dynamic collections stdlib tests', () {
    test('base64Encode and base64UrlEncode with dynamic list', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:convert';

        main() {
          final dynList = <dynamic>[72, 101, 108, 108, 111];
          final encoded = base64Encode(dynList);
          final urlEncoded = base64UrlEncode(dynList);
          final decoded = base64Decode(encoded);
          return [encoded, urlEncoded, decoded.toList()];
        }
      ''');

      expect(result, equals(['SGVsbG8=', 'SGVsbG8=', [72, 101, 108, 108, 111]]));
    });
  });
}
