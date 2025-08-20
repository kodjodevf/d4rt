import 'dart:typed_data';
import 'package:d4rt/d4rt.dart';

class Int16ListTypedData {
  static BridgedClass get definition => BridgedClass(
        name: 'Int16List',
        nativeType: Int16List,
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length == 1 && positionalArgs[0] is int) {
              return Int16List(positionalArgs[0] as int);
            }
            throw RuntimeError(
                "Int16List constructor expects one int argument (length).");
          },
          'fromList': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length == 1 && positionalArgs[0] is List) {
              final sourceList = positionalArgs[0] as List;
              final intList = sourceList.toNativeList().map((e) {
                if (e is int) return e;
                throw RuntimeError("Int16List.fromList expects a List<int>.");
              }).toList();
              return Int16List.fromList(intList);
            }
            throw RuntimeError(
                "Int16List.fromList expects one List<int> argument.");
          },
          'view': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty && positionalArgs[0] is ByteBuffer) {
              final buffer = positionalArgs[0] as ByteBuffer;
              final offsetInBytes = positionalArgs.length > 1
                  ? positionalArgs[1] as int? ?? 0
                  : 0;
              final length =
                  positionalArgs.length > 2 ? positionalArgs[2] as int? : null;
              return Int16List.view(buffer, offsetInBytes, length);
            }
            throw RuntimeError(
                "Int16List.view expects ByteBuffer and optional offset/length arguments.");
          },
          'sublistView': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty && positionalArgs[0] is TypedData) {
              final data = positionalArgs[0] as TypedData;
              final start = positionalArgs.length > 1
                  ? positionalArgs[1] as int? ?? 0
                  : 0;
              final end =
                  positionalArgs.length > 2 ? positionalArgs[2] as int? : null;
              return Int16List.sublistView(data, start, end);
            }
            throw RuntimeError(
                "Int16List.sublistView expects TypedData and optional start/end arguments.");
          },
        },
        methods: {
          // Index operators
          '[]': (visitor, target, positionalArgs, namedArgs) {
            if (target is Int16List &&
                positionalArgs.length == 1 &&
                positionalArgs[0] is int) {
              return target[positionalArgs[0] as int];
            }
            throw RuntimeError("Int16List[index] expects an int index.");
          },
          '[]=': (visitor, target, positionalArgs, namedArgs) {
            if (target is Int16List &&
                positionalArgs.length == 2 &&
                positionalArgs[0] is int &&
                positionalArgs[1] is int) {
              final index = positionalArgs[0] as int;
              final value = positionalArgs[1] as int;
              target[index] = value;
              return value;
            }
            throw RuntimeError(
                "Int16List[index] = value expects int index and int value.");
          },

          // List methods
          'sublist': (visitor, target, positionalArgs, namedArgs) {
            final start =
                positionalArgs.isNotEmpty ? positionalArgs[0] as int : 0;
            final end =
                positionalArgs.length > 1 ? positionalArgs[1] as int? : null;
            return (target as Int16List).sublist(start, end);
          },
          'getRange': (visitor, target, positionalArgs, namedArgs) {
            final start = positionalArgs[0] as int;
            final end = positionalArgs[1] as int;
            return (target as Int16List).getRange(start, end);
          },
          'setRange': (visitor, target, positionalArgs, namedArgs) {
            final start = positionalArgs[0] as int;
            final end = positionalArgs[1] as int;
            final iterable = positionalArgs[2] as Iterable<int>;
            final skipCount =
                positionalArgs.length > 3 ? positionalArgs[3] as int : 0;
            (target as Int16List).setRange(start, end, iterable, skipCount);
            return null;
          },
          'setAll': (visitor, target, positionalArgs, namedArgs) {
            final at = positionalArgs[0] as int;
            final iterable = positionalArgs[1] as Iterable<int>;
            (target as Int16List).setAll(at, iterable);
            return null;
          },
          'fillRange': (visitor, target, positionalArgs, namedArgs) {
            final start = positionalArgs[0] as int;
            final end = positionalArgs[1] as int;
            final fill =
                positionalArgs.length > 2 ? positionalArgs[2] as int? : null;
            (target as Int16List).fillRange(start, end, fill);
            return null;
          },

          // Typed methods
          'buffer': (visitor, target, positionalArgs, namedArgs) {
            return (target as Int16List).buffer;
          },
          'asUint8ListView': (visitor, target, positionalArgs, namedArgs) {
            final offsetInBytes =
                positionalArgs.isNotEmpty ? positionalArgs[0] as int? : null;
            final length =
                positionalArgs.length > 1 ? positionalArgs[1] as int? : null;
            return (target as Int16List)
                .buffer
                .asUint8List(offsetInBytes ?? 0, length);
          },

          // Standard methods
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as Int16List).toString();
          },
          '==': (visitor, target, positionalArgs, namedArgs) {
            return (target as Int16List) == positionalArgs[0];
          },
        },
        getters: {
          'length': (visitor, target) {
            if (target is Int16List) return target.length;
            throw RuntimeError(
                "Target is not an Int16List for getter 'length'");
          },
          'lengthInBytes': (visitor, target) {
            if (target is Int16List) return target.lengthInBytes;
            throw RuntimeError(
                "Target is not an Int16List for getter 'lengthInBytes'");
          },
          'elementSizeInBytes': (visitor, target) {
            if (target is Int16List) return target.elementSizeInBytes;
            throw RuntimeError(
                "Target is not an Int16List for getter 'elementSizeInBytes'");
          },
          'offsetInBytes': (visitor, target) {
            if (target is Int16List) return target.offsetInBytes;
            throw RuntimeError(
                "Target is not an Int16List for getter 'offsetInBytes'");
          },
          'buffer': (visitor, target) {
            if (target is Int16List) return target.buffer;
            throw RuntimeError(
                "Target is not an Int16List for getter 'buffer'");
          },
          'first': (visitor, target) {
            if (target is Int16List) return target.first;
            throw RuntimeError("Target is not an Int16List for getter 'first'");
          },
          'last': (visitor, target) {
            if (target is Int16List) return target.last;
            throw RuntimeError("Target is not an Int16List for getter 'last'");
          },
          'isEmpty': (visitor, target) {
            if (target is Int16List) return target.isEmpty;
            throw RuntimeError(
                "Target is not an Int16List for getter 'isEmpty'");
          },
          'isNotEmpty': (visitor, target) {
            if (target is Int16List) return target.isNotEmpty;
            throw RuntimeError(
                "Target is not an Int16List for getter 'isNotEmpty'");
          },
          'hashCode': (visitor, target) {
            if (target is Int16List) return target.hashCode;
            throw RuntimeError(
                "Target is not an Int16List for getter 'hashCode'");
          },
          'runtimeType': (visitor, target) {
            if (target is Int16List) return target.runtimeType;
            throw RuntimeError(
                "Target is not an Int16List for getter 'runtimeType'");
          },
        },
      );
}
