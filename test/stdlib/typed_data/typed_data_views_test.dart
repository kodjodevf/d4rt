import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('TypedData stdlib tests', () {
    test('TypedData supertype check and property access', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:typed_data';

        main() {
          final u8 = Uint8List(8);
          final bd = ByteData(16);
          final i32 = Int32List(4);
          final f64 = Float64List(2);
          return [
            u8 is TypedData,
            bd is TypedData,
            i32 is TypedData,
            f64 is TypedData,
            u8.lengthInBytes,
            bd.lengthInBytes,
            i32.lengthInBytes,
            f64.lengthInBytes,
          ];
        }
      ''') as List;

      expect(result[0], isTrue);
      expect(result[1], isTrue);
      expect(result[2], isTrue);
      expect(result[3], isTrue);
      expect(result[4], equals(8));
      expect(result[5], equals(16));
      expect(result[6], equals(16));
      expect(result[7], equals(16));
    });
  });
}
