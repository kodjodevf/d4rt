import 'dart:typed_data';
import 'package:d4rt/d4rt.dart';

class Uint16ListTypedData {
  static BridgedClass get definition => BridgedClass(
        name: 'Uint16List',
        nativeType: Uint16List,
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length == 1 && positionalArgs[0] is int) {
              return Uint16List(positionalArgs[0] as int);
            }
            throw RuntimeError("Uint16List constructor expects one int argument (length).");
          },
          'fromList': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length == 1 && positionalArgs[0] is List) {
              final sourceList = positionalArgs[0] as List;
              final intList = sourceList.toNativeList().map((e) {
                if (e is int) return e;
                throw RuntimeError("Uint16List.fromList expects a List<int>.");
              }).toList();
              return Uint16List.fromList(intList);
            }
            throw RuntimeError("Uint16List.fromList expects one List<int> argument.");
          },
          'view': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty && positionalArgs[0] is ByteBuffer) {
              final buffer = positionalArgs[0] as ByteBuffer;
              final offsetInBytes =
                  positionalArgs.length > 1 ? positionalArgs[1] as int? ?? 0 : 0;
              final length =
                  positionalArgs.length > 2 ? positionalArgs[2] as int? : null;
              return Uint16List.view(buffer, offsetInBytes, length);
            }
            throw RuntimeError("Uint16List.view expects ByteBuffer and optional offset/length arguments.");
          },
          'sublistView': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty && positionalArgs[0] is TypedData) {
              final data = positionalArgs[0] as TypedData;
              final start =
                  positionalArgs.length > 1 ? positionalArgs[1] as int? ?? 0 : 0;
              final end =
                  positionalArgs.length > 2 ? positionalArgs[2] as int? : null;
              return Uint16List.sublistView(data, start, end);
            }
            throw RuntimeError("Uint16List.sublistView expects TypedData and optional start/end arguments.");
          },
        },
        methods: {
          '[]': (visitor, target, positionalArgs, namedArgs) {
            if (target is Uint16List &&
                positionalArgs.length == 1 &&
                positionalArgs[0] is int) {
              return target[positionalArgs[0] as int];
            }
            throw RuntimeError("Uint16List[index] expects an int index.");
          },
          '[]=': (visitor, target, positionalArgs, namedArgs) {
            if (target is Uint16List &&
                positionalArgs.length == 2 &&
                positionalArgs[0] is int &&
                positionalArgs[1] is int) {
              final index = positionalArgs[0] as int;
              final value = positionalArgs[1] as int;
              target[index] = value;
              return value;
            }
            throw RuntimeError("Uint16List[index] = value expects int index and int value.");
          },
          'sublist': (visitor, target, positionalArgs, namedArgs) {
            final start = positionalArgs.isNotEmpty ? positionalArgs[0] as int : 0;
            final end =
                positionalArgs.length > 1 ? positionalArgs[1] as int? : null;
            return (target as Uint16List).sublist(start, end);
          },
          'toList': (visitor, target, positionalArgs, namedArgs) {
            final growable = namedArgs['growable'] as bool? ?? true;
            return (target as Uint16List).toList(growable: growable);
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as Uint16List).toString();
          },
        },
        getters: {
          'length': (visitor, target) => (target as Uint16List).length,
          'elementSizeInBytes': (visitor, target) =>
              (target as Uint16List).elementSizeInBytes,
          'buffer': (visitor, target) => (target as Uint16List).buffer,
          'lengthInBytes': (visitor, target) => (target as Uint16List).lengthInBytes,
          'offsetInBytes': (visitor, target) => (target as Uint16List).offsetInBytes,
          'isEmpty': (visitor, target) => (target as Uint16List).isEmpty,
          'isNotEmpty': (visitor, target) => (target as Uint16List).isNotEmpty,
          'first': (visitor, target) => (target as Uint16List).first,
          'last': (visitor, target) => (target as Uint16List).last,
          'hashCode': (visitor, target) => (target as Uint16List).hashCode,
          'runtimeType': (visitor, target) => (target as Uint16List).runtimeType,
        },
      );
}
