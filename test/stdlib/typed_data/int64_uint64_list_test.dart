import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('Int64List and Uint64List stdlib tests', () {
    test('Int64List operations', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:typed_data';

        main() {
          final list = Int64List(3);
          list[0] = 100;
          list[1] = -200;
          list[2] = 300;
          return [list.length, list[0], list[1], list[2], list.elementSizeInBytes];
        }
      ''');

      expect(result, equals([3, 100, -200, 300, 8]));
    });

    test('Uint64List operations and fromList', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:typed_data';

        main() {
          final list = Uint64List.fromList([10, 20, 30]);
          return [list.length, list[0], list[1], list[2], list.elementSizeInBytes];
        }
      ''');

      expect(result, equals([3, 10, 20, 30, 8]));
    });
  });
}
