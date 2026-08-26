import 'dart:typed_data';
import 'package:d4rt/d4rt.dart';

class Uint64ListTypedData {
  static BridgedClass get definition => BridgedClass(
        name: 'Uint64List',
        nativeType: Uint64List,
        typeParameterCount: 0,
        isSubtypeOfFunc: (value) => value is Uint64List,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length == 1 && positionalArgs[0] is int) {
              return Uint64List(positionalArgs[0] as int);
            }
            throw RuntimeError("Uint64List constructor expects one int argument (length).");
          },
          'fromList': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length == 1 && positionalArgs[0] is List) {
              final sourceList = positionalArgs[0] as List;
              final intList = sourceList.toNativeList().map((e) {
                if (e is int) return e;
                throw RuntimeError("Uint64List.fromList expects a List<int>.");
              }).toList();
              return Uint64List.fromList(intList);
            }
            throw RuntimeError("Uint64List.fromList expects one List<int> argument.");
          },
          'view': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty && positionalArgs[0] is ByteBuffer) {
              final buffer = positionalArgs[0] as ByteBuffer;
              final offsetInBytes =
                  positionalArgs.length > 1 ? positionalArgs[1] as int? ?? 0 : 0;
              final length =
                  positionalArgs.length > 2 ? positionalArgs[2] as int? : null;
              return Uint64List.view(buffer, offsetInBytes, length);
            }
            throw RuntimeError("Uint64List.view expects ByteBuffer and optional offset/length arguments.");
          },
          'sublistView': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty && positionalArgs[0] is TypedData) {
              final data = positionalArgs[0] as TypedData;
              final start =
                  positionalArgs.length > 1 ? positionalArgs[1] as int? ?? 0 : 0;
              final end =
                  positionalArgs.length > 2 ? positionalArgs[2] as int? : null;
              return Uint64List.sublistView(data, start, end);
            }
            throw RuntimeError("Uint64List.sublistView expects TypedData and optional start/end arguments.");
          },
        },
        methods: {
          '[]': (visitor, target, positionalArgs, namedArgs) {
            if (target is Uint64List &&
                positionalArgs.length == 1 &&
                positionalArgs[0] is int) {
              return target[positionalArgs[0] as int];
            }
            throw RuntimeError("Uint64List[index] expects an int index.");
          },
          '[]=': (visitor, target, positionalArgs, namedArgs) {
            if (target is Uint64List &&
                positionalArgs.length == 2 &&
                positionalArgs[0] is int &&
                positionalArgs[1] is int) {
              target[positionalArgs[0] as int] = positionalArgs[1] as int;
              return positionalArgs[1];
            }
            throw RuntimeError("Uint64List[index] = value expects int index and int value.");
          },
          'sublist': (visitor, target, positionalArgs, namedArgs) {
            if (target is Uint64List &&
                positionalArgs.isNotEmpty &&
                positionalArgs[0] is int) {
              final start = positionalArgs[0] as int;
              final end = positionalArgs.length > 1 ? positionalArgs[1] as int? : null;
              return target.sublist(start, end);
            }
            throw RuntimeError("Uint64List.sublist expects start index and optional end index.");
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as Uint64List).toString();
          },
        },
        getters: {
          'length': (visitor, target) {
            if (target is Uint64List) {
              return target.length;
            }
            throw RuntimeError("Target is not a Uint64List for getter 'length'.");
          },
          'buffer': (visitor, target) {
            if (target is Uint64List) {
              return target.buffer;
            }
            throw RuntimeError("Target is not a Uint64List for getter 'buffer'.");
          },
          'elementSizeInBytes': (visitor, target) {
            if (target is Uint64List) {
              return target.elementSizeInBytes;
            }
            throw RuntimeError("Target is not a Uint64List for getter 'elementSizeInBytes'.");
          },
          'offsetInBytes': (visitor, target) {
            if (target is Uint64List) {
              return target.offsetInBytes;
            }
            throw RuntimeError("Target is not a Uint64List for getter 'offsetInBytes'.");
          },
          'lengthInBytes': (visitor, target) {
            if (target is Uint64List) {
              return target.lengthInBytes;
            }
            throw RuntimeError("Target is not a Uint64List for getter 'lengthInBytes'.");
          },
          'isEmpty': (visitor, target) {
            if (target is Uint64List) {
              return target.isEmpty;
            }
            throw RuntimeError("Target is not a Uint64List for getter 'isEmpty'.");
          },
          'isNotEmpty': (visitor, target) {
            if (target is Uint64List) {
              return target.isNotEmpty;
            }
            throw RuntimeError("Target is not a Uint64List for getter 'isNotEmpty'.");
          },
          'first': (visitor, target) {
            if (target is Uint64List) {
              return target.first;
            }
            throw RuntimeError("Target is not a Uint64List for getter 'first'.");
          },
          'last': (visitor, target) {
            if (target is Uint64List) {
              return target.last;
            }
            throw RuntimeError("Target is not a Uint64List for getter 'last'.");
          },
          'hashCode': (visitor, target) => (target as Uint64List).hashCode,
          'runtimeType': (visitor, target) =>
              (target as Uint64List).runtimeType,
        },
      );
}
