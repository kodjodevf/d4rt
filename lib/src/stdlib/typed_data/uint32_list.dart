import 'dart:typed_data';
import 'package:d4rt/d4rt.dart';

class Uint32ListTypedData {
  static BridgedClass get definition => BridgedClass(
        name: 'Uint32List',
        nativeType: Uint32List,
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length == 1 && positionalArgs[0] is int) {
              return Uint32List(positionalArgs[0] as int);
            }
            throw RuntimeError("Uint32List constructor expects one int argument (length).");
          },
          'fromList': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length == 1 && positionalArgs[0] is List) {
              final sourceList = positionalArgs[0] as List;
              final intList = sourceList.toNativeList().map((e) {
                if (e is int) return e;
                throw RuntimeError("Uint32List.fromList expects a List<int>.");
              }).toList();
              return Uint32List.fromList(intList);
            }
            throw RuntimeError("Uint32List.fromList expects one List<int> argument.");
          },
          'view': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty && positionalArgs[0] is ByteBuffer) {
              final buffer = positionalArgs[0] as ByteBuffer;
              final offsetInBytes =
                  positionalArgs.length > 1 ? positionalArgs[1] as int? ?? 0 : 0;
              final length =
                  positionalArgs.length > 2 ? positionalArgs[2] as int? : null;
              return Uint32List.view(buffer, offsetInBytes, length);
            }
            throw RuntimeError("Uint32List.view expects ByteBuffer and optional offset/length arguments.");
          },
          'sublistView': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty && positionalArgs[0] is TypedData) {
              final data = positionalArgs[0] as TypedData;
              final start =
                  positionalArgs.length > 1 ? positionalArgs[1] as int? ?? 0 : 0;
              final end =
                  positionalArgs.length > 2 ? positionalArgs[2] as int? : null;
              return Uint32List.sublistView(data, start, end);
            }
            throw RuntimeError("Uint32List.sublistView expects TypedData and optional start/end arguments.");
          },
        },
        methods: {
          '[]': (visitor, target, positionalArgs, namedArgs) {
            if (target is Uint32List &&
                positionalArgs.length == 1 &&
                positionalArgs[0] is int) {
              return target[positionalArgs[0] as int];
            }
            throw RuntimeError("Uint32List[index] expects an int index.");
          },
          '[]=': (visitor, target, positionalArgs, namedArgs) {
            if (target is Uint32List &&
                positionalArgs.length == 2 &&
                positionalArgs[0] is int &&
                positionalArgs[1] is int) {
              final index = positionalArgs[0] as int;
              final value = positionalArgs[1] as int;
              target[index] = value;
              return value;
            }
            throw RuntimeError("Uint32List[index] = value expects int index and int value.");
          },
          'sublist': (visitor, target, positionalArgs, namedArgs) {
            final start = positionalArgs.isNotEmpty ? positionalArgs[0] as int : 0;
            final end =
                positionalArgs.length > 1 ? positionalArgs[1] as int? : null;
            return (target as Uint32List).sublist(start, end);
          },
          'toList': (visitor, target, positionalArgs, namedArgs) {
            final growable = namedArgs['growable'] as bool? ?? true;
            return (target as Uint32List).toList(growable: growable);
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as Uint32List).toString();
          },
        },
        getters: {
          'length': (visitor, target) => (target as Uint32List).length,
          'elementSizeInBytes': (visitor, target) =>
              (target as Uint32List).elementSizeInBytes,
          'buffer': (visitor, target) => (target as Uint32List).buffer,
          'lengthInBytes': (visitor, target) => (target as Uint32List).lengthInBytes,
          'offsetInBytes': (visitor, target) => (target as Uint32List).offsetInBytes,
          'isEmpty': (visitor, target) => (target as Uint32List).isEmpty,
          'isNotEmpty': (visitor, target) => (target as Uint32List).isNotEmpty,
          'first': (visitor, target) => (target as Uint32List).first,
          'last': (visitor, target) => (target as Uint32List).last,
          'hashCode': (visitor, target) => (target as Uint32List).hashCode,
          'runtimeType': (visitor, target) => (target as Uint32List).runtimeType,
        },
      );
}
