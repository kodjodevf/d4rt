import 'dart:typed_data';

import 'package:d4rt/src/bridge/registration.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/exceptions.dart';

void registerByteBuffer(Environment environment) {
  final byteBufferDefinition = BridgedClassDefinition(
    name: 'ByteBuffer',
    nativeType: ByteBuffer,
    methods: {
      'asUint8List': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is ByteBuffer) {
          int offsetInBytes = 0;
          int? length;
          if (positionalArgs.isNotEmpty) {
            if (positionalArgs[0] is int) {
              offsetInBytes = positionalArgs[0] as int;
            } else {
              throw RuntimeError("asUint8List: offsetInBytes must be an int.");
            }
          }
          if (positionalArgs.length > 1) {
            if (positionalArgs[1] is int?) {
              length = positionalArgs[1] as int?;
            } else if (positionalArgs[1] != null) {
              throw RuntimeError("asUint8List: length must be an int or null.");
            }
          }
          return target.asUint8List(offsetInBytes, length);
        }
        throw RuntimeError("Target is not a ByteBuffer for asUint8List");
      },
    },
    getters: {
      'lengthInBytes': (InterpreterVisitor? visitor, Object target) {
        if (target is ByteBuffer) {
          return target.lengthInBytes;
        }
        throw RuntimeError(
            "Target is not a ByteBuffer for getter 'lengthInBytes'");
      },
    },
  );

  environment.defineBridge(byteBufferDefinition);
}
