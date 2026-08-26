import 'dart:typed_data';
import 'package:d4rt/d4rt.dart';

class Int64ListTypedData {
  static BridgedClass get definition => BridgedClass(
        name: 'Int64List',
        nativeType: Int64List,
        typeParameterCount: 0,
        isSubtypeOfFunc: (value) => value is Int64List,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length == 1 && positionalArgs[0] is int) {
              return Int64List(positionalArgs[0] as int);
            }
            throw RuntimeError("Int64List constructor expects one int argument (length).");
          },
          'fromList': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length == 1 && positionalArgs[0] is List) {
              final sourceList = positionalArgs[0] as List;
              final intList = sourceList.toNativeList().map((e) {
                if (e is int) return e;
                throw RuntimeError("Int64List.fromList expects a List<int>.");
              }).toList();
              return Int64List.fromList(intList);
            }
            throw RuntimeError("Int64List.fromList expects one List<int> argument.");
          },
          'view': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty && positionalArgs[0] is ByteBuffer) {
              final buffer = positionalArgs[0] as ByteBuffer;
              final offsetInBytes =
                  positionalArgs.length > 1 ? positionalArgs[1] as int? ?? 0 : 0;
              final length =
                  positionalArgs.length > 2 ? positionalArgs[2] as int? : null;
              return Int64List.view(buffer, offsetInBytes, length);
            }
            throw RuntimeError("Int64List.view expects ByteBuffer and optional offset/length arguments.");
          },
          'sublistView': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty && positionalArgs[0] is TypedData) {
              final data = positionalArgs[0] as TypedData;
              final start =
                  positionalArgs.length > 1 ? positionalArgs[1] as int? ?? 0 : 0;
              final end =
                  positionalArgs.length > 2 ? positionalArgs[2] as int? : null;
              return Int64List.sublistView(data, start, end);
            }
            throw RuntimeError("Int64List.sublistView expects TypedData and optional start/end arguments.");
          },
        },
        methods: {
          '[]': (visitor, target, positionalArgs, namedArgs) {
            if (target is Int64List &&
                positionalArgs.length == 1 &&
                positionalArgs[0] is int) {
              return target[positionalArgs[0] as int];
            }
            throw RuntimeError("Int64List[index] expects an int index.");
          },
          '[]=': (visitor, target, positionalArgs, namedArgs) {
            if (target is Int64List &&
                positionalArgs.length == 2 &&
                positionalArgs[0] is int &&
                positionalArgs[1] is int) {
              target[positionalArgs[0] as int] = positionalArgs[1] as int;
              return positionalArgs[1];
            }
            throw RuntimeError("Int64List[index] = value expects int index and int value.");
          },
          'sublist': (visitor, target, positionalArgs, namedArgs) {
            if (target is Int64List &&
                positionalArgs.isNotEmpty &&
                positionalArgs[0] is int) {
              final start = positionalArgs[0] as int;
              final end = positionalArgs.length > 1 ? positionalArgs[1] as int? : null;
              return target.sublist(start, end);
            }
            throw RuntimeError("Int64List.sublist expects start index and optional end index.");
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as Int64List).toString();
          },
        },
        getters: {
          'length': (visitor, target) {
            if (target is Int64List) {
              return target.length;
            }
            throw RuntimeError("Target is not an Int64List for getter 'length'.");
          },
          'buffer': (visitor, target) {
            if (target is Int64List) {
              return target.buffer;
            }
            throw RuntimeError("Target is not an Int64List for getter 'buffer'.");
          },
          'elementSizeInBytes': (visitor, target) {
            if (target is Int64List) {
              return target.elementSizeInBytes;
            }
            throw RuntimeError("Target is not an Int64List for getter 'elementSizeInBytes'.");
          },
          'offsetInBytes': (visitor, target) {
            if (target is Int64List) {
              return target.offsetInBytes;
            }
            throw RuntimeError("Target is not an Int64List for getter 'offsetInBytes'.");
          },
          'lengthInBytes': (visitor, target) {
            if (target is Int64List) {
              return target.lengthInBytes;
            }
            throw RuntimeError("Target is not an Int64List for getter 'lengthInBytes'.");
          },
          'isEmpty': (visitor, target) {
            if (target is Int64List) {
              return target.isEmpty;
            }
            throw RuntimeError("Target is not an Int64List for getter 'isEmpty'.");
          },
          'isNotEmpty': (visitor, target) {
            if (target is Int64List) {
              return target.isNotEmpty;
            }
            throw RuntimeError("Target is not an Int64List for getter 'isNotEmpty'.");
          },
          'first': (visitor, target) {
            if (target is Int64List) {
              return target.first;
            }
            throw RuntimeError("Target is not an Int64List for getter 'first'.");
          },
          'last': (visitor, target) {
            if (target is Int64List) {
              return target.last;
            }
            throw RuntimeError("Target is not an Int64List for getter 'last'.");
          },
          'hashCode': (visitor, target) => (target as Int64List).hashCode,
          'runtimeType': (visitor, target) =>
              (target as Int64List).runtimeType,
        },
      );
}
