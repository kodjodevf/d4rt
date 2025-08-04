import 'dart:typed_data';
import 'package:d4rt/d4rt.dart';

class ByteDataTypedData {
  static BridgedClass get definition => BridgedClass(
        name: 'ByteData',
        nativeType: ByteData,
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length == 1 &&
                positionalArgs[0] is int &&
                namedArgs.isEmpty) {
              return ByteData(positionalArgs[0] as int);
            }
            throw RuntimeError(
                "ByteData constructor expects one int argument (length).");
          },
          'view': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty && positionalArgs[0] is ByteBuffer) {
              final buffer = positionalArgs[0] as ByteBuffer;
              final offsetInBytes = positionalArgs.length > 1
                  ? positionalArgs[1] as int? ?? 0
                  : 0;
              final length =
                  positionalArgs.length > 2 ? positionalArgs[2] as int? : null;
              return ByteData.view(buffer, offsetInBytes, length);
            }
            throw RuntimeError(
                "ByteData.view expects ByteBuffer and optional offset/length arguments.");
          },
          'sublistView': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty && positionalArgs[0] is TypedData) {
              final data = positionalArgs[0] as TypedData;
              final start = positionalArgs.length > 1
                  ? positionalArgs[1] as int? ?? 0
                  : 0;
              final end =
                  positionalArgs.length > 2 ? positionalArgs[2] as int? : null;
              return ByteData.sublistView(data, start, end);
            }
            throw RuntimeError(
                "ByteData.sublistView expects TypedData and optional start/end arguments.");
          },
        },
        methods: {
          // 8-bit integer methods
          'getInt8': (visitor, target, positionalArgs, namedArgs) {
            if (target is ByteData &&
                positionalArgs.length == 1 &&
                positionalArgs[0] is int) {
              return target.getInt8(positionalArgs[0] as int);
            }
            throw RuntimeError(
                "Invalid arguments for ByteData.getInt8. Expects int byteOffset.");
          },
          'setInt8': (visitor, target, positionalArgs, namedArgs) {
            if (target is ByteData &&
                positionalArgs.length == 2 &&
                positionalArgs[0] is int &&
                positionalArgs[1] is int) {
              target.setInt8(
                  positionalArgs[0] as int, positionalArgs[1] as int);
              return null;
            }
            throw RuntimeError(
                "Invalid arguments for ByteData.setInt8. Expects int byteOffset, int value.");
          },
          'getUint8': (visitor, target, positionalArgs, namedArgs) {
            if (target is ByteData &&
                positionalArgs.length == 1 &&
                positionalArgs[0] is int) {
              return target.getUint8(positionalArgs[0] as int);
            }
            throw RuntimeError(
                "Invalid arguments for ByteData.getUint8. Expects int byteOffset.");
          },
          'setUint8': (visitor, target, positionalArgs, namedArgs) {
            if (target is ByteData &&
                positionalArgs.length == 2 &&
                positionalArgs[0] is int &&
                positionalArgs[1] is int) {
              target.setUint8(
                  positionalArgs[0] as int, positionalArgs[1] as int);
              return null;
            }
            throw RuntimeError(
                "Invalid arguments for ByteData.setUint8. Expects int byteOffset, int value.");
          },

          // 16-bit integer methods
          'getInt16': (visitor, target, positionalArgs, namedArgs) {
            if (target is ByteData &&
                positionalArgs.isNotEmpty &&
                positionalArgs[0] is int) {
              final offset = positionalArgs[0] as int;
              final endian = positionalArgs.length > 1
                  ? positionalArgs[1] as Endian? ?? Endian.big
                  : Endian.big;
              return target.getInt16(offset, endian);
            }
            throw RuntimeError(
                "Invalid arguments for ByteData.getInt16. Expects int byteOffset, [Endian endian].");
          },
          'setInt16': (visitor, target, positionalArgs, namedArgs) {
            if (target is ByteData &&
                positionalArgs.length >= 2 &&
                positionalArgs[0] is int &&
                positionalArgs[1] is int) {
              final offset = positionalArgs[0] as int;
              final value = positionalArgs[1] as int;
              final endian = positionalArgs.length > 2
                  ? positionalArgs[2] as Endian? ?? Endian.big
                  : Endian.big;
              target.setInt16(offset, value, endian);
              return null;
            }
            throw RuntimeError(
                "Invalid arguments for ByteData.setInt16. Expects int byteOffset, int value, [Endian endian].");
          },
          'getUint16': (visitor, target, positionalArgs, namedArgs) {
            if (target is ByteData &&
                positionalArgs.isNotEmpty &&
                positionalArgs[0] is int) {
              final offset = positionalArgs[0] as int;
              final endian = positionalArgs.length > 1
                  ? positionalArgs[1] as Endian? ?? Endian.big
                  : Endian.big;
              return target.getUint16(offset, endian);
            }
            throw RuntimeError(
                "Invalid arguments for ByteData.getUint16. Expects int byteOffset, [Endian endian].");
          },
          'setUint16': (visitor, target, positionalArgs, namedArgs) {
            if (target is ByteData &&
                positionalArgs.length >= 2 &&
                positionalArgs[0] is int &&
                positionalArgs[1] is int) {
              final offset = positionalArgs[0] as int;
              final value = positionalArgs[1] as int;
              final endian = positionalArgs.length > 2
                  ? positionalArgs[2] as Endian? ?? Endian.big
                  : Endian.big;
              target.setUint16(offset, value, endian);
              return null;
            }
            throw RuntimeError(
                "Invalid arguments for ByteData.setUint16. Expects int byteOffset, int value, [Endian endian].");
          },

          // 32-bit integer methods
          'getInt32': (visitor, target, positionalArgs, namedArgs) {
            if (target is ByteData &&
                positionalArgs.isNotEmpty &&
                positionalArgs[0] is int) {
              final offset = positionalArgs[0] as int;
              final endian = positionalArgs.length > 1
                  ? positionalArgs[1] as Endian? ?? Endian.big
                  : Endian.big;
              return target.getInt32(offset, endian);
            }
            throw RuntimeError(
                "Invalid arguments for ByteData.getInt32. Expects int byteOffset, [Endian endian].");
          },
          'setInt32': (visitor, target, positionalArgs, namedArgs) {
            if (target is ByteData &&
                positionalArgs.length >= 2 &&
                positionalArgs[0] is int &&
                positionalArgs[1] is int) {
              final offset = positionalArgs[0] as int;
              final value = positionalArgs[1] as int;
              final endian = positionalArgs.length > 2
                  ? positionalArgs[2] as Endian? ?? Endian.big
                  : Endian.big;
              target.setInt32(offset, value, endian);
              return null;
            }
            throw RuntimeError(
                "Invalid arguments for ByteData.setInt32. Expects int byteOffset, int value, [Endian endian].");
          },
          'getUint32': (visitor, target, positionalArgs, namedArgs) {
            if (target is ByteData &&
                positionalArgs.isNotEmpty &&
                positionalArgs[0] is int) {
              final offset = positionalArgs[0] as int;
              final endian = positionalArgs.length > 1
                  ? positionalArgs[1] as Endian? ?? Endian.big
                  : Endian.big;
              return target.getUint32(offset, endian);
            }
            throw RuntimeError(
                "Invalid arguments for ByteData.getUint32. Expects int byteOffset, [Endian endian].");
          },
          'setUint32': (visitor, target, positionalArgs, namedArgs) {
            if (target is ByteData &&
                positionalArgs.length >= 2 &&
                positionalArgs[0] is int &&
                positionalArgs[1] is int) {
              final offset = positionalArgs[0] as int;
              final value = positionalArgs[1] as int;
              final endian = positionalArgs.length > 2
                  ? positionalArgs[2] as Endian? ?? Endian.big
                  : Endian.big;
              target.setUint32(offset, value, endian);
              return null;
            }
            throw RuntimeError(
                "Invalid arguments for ByteData.setUint32. Expects int byteOffset, int value, [Endian endian].");
          },

          // 64-bit integer methods
          'getInt64': (visitor, target, positionalArgs, namedArgs) {
            if (target is ByteData &&
                positionalArgs.isNotEmpty &&
                positionalArgs[0] is int) {
              final offset = positionalArgs[0] as int;
              final endian = positionalArgs.length > 1
                  ? positionalArgs[1] as Endian? ?? Endian.big
                  : Endian.big;
              return target.getInt64(offset, endian);
            }
            throw RuntimeError(
                "Invalid arguments for ByteData.getInt64. Expects int byteOffset, [Endian endian].");
          },
          'setInt64': (visitor, target, positionalArgs, namedArgs) {
            if (target is ByteData &&
                positionalArgs.length >= 2 &&
                positionalArgs[0] is int &&
                positionalArgs[1] is int) {
              final offset = positionalArgs[0] as int;
              final value = positionalArgs[1] as int;
              final endian = positionalArgs.length > 2
                  ? positionalArgs[2] as Endian? ?? Endian.big
                  : Endian.big;
              target.setInt64(offset, value, endian);
              return null;
            }
            throw RuntimeError(
                "Invalid arguments for ByteData.setInt64. Expects int byteOffset, int value, [Endian endian].");
          },
          'getUint64': (visitor, target, positionalArgs, namedArgs) {
            if (target is ByteData &&
                positionalArgs.isNotEmpty &&
                positionalArgs[0] is int) {
              final offset = positionalArgs[0] as int;
              final endian = positionalArgs.length > 1
                  ? positionalArgs[1] as Endian? ?? Endian.big
                  : Endian.big;
              return target.getUint64(offset, endian);
            }
            throw RuntimeError(
                "Invalid arguments for ByteData.getUint64. Expects int byteOffset, [Endian endian].");
          },
          'setUint64': (visitor, target, positionalArgs, namedArgs) {
            if (target is ByteData &&
                positionalArgs.length >= 2 &&
                positionalArgs[0] is int &&
                positionalArgs[1] is int) {
              final offset = positionalArgs[0] as int;
              final value = positionalArgs[1] as int;
              final endian = positionalArgs.length > 2
                  ? positionalArgs[2] as Endian? ?? Endian.big
                  : Endian.big;
              target.setUint64(offset, value, endian);
              return null;
            }
            throw RuntimeError(
                "Invalid arguments for ByteData.setUint64. Expects int byteOffset, int value, [Endian endian].");
          },

          // Float methods
          'getFloat32': (visitor, target, positionalArgs, namedArgs) {
            if (target is ByteData &&
                positionalArgs.isNotEmpty &&
                positionalArgs[0] is int) {
              final offset = positionalArgs[0] as int;
              final endian = positionalArgs.length > 1
                  ? positionalArgs[1] as Endian? ?? Endian.big
                  : Endian.big;
              return target.getFloat32(offset, endian);
            }
            throw RuntimeError(
                "Invalid arguments for ByteData.getFloat32. Expects int byteOffset, [Endian endian].");
          },
          'setFloat32': (visitor, target, positionalArgs, namedArgs) {
            if (target is ByteData &&
                positionalArgs.length >= 2 &&
                positionalArgs[0] is int &&
                positionalArgs[1] is num) {
              final offset = positionalArgs[0] as int;
              final value = (positionalArgs[1] as num).toDouble();
              final endian = positionalArgs.length > 2
                  ? positionalArgs[2] as Endian? ?? Endian.big
                  : Endian.big;
              target.setFloat32(offset, value, endian);
              return null;
            }
            throw RuntimeError(
                "Invalid arguments for ByteData.setFloat32. Expects int byteOffset, num value, [Endian endian].");
          },
          'getFloat64': (visitor, target, positionalArgs, namedArgs) {
            if (target is ByteData &&
                positionalArgs.isNotEmpty &&
                positionalArgs[0] is int) {
              final offset = positionalArgs[0] as int;
              final endian = positionalArgs.length > 1
                  ? positionalArgs[1] as Endian? ?? Endian.big
                  : Endian.big;
              return target.getFloat64(offset, endian);
            }
            throw RuntimeError(
                "Invalid arguments for ByteData.getFloat64. Expects int byteOffset, [Endian endian].");
          },
          'setFloat64': (visitor, target, positionalArgs, namedArgs) {
            if (target is ByteData &&
                positionalArgs.length >= 2 &&
                positionalArgs[0] is int &&
                positionalArgs[1] is num) {
              final offset = positionalArgs[0] as int;
              final value = (positionalArgs[1] as num).toDouble();
              final endian = positionalArgs.length > 2
                  ? positionalArgs[2] as Endian? ?? Endian.big
                  : Endian.big;
              target.setFloat64(offset, value, endian);
              return null;
            }
            throw RuntimeError(
                "Invalid arguments for ByteData.setFloat64. Expects int byteOffset, num value, [Endian endian].");
          },

          // Standard object methods
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as ByteData).toString();
          },
          '==': (visitor, target, positionalArgs, namedArgs) {
            return (target as ByteData) == positionalArgs[0];
          },
        },
        getters: {
          'lengthInBytes': (visitor, target) {
            if (target is ByteData) return target.lengthInBytes;
            throw RuntimeError(
                "Target is not a ByteData for getter 'lengthInBytes'");
          },
          'elementSizeInBytes': (visitor, target) {
            if (target is ByteData) return target.elementSizeInBytes;
            throw RuntimeError(
                "Target is not a ByteData for getter 'elementSizeInBytes'");
          },
          'offsetInBytes': (visitor, target) {
            if (target is ByteData) return target.offsetInBytes;
            throw RuntimeError(
                "Target is not a ByteData for getter 'offsetInBytes'");
          },
          'buffer': (visitor, target) {
            if (target is ByteData) return target.buffer;
            throw RuntimeError("Target is not a ByteData for getter 'buffer'");
          },
          'hashCode': (visitor, target) {
            if (target is ByteData) return target.hashCode;
            throw RuntimeError(
                "Target is not a ByteData for getter 'hashCode'");
          },
          'runtimeType': (visitor, target) {
            if (target is ByteData) return target.runtimeType;
            throw RuntimeError(
                "Target is not a ByteData for getter 'runtimeType'");
          },
        },
      );
}
