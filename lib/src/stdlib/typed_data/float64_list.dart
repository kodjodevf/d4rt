import 'dart:typed_data';
import 'package:d4rt/d4rt.dart';

class Float64ListTypedData {
  static BridgedClass get definition => BridgedClass(
        name: 'Float64List',
        nativeType: Float64List,
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length == 1 && positionalArgs[0] is int) {
              return Float64List(positionalArgs[0] as int);
            }
            throw RuntimeError("Float64List constructor expects one int argument (length).");
          },
          'fromList': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length == 1 && positionalArgs[0] is List) {
              final sourceList = positionalArgs[0] as List;
              final doubleList = sourceList.toNativeList().map((e) {
                if (e is num) return e.toDouble();
                throw RuntimeError("Float64List.fromList expects a List<num>.");
              }).toList();
              return Float64List.fromList(doubleList);
            }
            throw RuntimeError("Float64List.fromList expects one List<num> argument.");
          },
          'view': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty && positionalArgs[0] is ByteBuffer) {
              final buffer = positionalArgs[0] as ByteBuffer;
              final offsetInBytes =
                  positionalArgs.length > 1 ? positionalArgs[1] as int? ?? 0 : 0;
              final length =
                  positionalArgs.length > 2 ? positionalArgs[2] as int? : null;
              return Float64List.view(buffer, offsetInBytes, length);
            }
            throw RuntimeError("Float64List.view expects ByteBuffer and optional offset/length arguments.");
          },
          'sublistView': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty && positionalArgs[0] is TypedData) {
              final data = positionalArgs[0] as TypedData;
              final start =
                  positionalArgs.length > 1 ? positionalArgs[1] as int? ?? 0 : 0;
              final end =
                  positionalArgs.length > 2 ? positionalArgs[2] as int? : null;
              return Float64List.sublistView(data, start, end);
            }
            throw RuntimeError("Float64List.sublistView expects TypedData and optional start/end arguments.");
          },
        },
        methods: {
          '[]': (visitor, target, positionalArgs, namedArgs) {
            if (target is Float64List &&
                positionalArgs.length == 1 &&
                positionalArgs[0] is int) {
              return target[positionalArgs[0] as int];
            }
            throw RuntimeError("Float64List[index] expects an int index.");
          },
          '[]=': (visitor, target, positionalArgs, namedArgs) {
            if (target is Float64List &&
                positionalArgs.length == 2 &&
                positionalArgs[0] is int &&
                positionalArgs[1] is num) {
              final index = positionalArgs[0] as int;
              final value = (positionalArgs[1] as num).toDouble();
              target[index] = value;
              return value;
            }
            throw RuntimeError("Float64List[index] = value expects int index and num value.");
          },
          'sublist': (visitor, target, positionalArgs, namedArgs) {
            final start = positionalArgs.isNotEmpty ? positionalArgs[0] as int : 0;
            final end =
                positionalArgs.length > 1 ? positionalArgs[1] as int? : null;
            return (target as Float64List).sublist(start, end);
          },
          'toList': (visitor, target, positionalArgs, namedArgs) {
            final growable = namedArgs['growable'] as bool? ?? true;
            return (target as Float64List).toList(growable: growable);
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as Float64List).toString();
          },
        },
        getters: {
          'length': (visitor, target) => (target as Float64List).length,
          'elementSizeInBytes': (visitor, target) =>
              (target as Float64List).elementSizeInBytes,
          'buffer': (visitor, target) => (target as Float64List).buffer,
          'lengthInBytes': (visitor, target) => (target as Float64List).lengthInBytes,
          'offsetInBytes': (visitor, target) => (target as Float64List).offsetInBytes,
          'isEmpty': (visitor, target) => (target as Float64List).isEmpty,
          'isNotEmpty': (visitor, target) => (target as Float64List).isNotEmpty,
          'first': (visitor, target) => (target as Float64List).first,
          'last': (visitor, target) => (target as Float64List).last,
          'hashCode': (visitor, target) => (target as Float64List).hashCode,
          'runtimeType': (visitor, target) => (target as Float64List).runtimeType,
        },
      );
}
