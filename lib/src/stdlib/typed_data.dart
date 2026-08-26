import 'package:d4rt/src/environment.dart';
import 'typed_data/endian.dart';
import 'typed_data/byte_buffer.dart';
import 'typed_data/uint8_list.dart';
import 'typed_data/byte_data.dart';
import 'typed_data/int16_list.dart';
import 'typed_data/float32_list.dart';
import 'typed_data/int8_list.dart';
import 'typed_data/uint8_clamped_list.dart';
import 'typed_data/uint16_list.dart';
import 'typed_data/int32_list.dart';
import 'typed_data/uint32_list.dart';
import 'typed_data/float64_list.dart';

export 'typed_data/endian.dart';
export 'typed_data/byte_buffer.dart';
export 'typed_data/uint8_list.dart';
export 'typed_data/byte_data.dart';
export 'typed_data/int16_list.dart';
export 'typed_data/float32_list.dart';
export 'typed_data/int8_list.dart';
export 'typed_data/uint8_clamped_list.dart';
export 'typed_data/uint16_list.dart';
export 'typed_data/int32_list.dart';
export 'typed_data/uint32_list.dart';
export 'typed_data/float64_list.dart';

class TypedDataStdlib {
  static void register(Environment environment) {
    environment.defineBridge(EndianTypedData.definition);
    environment.defineBridge(ByteBufferTypedData.definition);
    environment.defineBridge(Uint8ListTypedData.definition);
    environment.defineBridge(ByteDataTypedData.definition);
    environment.defineBridge(Int16ListTypedData.definition);
    environment.defineBridge(Float32ListTypedData.definition);
    environment.defineBridge(Int8ListTypedData.definition);
    environment.defineBridge(Uint8ClampedListTypedData.definition);
    environment.defineBridge(Uint16ListTypedData.definition);
    environment.defineBridge(Int32ListTypedData.definition);
    environment.defineBridge(Uint32ListTypedData.definition);
    environment.defineBridge(Float64ListTypedData.definition);
  }
}
