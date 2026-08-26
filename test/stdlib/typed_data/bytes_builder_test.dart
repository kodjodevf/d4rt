import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('BytesBuilder stdlib tests', () {
    test('BytesBuilder add, addByte, toBytes, takeBytes', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:typed_data';

        main() {
          final builder = BytesBuilder();
          builder.add([1, 2, 3]);
          builder.addByte(4);
          final len = builder.length;
          final bytes = builder.toBytes();
          final taken = builder.takeBytes();
          final empty = builder.isEmpty;
          return [len, bytes.toList(), taken.toList(), empty];
        }
      ''');

      expect(result, equals([4, [1, 2, 3, 4], [1, 2, 3, 4], true]));
    });
  });
}
