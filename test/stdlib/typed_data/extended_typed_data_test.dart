import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('Extended TypedData stdlib tests', () {
    test('Int8List basic operations', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:typed_data';

        main() {
          final list = Int8List(3);
          list[0] = 127;
          list[1] = -128;
          list[2] = 42;
          return list.toList();
        }
      ''');

      expect(result, equals([127, -128, 42]));
    });

    test('Uint8ClampedList clamping behavior', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:typed_data';

        main() {
          final list = Uint8ClampedList(3);
          list[0] = 300; // Clamped to 255
          list[1] = -50; // Clamped to 0
          list[2] = 100;
          return list.toList();
        }
      ''');

      expect(result, equals([255, 0, 100]));
    });

    test('Uint16List and Int32List', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:typed_data';

        main() {
          final u16 = Uint16List.fromList([65535, 1000]);
          final i32 = Int32List.fromList([2147483647, -2147483648]);
          return [u16.toList(), i32.toList()];
        }
      ''');

      expect(result, equals([
        [65535, 1000],
        [2147483647, -2147483648],
      ]));
    });

    test('Uint32List and Float64List', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:typed_data';

        main() {
          final u32 = Uint32List(2);
          u32[0] = 4294967295;
          u32[1] = 100;

          final f64 = Float64List.fromList([3.141592653589793, 2.718281828459045]);
          return [u32.toList(), f64.toList()];
        }
      ''');

      expect(result, equals([
        [4294967295, 100],
        [3.141592653589793, 2.718281828459045],
      ]));
    });
  });
}
