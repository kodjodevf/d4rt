import 'dart:typed_data';
import 'package:d4rt/d4rt.dart';

class Float32ListTypedData {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        name: 'Float32List',
        nativeType: Float32List,
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length == 1 && positionalArgs[0] is int) {
              return Float32List(positionalArgs[0] as int);
            }
            throw RuntimeError(
                "Float32List constructor expects one int argument (length).");
          },
          'fromList': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length == 1 && positionalArgs[0] is List) {
              final sourceList = positionalArgs[0] as List;
              final doubleList = sourceList.map((e) {
                if (e is num) return e.toDouble();
                throw RuntimeError("Float32List.fromList expects a List<num>.");
              }).toList();
              return Float32List.fromList(doubleList);
            }
            throw RuntimeError(
                "Float32List.fromList expects one List<num> argument.");
          },
          'view': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty && positionalArgs[0] is ByteBuffer) {
              final buffer = positionalArgs[0] as ByteBuffer;
              final offsetInBytes = positionalArgs.length > 1
                  ? positionalArgs[1] as int? ?? 0
                  : 0;
              final length =
                  positionalArgs.length > 2 ? positionalArgs[2] as int? : null;
              return Float32List.view(buffer, offsetInBytes, length);
            }
            throw RuntimeError(
                "Float32List.view expects ByteBuffer and optional offset/length arguments.");
          },
          'sublistView': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty && positionalArgs[0] is TypedData) {
              final data = positionalArgs[0] as TypedData;
              final start = positionalArgs.length > 1
                  ? positionalArgs[1] as int? ?? 0
                  : 0;
              final end =
                  positionalArgs.length > 2 ? positionalArgs[2] as int? : null;
              return Float32List.sublistView(data, start, end);
            }
            throw RuntimeError(
                "Float32List.sublistView expects TypedData and optional start/end arguments.");
          },
        },
        methods: {
          // Index operators
          '[]': (visitor, target, positionalArgs, namedArgs) {
            if (target is Float32List &&
                positionalArgs.length == 1 &&
                positionalArgs[0] is int) {
              return target[positionalArgs[0] as int];
            }
            throw RuntimeError("Float32List[index] expects an int index.");
          },
          '[]=': (visitor, target, positionalArgs, namedArgs) {
            if (target is Float32List &&
                positionalArgs.length == 2 &&
                positionalArgs[0] is int &&
                positionalArgs[1] is num) {
              final index = positionalArgs[0] as int;
              final value = (positionalArgs[1] as num).toDouble();
              target[index] = value;
              return value;
            }
            throw RuntimeError(
                "Float32List[index] = value expects int index and num value.");
          },

          // List methods
          'sublist': (visitor, target, positionalArgs, namedArgs) {
            final start =
                positionalArgs.isNotEmpty ? positionalArgs[0] as int : 0;
            final end =
                positionalArgs.length > 1 ? positionalArgs[1] as int? : null;
            return (target as Float32List).sublist(start, end);
          },
          'getRange': (visitor, target, positionalArgs, namedArgs) {
            final start = positionalArgs[0] as int;
            final end = positionalArgs[1] as int;
            return (target as Float32List).getRange(start, end);
          },
          'setRange': (visitor, target, positionalArgs, namedArgs) {
            final start = positionalArgs[0] as int;
            final end = positionalArgs[1] as int;
            final iterable = positionalArgs[2] as Iterable<double>;
            final skipCount =
                positionalArgs.length > 3 ? positionalArgs[3] as int : 0;
            (target as Float32List).setRange(start, end, iterable, skipCount);
            return null;
          },
          'setAll': (visitor, target, positionalArgs, namedArgs) {
            final at = positionalArgs[0] as int;
            final iterable = positionalArgs[1] as Iterable<double>;
            (target as Float32List).setAll(at, iterable);
            return null;
          },
          'fillRange': (visitor, target, positionalArgs, namedArgs) {
            final start = positionalArgs[0] as int;
            final end = positionalArgs[1] as int;
            final fill = positionalArgs.length > 2
                ? (positionalArgs[2] as num?)?.toDouble()
                : null;
            (target as Float32List).fillRange(start, end, fill);
            return null;
          },

          // Typed methods
          'buffer': (visitor, target, positionalArgs, namedArgs) {
            return (target as Float32List).buffer;
          },
          'asUint8ListView': (visitor, target, positionalArgs, namedArgs) {
            final offsetInBytes =
                positionalArgs.isNotEmpty ? positionalArgs[0] as int? : null;
            final length =
                positionalArgs.length > 1 ? positionalArgs[1] as int? : null;
            return (target as Float32List)
                .buffer
                .asUint8List(offsetInBytes ?? 0, length);
          },

          // Standard methods
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as Float32List).toString();
          },
          '==': (visitor, target, positionalArgs, namedArgs) {
            return (target as Float32List) == positionalArgs[0];
          },
        },
        getters: {
          'length': (visitor, target) {
            if (target is Float32List) return target.length;
            throw RuntimeError(
                "Target is not a Float32List for getter 'length'");
          },
          'lengthInBytes': (visitor, target) {
            if (target is Float32List) return target.lengthInBytes;
            throw RuntimeError(
                "Target is not a Float32List for getter 'lengthInBytes'");
          },
          'elementSizeInBytes': (visitor, target) {
            if (target is Float32List) return target.elementSizeInBytes;
            throw RuntimeError(
                "Target is not a Float32List for getter 'elementSizeInBytes'");
          },
          'offsetInBytes': (visitor, target) {
            if (target is Float32List) return target.offsetInBytes;
            throw RuntimeError(
                "Target is not a Float32List for getter 'offsetInBytes'");
          },
          'buffer': (visitor, target) {
            if (target is Float32List) return target.buffer;
            throw RuntimeError(
                "Target is not a Float32List for getter 'buffer'");
          },
          'first': (visitor, target) {
            if (target is Float32List) return target.first;
            throw RuntimeError(
                "Target is not a Float32List for getter 'first'");
          },
          'last': (visitor, target) {
            if (target is Float32List) return target.last;
            throw RuntimeError("Target is not a Float32List for getter 'last'");
          },
          'isEmpty': (visitor, target) {
            if (target is Float32List) return target.isEmpty;
            throw RuntimeError(
                "Target is not a Float32List for getter 'isEmpty'");
          },
          'isNotEmpty': (visitor, target) {
            if (target is Float32List) return target.isNotEmpty;
            throw RuntimeError(
                "Target is not a Float32List for getter 'isNotEmpty'");
          },
          'hashCode': (visitor, target) {
            if (target is Float32List) return target.hashCode;
            throw RuntimeError(
                "Target is not a Float32List for getter 'hashCode'");
          },
          'runtimeType': (visitor, target) {
            if (target is Float32List) return target.runtimeType;
            throw RuntimeError(
                "Target is not a Float32List for getter 'runtimeType'");
          },
        },
      );
}
