import 'package:d4rt/src/environment.dart';
import 'typed_data/endian.dart';
import 'typed_data/byte_buffer.dart';
import 'typed_data/uint8_list.dart';
import 'typed_data/byte_data.dart';
import 'typed_data/int16_list.dart';
import 'typed_data/float32_list.dart';

class TypedDataStdlib {
  static void register(Environment environment) {
    environment.defineBridge(EndianTypedData.definition);
    environment.defineBridge(ByteBufferTypedData.definition);
    environment.defineBridge(Uint8ListTypedData.definition);
    environment.defineBridge(ByteDataTypedData.definition);
    environment.defineBridge(Int16ListTypedData.definition);
    environment.defineBridge(Float32ListTypedData.definition);
  }
}
