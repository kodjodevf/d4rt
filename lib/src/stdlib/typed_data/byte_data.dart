import 'dart:typed_data';
import 'package:d4rt/src/bridge/registration.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/exceptions.dart';

void registerByteData(Environment environment) {
  final byteDataDefinition = BridgedClassDefinition(
    name: 'ByteData',
    nativeType: ByteData,
    constructors: {
      '': (InterpreterVisitor visitor, List<Object?> positionalArgs,
          Map<String, Object?> namedArgs) {
        if (positionalArgs.length == 1 &&
            positionalArgs[0] is int &&
            namedArgs.isEmpty) {
          return ByteData(positionalArgs[0] as int);
        }
        throw RuntimeError(
            "ByteData constructor expects one int argument (length).");
      },
    },
    methods: {
      'getInt8': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is ByteData &&
            positionalArgs.length == 1 &&
            positionalArgs[0] is int &&
            namedArgs.isEmpty) {
          return target.getInt8(positionalArgs[0] as int);
        }
        throw RuntimeError(
            "Invalid arguments for ByteData.getInt8. Expects int byteOffset.");
      },
      'setInt8': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is ByteData &&
            positionalArgs.length == 2 &&
            positionalArgs[0] is int &&
            positionalArgs[1] is int &&
            namedArgs.isEmpty) {
          target.setInt8(positionalArgs[0] as int, positionalArgs[1] as int);
          return null; // Typically void
        }
        throw RuntimeError(
            "Invalid arguments for ByteData.setInt8. Expects int byteOffset, int value.");
      },
      'getUint16': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is ByteData &&
            positionalArgs.isNotEmpty &&
            positionalArgs[0] is int &&
            (positionalArgs.length == 1 || positionalArgs.length == 2) &&
            namedArgs.isEmpty) {
          final offset = positionalArgs[0] as int;
          Endian endian = Endian.big; // Default
          if (positionalArgs.length == 2) {
            // If endian is provided
            if (positionalArgs[1] is Endian) {
              endian = positionalArgs[1] as Endian;
            } else if (positionalArgs[1] != null) {
              // null is acceptable for default, but not other types
              throw RuntimeError(
                  "ByteData.getUint16: endian must be an Endian value.");
            }
          }
          return target.getUint16(offset, endian);
        }
        throw RuntimeError(
            "Invalid arguments for ByteData.getUint16. Expects int byteOffset, [Endian endian].");
      },
      'setUint16': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is ByteData &&
            (positionalArgs.length == 2 || positionalArgs.length == 3) &&
            positionalArgs[0] is int &&
            positionalArgs[1] is int &&
            namedArgs.isEmpty) {
          final offset = positionalArgs[0] as int;
          final value = positionalArgs[1] as int;
          Endian endian = Endian.big;
          if (positionalArgs.length == 3) {
            if (positionalArgs[2] is Endian) {
              endian = positionalArgs[2] as Endian;
            } else if (positionalArgs[2] != null) {
              throw RuntimeError(
                  "ByteData.setUint16: endian must be an Endian value.");
            }
          }
          target.setUint16(offset, value, endian);
          return null;
        }
        throw RuntimeError(
            "Invalid arguments for ByteData.setUint16. Expects int byteOffset, int value, [Endian endian].");
      },
    },
    getters: {
      'lengthInBytes': (InterpreterVisitor? visitor, Object target) {
        if (target is ByteData) return target.lengthInBytes;
        throw RuntimeError(
            "Target is not a ByteData for getter 'lengthInBytes'");
      },
      'elementSizeInBytes': (InterpreterVisitor? visitor, Object target) {
        if (target is ByteData) return target.elementSizeInBytes;
        throw RuntimeError(
            "Target is not a ByteData for getter 'elementSizeInBytes'");
      },
      'buffer': (InterpreterVisitor? visitor, Object target) {
        if (target is ByteData) {
          return target.buffer;
        }
        throw RuntimeError("Target is not a ByteData for getter 'buffer'");
      },
    },
  );

  environment.defineBridge(byteDataDefinition);
}
