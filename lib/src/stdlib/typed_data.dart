import 'package:d4rt/src/environment.dart';

import 'typed_data/endian.dart';
import 'typed_data/byte_buffer.dart';
import 'typed_data/uint8_list.dart';
import 'typed_data/byte_data.dart';

void registerTypedData(Environment environment) {
  registerEndian(environment);
  registerByteBuffer(environment);
  registerUint8List(environment);
  registerByteData(environment);
}
