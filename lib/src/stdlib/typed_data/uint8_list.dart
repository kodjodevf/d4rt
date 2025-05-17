import 'dart:typed_data';

import 'package:d4rt/src/bridge/registration.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/exceptions.dart';

void registerUint8List(Environment environment) {
  final uint8ListDefinition = BridgedClassDefinition(
    name: 'Uint8List',
    nativeType: Uint8List,
    constructors: {
      '': (InterpreterVisitor visitor, List<Object?> positionalArgs,
          Map<String, Object?> namedArgs) {
        if (positionalArgs.length == 1 &&
            positionalArgs[0] is int &&
            namedArgs.isEmpty) {
          return Uint8List(positionalArgs[0] as int);
        }
        throw RuntimeError(
            "Uint8List constructor expects one int argument (length).");
      },
      'fromList': (InterpreterVisitor visitor, List<Object?> positionalArgs,
          Map<String, Object?> namedArgs) {
        if (positionalArgs.length == 1 &&
            positionalArgs[0] is List &&
            namedArgs.isEmpty) {
          final sourceList = positionalArgs[0] as List;
          final intList = sourceList.map((e) {
            if (e is int) return e;
            throw RuntimeError("Uint8List.fromList expects a List<int>.");
          }).toList();
          return Uint8List.fromList(intList);
        }
        throw RuntimeError(
            "Uint8List.fromList expects one List<int> argument.");
      },
    },
    methods: {
      'sublist': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is Uint8List &&
            positionalArgs.isNotEmpty &&
            positionalArgs[0] is int) {
          final start = positionalArgs[0] as int;
          int? end;
          if (positionalArgs.length > 1) {
            if (positionalArgs[1] is int?) {
              end = positionalArgs[1] as int?;
            } else if (positionalArgs[1] != null) {
              throw RuntimeError(
                  "Uint8List.sublist: end must be an int or null.");
            }
          }
          return target.sublist(start, end);
        }
        throw RuntimeError("Invalid arguments for Uint8List.sublist");
      },
      '[]': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is Uint8List &&
            positionalArgs.length == 1 &&
            positionalArgs[0] is int &&
            namedArgs.isEmpty) {
          return target[positionalArgs[0] as int];
        }
        throw RuntimeError(
            "Invalid arguments for Uint8List[index]. Expects an int index.");
      },
      '[]=': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is Uint8List &&
            positionalArgs.length == 2 &&
            positionalArgs[0] is int &&
            positionalArgs[1] is int &&
            namedArgs.isEmpty) {
          final index = positionalArgs[0] as int;
          final value = positionalArgs[1] as int;
          target[index] = value;
          return value;
        }
        throw RuntimeError(
            "Invalid arguments for Uint8List[index] = value. Expects int index, int value.");
      }
    },
    getters: {
      'length': (InterpreterVisitor? visitor, Object target) {
        if (target is Uint8List) return target.length;
        throw RuntimeError("Target is not a Uint8List for getter 'length'");
      },
      'elementSizeInBytes': (InterpreterVisitor? visitor, Object target) {
        if (target is Uint8List) return target.elementSizeInBytes;
        throw RuntimeError(
            "Target is not a Uint8List for getter 'elementSizeInBytes'");
      },
      'buffer': (InterpreterVisitor? visitor, Object target) {
        if (target is Uint8List) {
          return target.buffer;
        }
        throw RuntimeError("Target is not a Uint8List for getter 'buffer'");
      },
    },
    setters: {},
  );

  environment.defineBridge(uint8ListDefinition);
}
